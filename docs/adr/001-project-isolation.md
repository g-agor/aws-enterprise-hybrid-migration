
# ADR-001: Project Isolation and Infrastructure Boundaries

**Status:** Accepted  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## 1. Context

Project 3 demonstrates an enterprise-style hybrid infrastructure and workload migration from an on-premises VMware environment into AWS.

The AWS accounts used for this project also contain infrastructure from an existing portfolio project, Project 2: AWS Secure Multi-Account Cloud Platform.

Project 3 must be developed independently without modifying, destroying or unintentionally affecting existing Project 2 infrastructure.

The design therefore requires isolation across:

- Source code and version control.
- Terraform state.
- AWS infrastructure resources.
- IAM deployment identities.
- Network address ranges and routing.
- Secrets and credentials.
- Operational documentation.

## 2. Decision

Maintain Project 3 as a separate infrastructure project with its own GitHub repository, Terraform root modules, state configuration, naming conventions and documentation.

Use the existing AWS Organization and its accounts while ensuring that Project 3 resources are logically isolated from existing infrastructure.

Apply the following controls:

1. Use a dedicated Project 3 Git repository.
2. Keep Project 2 source code and Terraform state unchanged.
3. Use unique Terraform state keys.
4. Use project-specific infrastructure resource names and tags.
5. Enforce AWS account restrictions through Terraform provider allowlists.
6. Use temporary AWS credentials through approved profiles.
7. Use non-overlapping VPC and on-premises network CIDRs.
8. Review Terraform plans before deployment.
9. Avoid unmanaged changes to existing shared AWS resources.
10. Maintain separate architectural documentation and operational evidence.

## 3. Alternatives Considered

### Option 1: Extend the Existing Project 2 Repository

Add the hybrid migration infrastructure to the existing Project 2 codebase.

**Advantages**

- Reuses existing code and deployment configuration.
- Reduces repository administration.
- Allows some shared infrastructure definitions.

**Disadvantages**

- Increases the risk of modifying existing infrastructure.
- Mixes unrelated project lifecycles.
- Makes project-specific validation and documentation less clear.
- Creates additional Terraform dependency and state-management risks.

**Outcome:** Rejected.

### Option 2: Create an Entirely Separate AWS Organization

Create new AWS accounts within an independent AWS Organization.

**Advantages**

- Strongest organisational separation.
- Independent billing and governance.
- Reduced risk of impacting existing projects.

**Disadvantages**

- Additional account and billing administration.
- Duplicated governance configuration.
- Greater operational overhead for a portfolio lab.

**Outcome:** Rejected due to unnecessary complexity.

### Option 3: Separate Project Resources Within the Existing Organization

Reuse existing AWS accounts but isolate Terraform state, infrastructure resources, deployment configuration and source code.

**Advantages**

- Maintains distinct project lifecycles.
- Reuses existing AWS account infrastructure.
- Reduces operational overhead.
- Supports enterprise-style multi-account architecture.
- Allows separate deployment and recovery procedures.

**Disadvantages**

- Account-level isolation between Project 2 and Project 3 is not absolute.
- Shared account limits and governance controls may affect both projects.
- Configuration mistakes can still affect resources in the same AWS account.
- Requires disciplined resource naming and deployment review.

**Outcome:** Selected.

## 4. Repository Isolation

Project 3 uses its own repository:

`aws-enterprise-hybrid-migration`

Project 2 uses a separate repository:

`aws-secure-multi-account-cloud-platform`

Each repository maintains independent:

- Source code.
- Terraform configurations.
- Infrastructure documentation.
- Git commit history.
- Architecture Decision Records.
- Operational runbooks.

Project 3 changes must not be applied to Project 2 Terraform environments.

## 5. Terraform State Isolation

Project 3 uses a dedicated S3 state bucket in the Management account:

`project3-hybrid-terraform-state-euw2`

The Terraform environments use separate state locations.

| Environment | State Location |
|---|---|
| Bootstrap | Local Terraform state |
| Network | `network/terraform.tfstate` |
| Development | `development/terraform.tfstate` |

The S3 bucket is configured with:

- Versioning.
- SSE-S3 encryption.
- Block Public Access.
- HTTPS-only access policy.
- Terraform lifecycle deletion protection.

