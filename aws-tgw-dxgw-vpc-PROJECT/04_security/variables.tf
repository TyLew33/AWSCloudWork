variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "project_name" {
  type        = string
  description = "Naming prefix for the NACL/SG created here"
  default     = "example-landing-zone"
}

variable "public_ingress_cidr" {
  type        = string
  description = "CIDR allowed to reach the web/app ports and ICMP from the internet"
  default     = "0.0.0.0/0"
}

variable "web_ports" {
  type        = list(number)
  description = "Public-facing TCP ports (e.g. 80/443)"
  default     = [80, 443]
}

variable "app_ports" {
  type        = list(number)
  description = "Application-specific TCP ports exposed publicly (example placeholder for whatever your workload listens on)"
  default     = [8080, 8443]
}

variable "trusted_cidrs" {
  type        = list(string)
  description = "CIDRs (typically on-prem/RFC1918) allowed all-traffic ingress — mirrors the on-prem TGW routes"
  default     = ["10.0.0.0/8"]
}

variable "nfs_cidrs" {
  type        = list(string)
  description = "Optional CIDRs allowed tcp/2049 (NFS) ingress. Leave empty to omit the rule entirely."
  default     = []
}
