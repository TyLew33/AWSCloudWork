# inspection-vpc-PROJECT

An **OpenTofu** lab in a single AWS account demonstrating a **centralized network inspection**
architecture: two isolated spoke VPCs (Prod, Dev) that can reach the internet — and nothing
else outside themselves — through a shared Transit Gateway and AWS Network Firewall sitting in a
dedicated Inspection VPC. Prod and Dev cannot reach each other, enforced by an explicit firewall
policy rather than by missing routes.

This has been applied and tested end-to-end in a live account (see [Verification](#verification)
below for actual log output from that test) and is meant to be built on, not just read.

## Architecture

- **Prod VPC** (`10.235.0.0/24`) and **Dev VPC** (`10.232.0.0/24`) each have a single subnet with
  no internet gateway of their own — their only route out is `0.0.0.0/0 → Transit Gateway`.
- The **Transit Gateway** has two explicit route tables (default association/propagation
  disabled): `rtb_spoke`, associated with the Prod and Dev attachments, holding only a static
  `0.0.0.0/0 → Inspection attachment` route; and `rtb_inspection`, associated with the Inspection
  attachment, holding static routes back to each spoke's CIDR. Neither spoke's CIDR is ever
  propagated or routed into the other's table.
- The **Inspection VPC** (`10.238.0.0/24`) has three subnets — a TGW-attachment subnet, a
  dedicated AWS Network Firewall subnet, and a public subnet with a NAT Gateway + IGW — and is the
  only VPC with internet access.
- **AWS Network Firewall** is the actual isolation mechanism: a stateful 5-tuple rule group with
  two `DROP` rules (Prod CIDR → Dev CIDR and back). Everything else — internet-bound traffic in
  either direction — is implicitly allowed, since no rule matches it.

```
                                Internet
                                    │
                                   IGW
                                    │
                    ┌───────────────┴────────────────┐
                    │      Inspection VPC (10.238.0.0/24)     │
                    │                                          │
                    │   public subnet ──── NAT Gateway         │
                    │        │        ▲ (re-inspected return)  │
                    │        ▼        │                        │
                    │   firewall subnet ── AWS Network Firewall│
                    │        │        ▲   DROP: prod ⇄ dev      │
                    │        ▼        │                        │
                    │   tgw-attach subnet                      │
                    └────────────────┬─────────────────────────┘
                                     │ Inspection attachment
                                     ▼
                    ┌──────────────────────────────────┐
                    │          Transit Gateway           │
                    │  rtb_spoke:      0.0.0.0/0 ───────►│ Inspection attachment
                    │  rtb_inspection: 10.235.0.0/24 ───►│ Prod attachment
                    │                  10.232.0.0/24 ───►│ Dev attachment
                    └───────────┬──────────────┬─────────┘
                       Prod attachment    Dev attachment
                                │                │
                    ┌───────────┴──┐     ┌───────┴───────┐
                    │   Prod VPC    │     │   Dev VPC      │
                    │ 10.235.0.0/24 │     │ 10.232.0.0/24  │
                    └───────────────┘     └────────────────┘

        Prod ───X──── Dev   (blocked by the firewall's explicit DROP
                             rule, not by an absent route)
```

Data flow after apply:
- **Spoke → Internet:** host → `0.0.0.0/0` → TGW → `rtb_spoke` → Inspection attachment →
  tgw-attach subnet → Network Firewall (no DROP rule matches → allowed) → firewall subnet →
  NAT Gateway → IGW → internet. Return traffic comes back through the public subnet's route for
  that spoke's CIDR, which points at the firewall endpoint again — internet-return traffic gets
  re-inspected, not routed straight back.
- **Prod ↔ Dev:** same path as above up through the firewall's tgw-attach subnet, where the
  5-tuple stateful rule (`sid:1` / `sid:2`) matches the CIDR pair and the packet is dropped.

## Repo layout

Numbered top-level directories (`00_*`–`07_*`) are a **staged deployment**, applied in order. Each
is its own OpenTofu root module with its own state file; cross-stage data flows through
`terraform_remote_state`, not module composition.

`08_github_oidc` sits outside that sequence — it provisions no network infrastructure and nothing
depends on its outputs. It defines the IAM trust relationship and roles that let GitHub Actions
deploy this project without stored credentials. See [CI/CD](#cicd).

| Stage | Purpose |
|---|---|
| `00_bootstrap` | S3 bucket + DynamoDB table for remote state. The one stage using **local** state — it can't depend on the backend it's creating. |
| `01_tgw_core` | Transit Gateway + the two explicit route tables (`rtb_spoke`, `rtb_inspection`). |
| `02_prod_vpc` | Prod VPC (`10.235.0.0/24`), single subnet, single AZ, no routes yet. |
| `03_dev_vpc` | Dev VPC (`10.232.0.0/24`), identical pattern. |
| `04_inspection_vpc` | Inspection VPC (`10.238.0.0/24`): IGW, NAT Gateway + EIP, three subnets (tgw-attach, firewall, public) with their route tables. |
| `05_network_firewall` | Stateful rule group (DROP Prod↔Dev), firewall policy, the firewall itself, and CloudWatch Logs (ALERT + FLOW) logging configuration. |
| `06_tgw_attachments` | TGW VPC attachments for all three VPCs, plus each spoke's `0.0.0.0/0 → TGW` route. |
| `07_post_attachment_routing` | Everything that needed the attachments *and* the firewall to exist first: TGW route table associations + static routes, and the Inspection VPC's remaining intra-VPC routes (to the firewall endpoint, and back out via the TGW). |

### Apply order

```
00_bootstrap
01_tgw_core
02_prod_vpc
03_dev_vpc
04_inspection_vpc
05_network_firewall
06_tgw_attachments
07_post_attachment_routing
```

Strictly sequential — every stage from `01` on reads at least one earlier stage's state via
`terraform_remote_state`, and `07` reads from `01`, `04`, `05`, and `06`.

## Getting started

### Prerequisites

- A single AWS account and CLI profile. The `aws_profile` and `state_profile` variables default to
  `null`, which falls through to the default credential chain — so set `AWS_PROFILE` in your shell
  (or pass the variable explicitly) when working locally. The same configuration therefore runs
  unchanged in CI, where credentials arrive from OIDC rather than from `~/.aws/config`.
- IAM permissions for VPC, Transit Gateway, AWS Network Firewall, NAT Gateway/EIP, S3, DynamoDB,
  and CloudWatch Logs.

### Applying

```sh
cd 00_bootstrap
cp terraform.tfvars.example terraform.tfvars   # edit bucket/table names if they collide
tofu init
tofu apply
```

Then, per remaining stage (`01_tgw_core` through `07_post_attachment_routing`, in order):

```sh
cp terraform.tfvars.example terraform.tfvars   # edit region if yours differs
export AWS_PROFILE=default                     # or whichever profile you use
tofu init
tofu plan
tofu apply
```

The steps above are the bootstrap and break-glass path. Once `08_github_oidc` has been applied,
the normal route for `01`–`07` is the gated [CI/CD](#cicd) workflows, which produce a reviewed
plan and a recorded approver for every change. `00_bootstrap` stays local permanently — it owns
the state backend the pipeline depends on.

Every stage's `backend.tf` hardcodes the bucket/table names from `00_bootstrap`
(`inspection-vpc-tfstate-bucket` / `inspection-vpc-tfstate-lock`) — OpenTofu backend blocks can't
reference variables, so if you rename those in `00_bootstrap`, update every other stage's
`backend.tf` (and matching `state_bucket`/`state_lock_table` variables) to match.

## CI/CD

This project deploys through GitHub Actions using **OpenID Connect federation to AWS — no
long-lived access keys exist in the repository or in GitHub secrets.** Each run exchanges a
short-lived, GitHub-signed identity token for AWS credentials valid for roughly an hour.

`08_github_oidc` defines that trust. It is applied **once, manually**, before anything else in the
pipeline can work — the module granting the pipeline its access cannot be applied by the pipeline.

### Two roles, split by blast radius

| Role | Access | Trusted OIDC subjects |
|---|---|---|
| `gha-inspection-vpc-plan` | Read-only, plus state read and DynamoDB lock | `:pull_request`, `:ref:refs/heads/main` |
| `gha-inspection-vpc-apply` | `ec2`, `network-firewall`, `logs`, `ram`, plus state write | `:environment:inspection-vpc` **only** |

The plan role needs DynamoDB **write** despite being read-only on infrastructure: `tofu plan`
acquires a state lock while it runs.

The split is what makes an ungated plan safe. Anything read-only runs freely on a pull request;
anything that mutates infrastructure is reachable only through the approval gate.

### Workflows

| Workflow | Fires on | AWS access | Gated |
|---|---|---|---|
| `inspection-vpc-checks.yml` | PR, push to `main`, manual | none | no |
| `inspection-vpc-plan.yml` | PR, push to `main`, manual | read-only | no |
| `inspection-vpc-apply.yml` | manual only | write | yes |
| `inspection-vpc-destroy.yml` | manual only | write | yes |

**checks** — `tofu fmt`, `tofu validate` across every stage in parallel, `tflint` with the AWS
ruleset (`.tflint.hcl` at the repo root), and `checkov`. Runs `init -backend=false`, so it needs no
AWS credentials at all and works for `00_bootstrap` despite its missing backend block. These are
the required status checks on `main`.

**plan** — assumes the plan role, runs `tofu plan` against live state, posts the result as a
pull-request comment (or to the run summary on a merge). Only stages the change actually touches
are planned, determined by diffing the relevant commits. Informational rather than blocking: a plan
can legitimately fail because an upstream stage hasn't been applied yet, which says nothing about
the change under review.

**apply** — manual, one stage at a time, because the apply order is strictly sequential and the
operator chooses when each stage runs. Requires typing `APPLY`, then halts on the `inspection-vpc`
environment for human approval before its first step. The applied plan is archived for 90 days.

**destroy** — the same gate plus three further guards:

- The confirmation text must be the **exact stage name**, not a generic word, so a mis-clicked
  dropdown can't be carried through by muscle memory.
- The stage list is ordered in reverse (`07` → `01`), matching the order teardown must follow.
  `05_network_firewall` holds an endpoint inside `04_inspection_vpc`; destroying `04` first fails
  or orphans resources.
- A read-only **preview job runs before the approval gate**, generating the full destroy plan into
  the run summary. The approver sees exactly which resources will be removed before deciding, and
  the gated job then applies that exact saved plan rather than re-planning afterwards. If state
  moved in between, OpenTofu rejects the stale plan rather than destroying something unreviewed.

`00_bootstrap` is excluded from every workflow that touches AWS. It owns the state bucket and lock
table every other stage depends on, and keeps its own state locally — planning or destroying it
from CI would operate on the foundation the rest of the pipeline stands on.

### Two independent gates

```
branch protection ──► what reaches main
                        PR required, status checks must pass,
                        force pushes blocked

environment gate  ──► what reaches AWS
                        human approval + AWS-side enforcement
```

The second is enforced twice over. Declaring `environment: inspection-vpc` is what holds a job for
approval — and it is also what sets the OIDC subject claim the apply role trusts. Removing that
line to skip the approval changes the subject, so AWS refuses to issue credentials and the job
fails at authentication. **The gate is not enforced by the thing an author can edit.**

### Setup, if reproducing this

1. Apply `00_bootstrap` locally (state bucket + lock table).
2. Apply `08_github_oidc` locally. It outputs two role ARNs.
3. Add those as **repository variables** (not secrets — an ARN is an address, useless without a
   signed token from the repo): `AWS_INSPECTION_PLAN_ROLE_ARN`, `AWS_INSPECTION_APPLY_ROLE_ARN`.
4. Create a GitHub **environment** named exactly `inspection-vpc`, with a required reviewer and
   deployment branches limited to `main`. The name must match `apply_environment` in
   `08_github_oidc/variables.tf` — it forms part of the OIDC subject the apply role trusts.
5. Set the `sub_claim_prefix` variable if the repository uses immutable subject claims (see below).

### Troubleshooting OIDC

Nearly every failure is a mismatch between the subject claim GitHub sends and the one the trust
policy expects. Both sides are queryable — don't infer either.

```sh
# What subject prefix does GitHub actually send for this repo?
gh api /repos/OWNER/REPO/actions/oidc/customization/sub

# What does the role actually trust?
aws iam get-role --role-name gha-inspection-vpc-plan \
  --query 'Role.AssumeRolePolicyDocument.Statement[0].Condition'
```

The subject **suffix changes with the trigger** — `:pull_request`, `:ref:refs/heads/main`, and
`:environment:NAME` are three different strings, and a trust policy listing only one will work for
that trigger and silently fail for the others.

The **prefix** differs too. Repositories created, renamed, or transferred after 2026-07-15 use
immutable subject claims, embedding permanent numeric IDs:

```
classic:    repo:OWNER/REPO
immutable:  repo:OWNER@000000000/REPO@0000000000
```

The IDs survive renames by design, so renaming a repository does not restore the classic format.
`08_github_oidc` handles both via the `sub_claim_prefix` variable, which defaults to `null` (classic).

| Error | Cause |
|---|---|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | Subject mismatch — wrong prefix, or the trigger's suffix isn't listed |
| `Source Account ID is needed if the Role Name is provided` | The role variable isn't a valid ARN — usually quotes copied from `tofu apply` output. Use `tofu output -raw` |
| `Credentials could not be loaded` | The job is missing `id-token: write` |
| `failed to get shared config profile` | A `profile` line survived in a `backend.tf` |

## Cost

This is **not free while running** — two components carry a flat hourly charge regardless of
traffic:

| Resource | Rate | Qty | Cost/hr |
|---|---|---|---|
| AWS Network Firewall endpoint (single AZ) | $0.395/hr | 1 | $0.395 |
| TGW VPC attachments | $0.05/hr each | 3 | $0.150 |
| NAT Gateway | $0.045/hr | 1 | $0.045 |
| Public IPv4 address (NAT EIP) | $0.005/hr | 1 | $0.005 |
| **Total** | | | **≈ $0.595/hr** |

Plus data-processing charges only if you push real traffic: TGW $0.02/GB, NAT $0.045/GB, Network
Firewall $0.065/GB — a connectivity test pushes at most a few MB, effectively free. The S3/
DynamoDB state backend and CloudWatch Logs (3-day retention) are pennies and safe to leave up
indefinitely.

**Tear down with `tofu destroy` in reverse order (`07` → `01`) as soon as you're done testing** —
leaving this running for a month runs ≈ $430+. `00_bootstrap` can be left up; it costs nothing
meaningful on its own.

## Design tradeoffs

Everything here optimizes for **cheap, disposable, and correct to test** — not production
readiness. Worth naming explicitly, since none of these are accidents:

- **Single AZ, deliberately.** Every VPC, the NAT Gateway, and the Network Firewall endpoint live
  in one AZ (`us-east-2a`). A second AZ would double the Network Firewall endpoint cost
  (`$0.395/hr → $0.79/hr`) and add a second NAT Gateway, TGW-attachment subnet, and firewall
  subnet — for a lab whose entire purpose is proving the routing and firewall-policy logic work,
  not surviving an AZ outage. Multi-AZ is the first thing to add (see below) if this ever needs to
  hold real traffic.
- **Implicit-allow firewall policy, deliberately.** Two `DROP` rules plus `DEFAULT_ACTION_ORDER`
  implicit-allow, instead of an allow-list. This keeps the policy legible in one read and keeps the
  lab focused on demonstrating segmentation, not building out a production rule set.
- **One subnet per spoke VPC, deliberately.** Prod and Dev each get a single subnet spanning their
  whole `/24` rather than a dedicated TGW-attachment subnet separate from workload subnets — there's
  no workload segmentation need at this scale, so the extra subnet would be complexity without a
  corresponding benefit.

## Verification

Validated end-to-end against real AWS resources: SSM-managed EC2 instances launched into the Prod
and Dev subnets (outside of this lab's stages — bring your own test instances).

**Egress confirmed** via CloudWatch FLOW logs showing complete round-trip flows (NTP time sync,
TLS to SSM endpoints) from both spokes out through the firewall to public internet IPs.

**Isolation confirmed** via a live CloudWatch ALERT log entry:

```json
{
  "event_type": "alert",
  "src_ip": "10.235.0.18", "dest_ip": "10.232.0.29", "proto": "TCP", "dest_port": 80,
  "alert": { "signature_id": 1, "action": "blocked" },
  "verdict": { "action": "drop" },
  "pkt_src": "geneve encapsulation"
}
```

`signature_id: 1` is the Prod→Dev rule from `05_network_firewall`; `pkt_src: "geneve
encapsulation"` confirms the traffic genuinely arrived via the TGW attachment (Network Firewall
receives TGW-forwarded traffic over Geneve) rather than some other path.

To reproduce: launch an SSM-managed instance in each spoke subnet, then from one, `ping` /
`curl -m 5` the other's private IP (should hang/fail) and `curl https://checkip.amazonaws.com`
(should succeed and return the NAT Gateway's EIP). Check the `.../alert` log group for the DROP
event and the `.../flow` log group for the egress round trip.

## Things to review before treating this as production-ready

- `prevent_destroy` is set on the TGW and both TGW route tables (`01_tgw_core`) — remove it
  deliberately before a real teardown, or edit it out ahead of `tofu destroy`.
- Single AZ, no redundancy — a production deployment needs a firewall endpoint, NAT Gateway, and
  TGW attachment subnet per AZ.
- The firewall policy allows everything except the two explicit Prod↔Dev DROP rules — fine for
  demonstrating segmentation, but production traffic filtering usually wants an allow-list and/or
  domain/IDS rule groups, not implicit allow.
- No EC2/workload stage is included on purpose — this lab is scoped to the network/inspection
  layer; bring your own compute.
- CloudWatch Logs retention (`log_retention_days`, default 3) is short to keep cost near zero —
  raise it for anything longer-lived than a test session.
- The CI pipeline is a convention, not a control: local credentials still carry enough privilege
  to apply outside it. Enforcing it means scoping the state bucket policy to the apply role and
  reducing standing human permissions — with a separate break-glass path.
- No drift detection. A scheduled `tofu plan -detailed-exitcode` across every stage, opening an
  issue on exit code 2, would catch out-of-band changes.
- Checkov runs with `continue-on-error: true`, so it reports findings without blocking. Triage the
  baseline and remove that line to make it a real gate.
- The apply role's `ec2:*` is broader than necessary. Narrow it from CloudTrail evidence once the
  set of actions an apply actually calls is known.

## Conventions when adding resources

- New stages get a numeric prefix matching their position in the apply order — don't reuse a
  number, since `terraform_remote_state` references would collide.
- Single AWS account, so providers are unaliased (unlike `aws-tgw-dxgw-vpc-PROJECT/`'s
  `aws.core`/`aws.workload` split) — every stage has one `provider "aws" {}` block.
- Cross-stage data passes through `terraform_remote_state`, never module composition.
- Route tables that get routes added by a *later* stage (e.g. the spoke route tables, or the
  Inspection VPC's three route tables) are created with `lifecycle { ignore_changes = [route] }`
  and populated exclusively with standalone `aws_route` resources — never mix those with an inline
  `route` block on the same table.