Network and Development use native S3 state locking through:

`use_lockfile = true`

The implementation uses Terraform 1.17.1.

The Bootstrap local state must be securely backed up. Moving Bootstrap state to a separate remote backend may be considered later, but it has not been completed.

Terraform state and saved plans must not be committed to Git.

## 6. AWS Account and IAM Boundaries

The project uses three AWS accounts.

| Account | Responsibility |
|---|---|
| Management | AWS Organizations, billing and Terraform state |
| Network | Transit Gateway, VPN and shared network connectivity |
| Development | VPC, private subnets and migration workloads |

Terraform providers use account-specific profiles.

The `allowed_account_ids` provider setting restricts deployments to the intended account.

Temporary STS credentials are used instead of embedding static access keys in Terraform configuration.

Shared account access means that IAM permissions, resource naming and Terraform plan reviews remain essential.

## 7. Network Isolation

The Development VPC uses:

`10.30.0.0/16`

The on-premises VMware LAN uses:

`10.10.0.0/24`

The CIDR ranges do not overlap.

The Development VPC contains:

- Private subnet A: `10.30.0.0/24`
- Private subnet B: `10.30.1.0/24`
- Dedicated private route tables.
- A restrictive default security group.
- A Transit Gateway VPC attachment.

No Internet Gateway or NAT Gateway has been provisioned as part of the initial Development VPC configuration.

Routing between AWS and the on-premises LAN uses the Project 3 Transit Gateway and Site-to-Site VPN infrastructure.

The selected CIDR ranges must remain non-overlapping with existing networks and future connectivity requirements.

## 8. Resource Naming and Ownership

Project-specific names and tags help distinguish infrastructure from other AWS resources.

Where supported, resources use identifiers such as:

`project3-`

Resource naming and tagging provide administrative clarity but do not enforce access isolation.

IAM, Terraform state separation, resource policies and account restrictions remain necessary.

## 9. Security and Secrets

The repository excludes:

- Terraform state files.
- Terraform saved plans.
- Terraform variable files containing local values.
- Environment files.
- Private keys and credential material.
- VPN configuration files containing secrets.

The `.terraform.lock.hcl` files are committed to preserve dependency selections.

Secrets must not appear in Terraform source code, Git history, public documentation or screenshots.

## 10. Implementation Status

**Completed**

- Created an independent Project 3 Git repository.
- Established separate Terraform environments.
- Created a dedicated S3 state bucket.
- Enabled Network and Development remote state.
- Configured account-specific AWS provider profiles.
- Enforced AWS account allowlists.
- Deployed Project 3 Transit Gateway and VPN resources.
- Deployed the Development VPC and private subnets.
- Established the cross-account Transit Gateway attachment.
- Configured AWS-side hybrid routing.
- Created project-specific architecture documentation.

**Pending**

- Securely back up the Bootstrap local Terraform state.
- Verify effective AWS and on-premises routing.
- Configure strongSwan IPsec tunnels.
- Deploy migration destinations.
- Validate workload isolation.
- Complete operational monitoring and recovery testing.

## 11. Consequences

### Positive

- Independent project lifecycle.
- Reduced risk of unintended Project 2 changes.
- Clear ownership of Project 3 infrastructure.
- Separate Terraform state and Git history.
- Reproducible deployments.
- Traceable architectural decisions.
- Enterprise-style multi-account infrastructure.

### Negative

- Some AWS account-level infrastructure remains shared.
- Strong isolation requires ongoing IAM and deployment discipline.
- Additional Terraform backend administration.
- Potential interaction with shared account quotas and governance.
- Risk of cross-project interference if naming or resource references are incorrect.

## 12. Validation

**Completed**

- Confirmed project-specific AWS account targeting.
- Verified Terraform state bucket configuration.
- Validated Terraform configurations.
- Reviewed Terraform plans before deployment.
- Confirmed the Transit Gateway VPC attachment is available.
- Confirmed distinct Development and on-premises CIDR ranges.

**Pending**

- Validate actual hybrid traffic flow.
- Review resource access and permissions.
- Record security and network isolation test results.
- Verify protected Bootstrap state recovery.

## 13. References

- [AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
- [Terraform State](https://developer.hashicorp.com/terraform/language/state)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [AWS VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
