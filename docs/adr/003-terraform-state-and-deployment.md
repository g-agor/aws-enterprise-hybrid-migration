
# ADR-003: Terraform State Management and Deployment Strategy

**Status:** Accepted  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## Context

The project provisions infrastructure across multiple AWS accounts using Terraform.

Terraform state records mappings between declared resources and deployed AWS infrastructure. Loss, corruption or concurrent modification of state could lead to configuration drift, failed deployments or unintended infrastructure changes.

The project requires:

- Account-specific infrastructure isolation
- Secure and durable Terraform state storage
- Concurrency protection during deployments
- Reproducible Terraform provider versions
- Temporary AWS credentials rather than static access keys
- Recovery from partially completed deployments
- Isolation from existing Project 2 infrastructure

## Decision

Use separate Terraform root modules for Bootstrap, Network and Development.

Store Network and Development state remotely in a versioned Amazon S3 bucket owned by the AWS Organizations Management account.

Use native S3 state locking through Terraform's `use_lockfile = true` option.

Retain the Bootstrap Terraform state locally because Bootstrap manages the S3 bucket used by the other environments.

Use separate AWS provider profiles for each account, with `allowed_account_ids` enforcing deployment boundaries.

### State Architecture

| Root Module | State Location | AWS Account |
|---|---|---|
| Bootstrap | Local Terraform state | Management |
| Network | S3: `network/terraform.tfstate` | Network |
| Development | S3: `development/terraform.tfstate` | Development |

**State bucket:** `project3-hybrid-terraform-state-euw2`  
**Bucket owner:** Management account (`297580067519`)  
**AWS Region:** `eu-west-2`

The state bucket is configured with:

- S3 bucket versioning
- Server-side encryption using SSE-S3 (AES-256)
- Block Public Access
- HTTPS-only access policy
- Terraform `prevent_destroy` lifecycle protection

The S3 backend uses the Management account's `T-Builder` profile.

Terraform AWS providers use account-specific profiles to deploy resources into their respective workload accounts.

## Alternatives Considered

### Option 1: Local Terraform State for All Environments

**Advantages**
- Simple initial setup
- No remote backend dependency
- Minimal infrastructure overhead

**Disadvantages**
- State loss risk if the development machine fails
- No built-in shared locking
- Difficult team collaboration
- Inappropriate for repeatable enterprise-style operations

**Outcome:** Rejected for Network and Development.

### Option 2: S3 Backend with DynamoDB Locking

**Advantages**
- Established locking pattern
- Familiar to many existing Terraform environments

**Disadvantages**
- Requires an additional DynamoDB table
- Adds infrastructure and operational overhead
- DynamoDB-based locking has been deprecated in newer Terraform versions

**Outcome:** Rejected in favour of native S3 locking.

### Option 3: S3 Backend with Native Locking

**Advantages**
- Secure, versioned remote state
- Built-in concurrency protection
- Fewer supporting AWS resources
- Clear separation of environment state
- Compatible with the chosen Terraform version

**Disadvantages**
- Depends on S3 availability and backend permissions
- Requires careful cross-account credential management
- Backend configuration must be maintained separately from the AWS provider

**Outcome:** Selected.

## Credential and Account Strategy

AWS CLI profiles provide temporary credentials through STS AssumeRole.

The following profiles are used:

| Purpose | Profile |
|---|---|
| Management and S3 backend | `T-Builder` |
| Network Terraform provider | `project3-network-terraform` |
| Development Terraform provider | `project3-dev-terraform` |

Terraform-compatible provider profiles use AWS CLI `credential_process` to export temporary credentials from the existing account-assumption profiles.

No permanent AWS access keys are required in Terraform configuration.

Provider-level `allowed_account_ids` restrict deployment to the intended AWS account.

## Deployment Dependency Strategy

The infrastructure is deployed in a controlled sequence:

1. Bootstrap: create the remote-state bucket.
2. Network: create Transit Gateway, route tables, VPN and RAM share.
3. Development: create VPC, private subnets and TGW attachment.
4. Network: accept the cross-account attachment and configure TGW routing.
5. Development: enable routes from private subnets towards the on-premises LAN.
6. On-premises: configure IPsec and validate hybrid connectivity.

This order resolves dependencies between the account that owns the Transit Gateway and the account consuming the shared resource.

## Recovery from Partial Deployment Failure

During the Network deployment, AWS RAM rejected two resource-share associations with `OperationNotPermittedException`.

Terraform successfully recorded the other deployed resources in remote state.

The investigation verified AWS Organizations membership, trusted access, the RAM service-linked role, its permissions and the resource-share configuration.

After RAM integration was established, a fresh Terraform reconciliation plan successfully created the two remaining associations.

This demonstrated that:

- Terraform applies are not atomic transactions.
- Successfully created resources can remain deployed when other resources fail.
- Remote state should be preserved during recovery.
- A fresh plan should be generated after a partial deployment.
- Saved plans must not be reused after infrastructure state changes.

The deployed Transit Gateway and VPN were preserved throughout recovery.

## Security Considerations

- Never commit Terraform state or saved plan files.
- Exclude `.tfvars`, environment files and credential material from version control.
- Commit `.terraform.lock.hcl` to preserve dependency selections.
- Restrict S3 backend access to authorised identities.
- Use temporary STS credentials.
- Avoid placing credentials and VPN pre-shared keys in Terraform output or documentation.
- Protect the Bootstrap local state separately from the repository.
- Review state bucket encryption and access controls before production use.

## Consequences

### Positive

- Isolated state for Network and Development
- Centralised remote-state governance
- Versioned state recovery capability
- Terraform concurrency protection
- Reproducible provider dependencies
- Reduced risk of cross-account deployment errors
- Documented recovery from partial infrastructure failures

### Negative

- Additional backend and credential configuration
- Dependency on the Management account for remote state
- Local Bootstrap state requires separate protection
- Cross-account deployments require carefully coordinated execution

## Validation

**Completed**
- Created and verified the S3 state bucket
- Confirmed S3 versioning, encryption and public access restrictions
- Initialised Network and Development remote backends
- Validated Terraform configurations
- Deployed Network and Development infrastructure
- Recovered successfully from a partial Network deployment
- Committed Terraform configurations and provider lockfiles to Git

**Pending**
- Periodically review backend IAM permissions
- Implement a protected backup procedure for Bootstrap local state
- Document tested Terraform state-recovery procedures

## References

- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Terraform State](https://developer.hashicorp.com/terraform/language/state)
- [Terraform Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
- [AWS S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
