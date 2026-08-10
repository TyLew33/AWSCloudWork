# aws-tgw-dxgw-vpc-PROJECT

An **OpenTofu** reference Project for a staged, multi-account AWS Transit Gateway + Direct Connect
Gateway + VPC deployment that connects a workload VPC to an on-prem network via a regional Transit
Gateway and an existing Direct Connect Gateway, with DNS resolution for internal zones via
RAM-shared Route 53 Resolver rules.

`PROJECT` in this repo's name is a placeholder — when you copy this template for a real deployment,
rename the directory (and, optionally, the `project_name` variable default in each stage) to your
own project identifier, e.g. `aws-tgw-dxgw-vpc-anz-hezp`.

This is a genericized template distilled from a real production deployment. It is meant to be
**read, copied, and adapted** — not applied as-is. Every account ID, CIDR range, resource ID, and
DNS zone in this repo is a placeholder. Fill in your own via `terraform.tfvars` / `backend.tf`
(see [Getting started](#getting-started) below) before running anything.

## Architecture

- A **core account** owns the regional Transit Gateway, its route table, the RAM share, and the
  Direct Connect Gateway association.
- A **workload account** owns the VPC, subnets, security group/NACL, and the TGW VPC attachment.
- The workload VPC has a **single public-subnet tier** (no private subnets) — public subnets reach
  on-prem via the TGW → DXGW → DX path, and reach the internet directly via an IGW. Both route sets
  live in one route table.
- Internal DNS zones are resolved through RAM-shared Route 53 Resolver rules, consumed from the
  workload VPC.

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

Data flow after apply, all from the single public route table:
- **To on-prem:** public-subnet host → route table's on-prem CIDR routes → TGW → TGW route table →
  DXGW association (`allowed_prefixes` from stage 06) → DXGW → DX → on-prem.
- **To the internet:** public-subnet host → `0.0.0.0/0` route → IGW → internet (instances need
  `map_public_ip_on_launch = true` or an assigned Elastic IP).
- **DNS:** a query for an internal zone from a VPC instance → VPC resolver → matched RAM-shared
  resolver rule (stage 08) → forwarded to the on-prem DNS server defined in the rule's owning
  account.

## Repo layout

Numbered top-level directories (`01_*`–`08_*`) are a **staged deployment**. Each is a separate
OpenTofu root module with its own state file, applied in numeric order. The one exception is
`04_security`, a **child module** (no backend, no provider config) invoked by `04_workload_vpc` —
it is not applied on its own.

| Stage | Account | Purpose |
|---|---|---|
| `01_dxgw_inputs` | core | Passthrough only — pins an existing DXGW ID + allowed prefixes as outputs. Creates no resources. |
| `02_tgw_core` | core | Creates the regional TGW and its explicit route table (default association/propagation disabled). |
| `03_ram_shares` | core | RAM-shares the TGW with the workload account. Must apply before `05`. |
| `04_workload_vpc` | workload | VPC, IGW, 2 public subnets, one route table. Invokes `04_security` inline. |
| `04_security` | workload (child module) | NACL + security group, associated to the public subnets. |
| `05_tgw_vpc_attachment` | workload | TGW VPC attachment + on-prem routes in the public route table. Does **not** create the TGW RT association/propagation (see `05b`). |
| `05b_tgw_rt_associations` | core | TGW RT association + propagation for the VPC attachment — must run under the core profile because TGW route tables aren't RAM-shareable. |
| `06_dxgw_association` | core | Associates the DXGW with the TGW, restricted to `allowed_prefixes`. |
| `07_tgw_dxgw_rt_associations` | core | TGW RT association + propagation for the (implicit) DXGW attachment. |
| `08_route53_resolver_shared` | workload | Associates RAM-shared Route 53 Resolver rules with the workload VPC. |

### Apply order

```
01_dxgw_inputs             (core)
02_tgw_core                (core)
03_ram_shares               (core)      ← must precede 05
04_workload_vpc            (workload)  ← invokes 04_security inline
05_tgw_vpc_attachment      (workload)
05b_tgw_rt_associations     (core)      ← wires VPC attachment into the core TGW RT
06_dxgw_association         (core)      ← TGW <-> DXGW association only
07_tgw_dxgw_rt_associations (core)      ← wires DXGW attachment into the core TGW RT
08_route53_resolver_shared (workload)
```

Ordering constraints:
- `02` before `03`, `05`, `05b`, `06` (TGW must exist)
- `03` before `05` (TGW must be shared to the workload account)
- `04` before `05`, `08` (VPC must exist)
- `05` before `05b` (the attachment must exist and be `available` — either set
  `auto_accept_shared_attachments = "enable"` on the TGW or accept it from the owner side first)
- `01` before `06` (DXGW inputs needed)
- `06` before `07` (the DXGW association must exist before its implicit TGW attachment can be
  looked up via data source in `07`)

`01`, `02`, and `04` are independent of each other and can be applied in any interleaving.

## Getting started

### Prerequisites

- Two AWS accounts (or one account playing both roles, with two CLI profiles) — a **core** account
  and a **workload** account.
- An existing Direct Connect Gateway with a virtual interface to your on-prem network.
- An S3 bucket + DynamoDB table for OpenTofu remote state, bootstrapped separately (not part of
  this example) — see [Remote state backend](#remote-state-backend) below.
- If you use RAM-shared Route 53 Resolver rules from a separate DNS account, those rules must
  already exist and be shared (and the share accepted) before `08_route53_resolver_shared` will
  work.
- Two named AWS CLI profiles matching whatever you set `core_profile` / `workload_profile` to.

### Remote state backend

Every stage's `backend.tf` has a literal S3 backend block with placeholder values
(`bucket = "opentofu-state-bucket"`, `dynamodb_table = "opentofu-state-lock"`, `region =
"us-east-2"`, `profile = "core"`). Before applying, edit the `backend "s3" { ... }` block in each
stage's `backend.tf` to point at your own bucket, lock table, region, and profile — the same
values should also be set on that stage's `state_bucket` / `state_region` / `state_profile` /
`state_key_prefix` variables (used by its `terraform_remote_state` data sources), so keep the two
in sync. Then, per stage:

```sh
cp terraform.tfvars.example terraform.tfvars   # edit with your real values
tofu init
tofu plan
tofu apply
```

`terraform.tfvars` is gitignored — never commit it. Because `backend.tf` here holds literal
values, treat it as configuration you edit locally per environment rather than something to commit
as-is with real bucket/table names — or swap it back to a partial `backend "s3" {}` block plus
`-backend-config=backend.hcl` (gitignored) if you'd rather keep real backend values out of git
entirely.

Note that in this design **every** stage's backend authenticates with the `core` profile, including
workload-account stages — only the core profile needs read/write access to the state bucket and
lock table; the workload profile is only used by the resource provider to create resources in that
account.

### Variables you must set per stage

Each stage directory has its own `terraform.tfvars.example` listing the variables specific to it
(CIDR ranges, the DXGW ID, RAM principal account IDs, resolver rule IDs, etc.), plus a shared set
of naming/tag variables (`aws_region`, `environment`, `project_name`, `core_profile` /
`workload_profile`) and, where the stage reads remote state, `state_bucket` / `state_region` /
`state_profile` / `state_key_prefix` (must match `backend.tf`). Keep these values consistent across
stages — they aren't derived automatically because each stage is an independent root module (see
[Conventions](#conventions-when-adding-resources)).

## Things to review before treating this as production-ready

This is an example distilled for clarity, not a hardened reference architecture. In particular:

- `04_security`'s example security group is deliberately permissive (open ICMP/web/app ports to
  `0.0.0.0/0`, all-traffic from `trusted_cidrs`) to illustrate the pattern — tighten
  `public_ingress_cidr`, `web_ports`, `app_ports`, and `trusted_cidrs` for real use.
- The NACL is allow-all in both directions (a no-op vs. the default NACL) — kept only to show where
  you'd add real rules.
- There's no private subnet tier; add one (with a NAT gateway) if your workloads shouldn't have
  public IPs.
- `prevent_destroy` is set on the TGW, TGW route table, VPC, and DXGW association — remove it
  deliberately if you need to tear the example down.

## Conventions when adding resources

- New stages get a numeric prefix matching their position in the apply order. Don't reuse a
  number — collisions break `terraform_remote_state` references.
- Provider aliases match the owning account: `core` or `workload`. Every resource declares
  `provider = aws.<alias>` explicitly.
- Cross-stage data passes through `terraform_remote_state` outputs from S3, not variables or module
  composition. The one exception is `04_security`, a child module of `04_workload_vpc` because its
  NACL/SG associations are tightly coupled to the subnets created in that same apply.
- Don't hardcode AWS resource IDs (`tgw-...`, `vpc-...`) in stage code except where they reference
  external/RAM-shared resources owned by other repos (e.g. the resolver rule IDs in stage 08).
