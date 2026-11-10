# AWS Enterprise Hybrid Infrastructure & Migration

Project 3: an isolated hybrid infrastructure and migration lab in eu-west-2.

## Target architecture

Three Ubuntu Server 24.04 VMs on VMware Fusion (Intel Mac): Flask/Gunicorn application, PostgreSQL 16 database, and strongSwan VPN gateway. AWS target: separate network and development accounts, Transit Gateway, Site-to-Site VPN, application/database migration, and recovery exercises.

## Current implementation

- Initial repository committed and pushed to the private GitHub repository.
- Terraform state bootstrap and private VPC foundation prepared; not deployed.
- Transit Gateway, VPN, application, database, and recovery stages remain planned.

Start with [GitHub setup](docs/github-setup.md), then [Terraform workflow](docs/terraform-workflow.md).
Architecture decisions are in [ADR 001](docs/adr/001-project-isolation.md).

## Isolation

Use a dedicated Project 3 AWS profile and verify its account before planning. Do not reuse Project 2 state, buckets, Terraform directories, or backend keys. Never commit credentials, state, plans, or local variable files.
