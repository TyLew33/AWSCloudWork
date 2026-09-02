# aws-infrastructure-portfolio

A collection of AWS infrastructure work, ranging from a full multi-account
network deployment to focused, single-concept examples of specific services
and patterns. The code favors real deployment concerns — staged state,
least-privilege-shaped policies, provider aliasing across accounts — over
tutorial simplicity.

## Featured project: `aws-tgw-dxgw-vpc-PROJECT/`

An OpenTofu reference deployment for a staged, multi-account **AWS Transit
Gateway + Direct Connect Gateway + VPC** setup: a workload VPC reaches an
on-prem network via a regional Transit Gateway and an existing Direct Connect
Gateway, with internal DNS resolved through RAM-shared Route 53 Resolver
rules.

The deployment is split across two AWS accounts — a **core** account that
owns the TGW, its route table, and the RAM share, and a **workload** account
that owns the VPC and its TGW attachment — and is applied as 8 independently
staged OpenTofu root modules (`01_*` – `08_*`), each with its own state file,
wired together with `terraform_remote_state` rather than a single monolithic
apply.

```
┌─────────────────────────── core account ───────────────────────────────┐
│  01_dxgw_inputs  ──►  06_dxgw_association  ──►  DXGW  ──►  on-prem     │
│        │                                                               │
│        ▼                                                               │
│  02_tgw_core ──► core TGW + route table                                │
│        │                                                               │
│        ▼                                                               │
│  03_ram_shares ──── RAM share of TGW ──────────────────┐               │
│  07_tgw_dxgw_rt_associations (DXGW attachment           │               │
│     assoc + prop into the core TGW route table)         │               │
└──────────────────────────────────────────────────────────┼─────────────┘
                                                            │
┌──────────────────────── workload account ─────────────────▼───────────┐
│  04_workload_vpc ─► workload VPC                                       │
│       │ (invokes 04_security child module: NACL + SG)                 │
│       ▼                                                                │
│  05_tgw_vpc_attachment ─► VPC attached to shared TGW                   │
│                         ─► public route table on-prem routes          │
│       │                                                                │
│       │ (TGW RT assoc + prop done by core-account stage 05b ──┐       │
│       │  — TGW route tables are not RAM-shareable)             │       │
│       ▼                                                        │       │
│  08_route53_resolver_shared ─► associates RAM-shared resolver  │       │
│                                rules with the workload VPC     │       │
└─────────────────────────────────────────────────────────────────┼─────┘
                                                                   │
┌───────────────── core account (continued) ──────────────────────▼────┐
│  05b_tgw_rt_associations ─► core TGW route table gets:                │
│                              • assoc: VPC attachment                  │
│                              • prop:  VPC attachment                  │
└─────────────────────────────────────────────────────────────────────┘
```

The non-obvious constraint that shapes the whole design: **TGW route tables
aren't RAM-shareable.** The workload account can attach its VPC to a
RAM-shared TGW (stage `05`), but it cannot associate or propagate that
attachment into the TGW's route table — only the owning core account can do
that. That's why the route-table wiring is split into its own stage,
`05b_tgw_rt_associations`, run under the core account's credentials, instead
of being folded into `05`. The same split repeats for the DXGW side (`06`
association, `07` route-table wiring). Getting this ordering wrong is a
common failure mode in real multi-account TGW deployments, and the staged,
numbered layout here exists specifically to make that ordering explicit and
enforceable rather than something the operator has to remember.

See [aws-tgw-dxgw-vpc-PROJECT/README.md](aws-tgw-dxgw-vpc-PROJECT/README.md)
for the full stage table, apply order, ordering constraints, and getting-started
guide.

## Other work

| Directory | Stack | What it demonstrates |
|---|---|---|
| `inspection-vpc-PROJECT/` | OpenTofu | A staged, single-account centralized-inspection VPC lab — Prod and Dev VPCs that reach the internet but not each other, enforced by AWS Network Firewall behind a Transit Gateway. Applied and validated end-to-end against live AWS resources (see its README's Verification section). |
| `Step-Functions/` | AWS SAM, ASL | A Step Functions state machine (validate → complete) with unit and integration tests under `sam-app/tests/`. |
| `lambda/` | SAM, Docker/ECR | A basic Lambda handler plus a container-image Lambda built and pushed to ECR. |
| `sns/sqs/` | SAM, IAM policy JSON | SNS fan-out to per-purpose SQS queues (email, inventory), each with its own scoped access policy. |
| `s3/` | AWS CLI (bash), CFN, Terraform | CORS-configured static hosting, SSE encryption, checksum validation, ETag behavior, prefix listing, and lifecycle rules — with parallel CloudFormation and Terraform variants of the same bucket. |
| `aws-asg/` | Terraform | An Auto Scaling Group with a launch template and provider configuration. |
| `rds_tofu_lab/` | OpenTofu | A standalone RDS instance provisioned via OpenTofu. |
| `vpc/basics/` | AWS CLI (bash) | Scripted, from-scratch VPC creation and teardown (IGW, subnet) outside of any IaC tool. |
| `iam/` | CloudFormation | An inline IAM policy attached via a CFN template. |

### `inspection-vpc-PROJECT/` design tradeoffs

Single AZ is deliberate, not a shortcut: doubling AZs would double the Network Firewall endpoint
cost and add a second NAT Gateway, TGW-attachment subnet, and firewall subnet per VPC, for a lab
whose purpose is validating routing and firewall-policy correctness rather than surviving an AZ
failure. See its README's own
[Design tradeoffs](inspection-vpc-PROJECT/README.md#design-tradeoffs) section for the rest.

## Tooling

Terraform / OpenTofu, AWS SAM, CloudFormation, AWS CLI, Python, Bash, and a
devcontainer for a consistent local environment.

## Repository conventions

`aws-tgw-dxgw-vpc-PROJECT/` is a full, staged, multi-account deployment
meant to be read end-to-end. Everything else in this repo is a focused
example of a single service or pattern — useful in isolation, but not
representative of the scale of the featured project. Don't take the size of
a directory as a signal of its complexity; `rds_tofu_lab/` is a few files on
purpose, `aws-tgw-dxgw-vpc-PROJECT/` is not.
