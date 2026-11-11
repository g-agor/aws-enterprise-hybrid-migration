# ADR-003: Terraform State Management and Deployment Strategy

## Context

The hybrid migration project provisions infrastructure across multiple AWS accounts using Terraform. Secure state management is essential to prevent deployment conflicts, configuration drift and unintended changes to existing infrastructure.

The architecture requires independent state, concurrency protection, controlled AWS credentials and a reliable approach to recovering from partial deployment failures.

## Decision

Use separate Terraform root modules for **Bootstrap, Network and Development**, with Network and Development state stored remotely in a dedicated, versioned Amazon S3 bucket.

| Environment | State location | AWS account |
|---|---|---|
| Bootstrap | Local Terraform state | Management |
| Network | `network/terraform.tfstate` | Network |
| Development | `development/terraform.tfstate` | Development |

**State bucket:** `project3-hybrid-terraform-state-euw2`  
**Region:** `eu-west-2`

The S3 backend implements:

- Versioning and SSE-S3 encryption.
- Block Public Access and HTTPS-only access.
- Native Terraform state locking using `use_lockfile = true`.
- Terraform `prevent_destroy` protection for the bucket resource.

Terraform providers use account-specific profiles, temporary AWS credentials and `allowed_account_ids` restrictions. Provider dependency lock files are committed to Git.

The Bootstrap environment retains local state because it provisions the remote-state infrastructure.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Local state for all environments | Rejected | No shared locking and greater risk of state loss |
| S3 with DynamoDB locking | Rejected | Additional infrastructure and deprecated locking mechanism |
| S3 with native locking | Selected | Versioned remote state and concurrency protection without DynamoDB |

## Deployment Strategy

Infrastructure deployment follows account and resource dependencies:

1. **Bootstrap:** Provision the S3 state backend in Management.
2. **Network:** Deploy Transit Gateway, VPN and AWS RAM sharing.
3. **Development:** Deploy the VPC, private subnets and TGW attachment.
4. **Network:** Configure cross-account attachment routing.
5. **Development:** Configure private routes and deploy migration workloads.
6. **On-premises:** Establish VPN connectivity and complete workload migration.

This sequence separates resource ownership while accommodating cross-account networking dependencies.

## Implementation and Recovery

Network and Development infrastructure were deployed successfully using separate remote-state configurations.

During an earlier Network deployment, AWS RAM rejected two resource-share associations. Terraform preserved successfully deployed resources in state, allowing the remaining associations to be created through a fresh reconciliation plan.

This demonstrated that Terraform operations are not atomic and that partial failures should be recovered through state inspection and replanning rather than deleting infrastructure or reusing outdated saved plans.

The same controlled reconciliation approach was subsequently used when addressing Terraform routing configuration drift.

## Consequences

**Benefits**

- Independent Network and Development state.
- Centralised, encrypted and versioned state storage.
- Concurrency protection without DynamoDB.
- Reduced cross-account deployment risk.
- Reproducible provider dependencies.
- Recovery from partial deployment failures.

**Trade-offs**

- Remote state depends on Management account availability and permissions.
- Cross-account deployment requires coordinated configuration.
- Bootstrap local state requires separate backup and protection.
- S3 backend access and permissions require ongoing governance.

## Validation

- Verified S3 backend encryption, versioning and access restrictions.
- Initialised Network and Development remote state.
- Successfully deployed Terraform-managed infrastructure across the accounts.
- Recovered from partial deployment failures without destroying existing resources.
- Maintained project-specific source control and provider dependency lock files.

## References

- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Terraform State](https://developer.hashicorp.com/terraform/language/state)
- [Terraform Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
- [Amazon S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)