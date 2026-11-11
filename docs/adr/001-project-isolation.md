# ADR-001: Project Isolation and Infrastructure Boundaries

## Context

The AWS Enterprise Hybrid Infrastructure & Migration project operates within an existing AWS Organization that also hosts the AWS Secure Multi-Account Cloud Platform project.

Both implementations require independent infrastructure lifecycles to minimise the risk of unintended changes to shared AWS resources.

## Decision

Maintain the hybrid migration project as an independent implementation within the existing AWS Organization.

Isolation is enforced through:

- A dedicated GitHub repository and Terraform root modules.
- Separate Terraform state locations and a dedicated S3 backend.
- Account-specific AWS deployment profiles and Terraform `allowed_account_ids`.
- Project-specific resource names and tags.
- Non-overlapping on-premises and AWS network CIDRs.
- Separate application credentials, documentation and operational procedures.

Project 3 uses the repository `aws-enterprise-hybrid-migration` and the S3 state bucket `project3-hybrid-terraform-state-euw2`.

Network and Development Terraform state are stored separately using native S3 locking.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Extend the existing cloud platform repository | Rejected | Increases cross-project dependencies and Terraform state risk |
| Create an independent AWS Organization | Rejected | Adds unnecessary governance and administrative overhead |
| Isolate resources within the existing Organization | Selected | Maintains separate project lifecycles while reusing established account infrastructure |

## Implementation

The project uses three AWS accounts for Management, Network and Development responsibilities.

Infrastructure deployed within these boundaries includes:

- Centralised Transit Gateway and Site-to-Site VPN connectivity.
- Development VPC (`10.30.0.0/16`) and private subnets.
- Cross-account Transit Gateway attachment.
- Private EC2 application infrastructure.
- Amazon RDS PostgreSQL migration environment.

The on-premises VMware network uses `10.10.0.0/24`, avoiding address overlap with the AWS VPC.

Terraform state, saved plans, private SSH keys, VPN secrets and application credentials are excluded from version control.

The Bootstrap Terraform environment retains local state.

## Consequences

**Benefits**

- Independent deployment and change-management lifecycle.
- Reduced risk of interfering with existing infrastructure.
- Clear infrastructure ownership and state separation.
- Reusable AWS organisational foundation.

**Trade-offs**

- AWS accounts and governance remain shared.
- Isolation depends on IAM permissions and deployment discipline.
- Separate Terraform backends require additional administration.
- Locally stored Bootstrap state requires appropriate protection and backup.

## Validation

- Independent Terraform environments deployed successfully.
- AWS account restrictions and remote-state separation established.
- Private hybrid connectivity operational.
- Application and database migration completed within the Development account.
- Existing cloud platform infrastructure remained outside the Project 3 deployment scope.

## References

- [AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)