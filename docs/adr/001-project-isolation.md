# ADR 001: Isolate Project 3

Status: accepted for the initial lab foundation.

Keep the existing repository and initial history. Use separate AWS profiles, explicit account allowlists, new state buckets, and unique backend keys for each environment. Never edit Project 2 or shared credential files as part of this project.

Bootstrap uses local state initially, stored outside Git. The state bucket enables versioning, encryption, public-access blocking, TLS-only access and deletion protection. Migrate bootstrap state into its own S3 key after creation, then back it up securely. S3 native locking requires Terraform 1.10 or newer.

The first VPC has two private subnets across explicitly selected availability zones. It has no internet gateway, NAT gateway, or external route. CIDR 10.30.0.0/16 is a proposal: verify against Project 2, on-premises, VPN and all AWS routes before applying. Transit Gateway and VPN are deferred until account, address, home-router NAT and public-IP requirements are verified. These later services incur ongoing charges.
