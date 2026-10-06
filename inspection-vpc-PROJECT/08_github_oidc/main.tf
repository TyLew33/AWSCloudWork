###############################################################################
# GitHub Actions -> AWS trust, scoped to inspection-vpc-PROJECT.
#
# Apply ONCE from your laptop:
#   cd inspection-vpc-PROJECT/08_github_oidc
#   AWS_PROFILE=default tofu init
#   AWS_PROFILE=default tofu apply
#
# Requires 00_bootstrap to have been applied already, since the state bucket
# and lock table must exist before this module can store its own state there.
###############################################################################

data "aws_caller_identity" "current" {}

locals {
  # The prefix GitHub stamps on every OIDC token for this repo.
  #
  # Classic format:    repo:OWNER/REPO
  # Immutable format:  repo:OWNER@OWNER_ID/REPO@REPO_ID
  #
  # Repos created, renamed or transferred after 2026-07-15, and repos that
  # opted in, use the immutable format. The numeric IDs survive renames,
  # which is the whole point: a recycled repo name cannot mint tokens that
  # match a stale trust policy.
  #
  # Find yours (this is authoritative, do not guess):
  #   gh api /repos/OWNER/REPO/actions/oidc/customization/sub
  # and read the sub_claim_prefix field.
  repo_prefix = coalesce(var.sub_claim_prefix, "repo:${var.github_repository}")

  # GitHub's description of the job requesting credentials. The suffix CHANGES
  # depending on the trigger, which is the other common source of
  # "Not authorized to perform sts:AssumeRoleWithWebIdentity":
  #
  #   pull request        <prefix>:pull_request
  #   push / manual run   <prefix>:ref:refs/heads/BRANCH
  #   uses an environment <prefix>:environment:NAME
  #
  # The plan role is reachable both ways, so BOTH must be listed.
  plan_subjects = [
    "${local.repo_prefix}:pull_request",
    "${local.repo_prefix}:ref:refs/heads/${var.default_branch}",
  ]

  apply_subject = "${local.repo_prefix}:environment:${var.apply_environment}"

  state_bucket_arn = "arn:aws:s3:::${var.state_bucket}"
  lock_table_arn   = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.state_lock_table}"
}

###############################################################################
# 1. Identity provider — one per AWS account, ever.
#
# If you already created this for another project, DELETE this resource and
# reference the existing ARN instead. Creating a second one for the same URL
# will fail with EntityAlreadyExists.
###############################################################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # The audience. GitHub stamps the token "intended for AWS STS" and AWS
  # verifies that stamp, so a token minted for another service cannot be
  # replayed here.
  client_id_list = ["sts.amazonaws.com"]

  # thumbprint_list deliberately omitted: AWS validates GitHub's certificate
  # against its own trusted CA library and ignores any legacy thumbprint.
  # Requires AWS provider >= 5.81; this project pins ~> 6.45.

  tags = {
    Name      = "github-actions"
    ManagedBy = "OpenTofu"
  }
}

###############################################################################
# 2a. PLAN role
#     Read-only on infrastructure. Reads remote state (stages 05/06/07 read
#     other stages' state) and takes the state lock while planning.
###############################################################################

data "aws_iam_policy_document" "plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # StringEquals, never StringLike with a wildcard. A wildcard here would
    # let any branch in any of your repos assume this role.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.plan_subjects
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "gha-inspection-vpc-plan"
  description          = "Pull-request workflows: tofu plan for inspection-vpc-PROJECT"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

# Broad read so plan can refresh VPCs, TGW, Network Firewall, NAT, routes.
# NOTE: ReadOnlyAccess can read S3 object CONTENTS. Fine for a lab account;
# reconsider if this account ever holds sensitive data.
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }

  # Read this stage's own state, plus the other stages' state that
  # 05/06/07 pull in through terraform_remote_state.
  statement {
    sid       = "ReadStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${local.state_bucket_arn}/*"]
  }

  # plan TAKES A LOCK while it runs, which is why a read-only role still
  # needs write access to the lock table.
  statement {
    sid    = "ManageStateLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [local.lock_table_arn]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "inspection-vpc-state-read"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

###############################################################################
# 2b. APPLY role
#     Reachable ONLY by a job declaring environment: inspection-vpc.
#     Because that environment requires human approval, AWS itself refuses
#     credentials to anything that skipped the gate.
###############################################################################

data "aws_iam_policy_document" "apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # The environment subject. A pull request can never produce this string,
    # so no PR can reach this role no matter what its YAML says.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.apply_subject]
    }
  }
}

resource "aws_iam_role" "apply" {
  name                 = "gha-inspection-vpc-apply"
  description          = "Approved deployments: tofu apply for inspection-vpc-PROJECT"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600
}

# Scoped to the services this project actually creates, rather than
# PowerUserAccess. Narrow enough to be meaningful, broad enough to work.
data "aws_iam_policy_document" "apply_infra" {
  statement {
    sid    = "NetworkingAndFirewall"
    effect = "Allow"
    actions = [
      "ec2:*",             # VPCs, subnets, routes, NAT, IGW, TGW, ENIs
      "network-firewall:*",# firewall, policy, rule groups, logging config
      "logs:*",            # firewall flow/alert log destinations
      "ram:*",             # resource shares, if you add cross-account later
      "elasticloadbalancing:Describe*",
    ]
    resources = ["*"]
  }

  # Needed for default_tags and for reading account context.
  statement {
    sid    = "ReadIdentity"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
      "iam:ListRoles",
      "iam:GetRole",
    ]
    resources = ["*"]
  }

  # Network Firewall creates a service-linked role on first use.
  statement {
    sid       = "ServiceLinkedRole"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["network-firewall.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "apply_infra" {
  name   = "inspection-vpc-infra"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_infra.json
}

data "aws_iam_policy_document" "apply_state" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "WriteStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/*"]
  }

  statement {
    sid    = "ManageStateLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [local.lock_table_arn]
  }
}

resource "aws_iam_role_policy" "apply_state" {
  name   = "inspection-vpc-state-write"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_state.json
}
