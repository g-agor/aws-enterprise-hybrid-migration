
# ADR-010: Security, Resilience and Rollback Strategy

**Status:** Proposed  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## 1. Context

The project implements an enterprise-style hybrid infrastructure and migration architecture spanning on-premises VMware workloads and multiple AWS accounts.

The architecture must protect application and database workloads, preserve data integrity, support controlled recovery and provide evidence of operational readiness.

The project also requires a migration strategy that minimises unnecessary disruption and preserves a viable rollback path.

The current environment consists of:

- AWS Organizations Management account.
- Dedicated AWS Network account.
- Dedicated AWS Development account.
- AWS Transit Gateway.
- AWS Site-to-Site VPN.
- On-premises strongSwan VPN gateway.
- Private Development VPC.
- Two private subnets across separate Availability Zones.
- Flask application hosted on-premises.
- PostgreSQL 16 source database.
- Terraform-managed infrastructure.

The environment is a controlled migration lab rather than a production service.

Security and resilience controls must therefore be assessed against the lab's scope, cost constraints and intended learning outcomes.

## 2. Decision

Adopt a layered security and resilience strategy based on:

1. AWS account separation.
2. Least-privilege identity and access management.
3. Private-by-default workload networking.
4. Encrypted hybrid connectivity.
5. Secure management of secrets.
6. Protected Terraform state.
7. Centralised logging and monitoring.
8. Documented backup and recovery.
9. Controlled migration cutover.
10. Tested rollback procedures.
11. Explicit recovery objectives.
12. Validation of failure scenarios.

Implement controls incrementally according to the deployed workload architecture.

Do not claim production-grade high availability or disaster recovery until those capabilities have been implemented and tested.

## 3. Alternatives Considered

### Option 1: Basic Infrastructure Security Only

Rely on private subnets, security groups and standard AWS service configuration.

**Advantages**

- Lower implementation complexity.
- Lower infrastructure cost.
- Suitable for initial connectivity testing.

**Disadvantages**

- Limited operational visibility.
- Incomplete recovery capability.
- Insufficient evidence of resilience.
- Greater risk of undetected configuration errors.

**Outcome:** Rejected as the final operating model.

### Option 2: Fully Redundant Enterprise Architecture

Implement comprehensive multi-AZ or multi-Region redundancy for networking, applications and databases.

**Advantages**

- Potentially greater availability.
- Reduced dependency on individual components.
- Supports stringent business continuity requirements.

**Disadvantages**

- Significantly higher cost.
- Greater implementation and operational complexity.
- Requires additional testing and lifecycle management.
- Disproportionate to the limited-duration migration lab.

**Outcome:** Not selected for the initial implementation.

### Option 3: Risk-Based Security and Resilience

Implement foundational security controls, targeted redundancy, monitoring, backup and repeatable recovery procedures.

**Advantages**

- Demonstrates security and resilience engineering.
- Supports measurable testing.
- Controls unnecessary infrastructure cost.
- Allows future enhancements.
- Aligns controls with the project's risk profile.

**Disadvantages**

- Some infrastructure remains non-redundant.
- Recovery may require manual intervention.
- Certain production-grade controls remain outside the initial scope.

**Outcome:** Selected as the proposed approach.

## 4. Identity and Access Management

### 4.1 Multi-Account Separation

Separate responsibilities across:

| Account | Responsibility |
|---|---|
| Management | AWS Organizations and Terraform state |
| Network | Shared hybrid networking |
| Development | Workloads and migration destinations |

Account boundaries reduce the impact of accidental or unauthorised changes.

However, account separation does not replace resource-level IAM permissions.

### 4.2 Temporary Credentials

Use temporary credentials and STS AssumeRole for Terraform operations.

Existing Terraform provider configurations enforce account restrictions through `allowed_account_ids`.

Avoid long-lived access keys in source code or repository configuration.

### 4.3 Least Privilege

The current lab uses administrative cross-account access for infrastructure deployment.

Before production adoption, replace broad deployment permissions with more narrowly scoped IAM roles and policies.

Review:

- Terraform deployment permissions.
- Application execution roles.
- Database migration roles.
- Secrets retrieval permissions.
- Logging permissions.
- Backup and recovery permissions.

Privilege boundaries must be appropriate to each operational responsibility.

## 5. Network Security

### 5.1 Private Workloads

The Development VPC uses:

`10.30.0.0/16`

Two private subnets are deployed in separate Availability Zones.

Automatic public IPv4 assignment is disabled.

No general internet egress route is configured in the initial private subnet route tables.

### 5.2 Hybrid Network Encryption

AWS Site-to-Site VPN uses IKEv2/IPsec to protect traffic traversing the public internet.

The Ubuntu strongSwan gateway is responsible for establishing and maintaining the customer-side IPsec connection.

Actual tunnel establishment and cryptographic negotiation must be verified before claiming encrypted hybrid connectivity is operational.

### 5.3 Network Access Controls

Use layered controls including:

- Transit Gateway route tables.
- VPC route tables.
- Workload-specific security groups.
- Network ACLs where justified.
- Ubuntu host firewalls.
- Restrictive PostgreSQL network access.
- Approved application ports.

Routes establish reachability but do not authorise all traffic.

### 5.4 Segmentation Validation

Test both permitted and prohibited communication paths.

Examples include:

- Approved application-to-database connectivity.
- Approved on-premises-to-AWS connectivity.
- Unauthorised database access attempts.
- Unexpected outbound traffic.
- Connectivity following route or firewall changes.

Results should be recorded as operational evidence.

## 6. Data Protection

### 6.1 Encryption at Rest

Evaluate and enable appropriate encryption for:

- EBS volumes.
- Database storage.
- Database backups.
- Application secrets.
- Migration artifacts.
- Terraform state.

The Terraform state bucket currently uses SSE-S3 encryption.

Managed database encryption settings will depend on the selected destination service.

### 6.2 Encryption in Transit

Protect sensitive connections using:

- AWS Site-to-Site VPN.
- TLS for application traffic where appropriate.
- TLS for PostgreSQL connections where required.
- HTTPS for AWS service APIs.

IPsec tunnel encryption does not remove the need to consider application-level transport security.

### 6.3 Secrets Management

Do not embed secrets in:

- Terraform source files.
- Git commits.
- Container images.
- Public documentation.
- Screenshots.
- Application source code.

Evaluate AWS Secrets Manager or other approved secure secret-storage mechanisms.

Apply least-privilege access to applications and migration services.

## 7. Terraform State Protection

Network and Development Terraform state is stored in a Management-account S3 bucket.

The backend provides:

- S3 bucket versioning.
- Server-side encryption.
- Block Public Access.
- HTTPS-only policy.
- Native S3 state locking.

Terraform state may contain sensitive infrastructure attributes even when sensitive output is suppressed.

Access to state must therefore remain restricted.

The Bootstrap Terraform state remains local and requires a separate protected backup procedure.

## 8. Logging and Monitoring

The operating model should include relevant monitoring for:

### Networking

- VPN tunnel state.
- Transit Gateway attachment state.
- Route configuration.
- Connectivity failures.
- Traffic and throughput.

### Compute and Application

- Instance or ECS task health.
- CPU and memory utilisation.
- Application error logs.
- Application availability.
- Application response times.
- Deployment failures.

### Database

- Database availability.
- Connection errors.
- Storage consumption.
- Query performance.
- Backup status.
- Replication or migration lag where applicable.

### Security and Audit

- AWS CloudTrail activity.
- Relevant security events.
- IAM permission changes.
- Network configuration changes.
- Access to sensitive resources.

CloudWatch alarms and operational notifications should be configured for meaningful failure conditions.

Existing Project 2 security services must not be assumed to cover Project 3 resources without verification.

## 9. Availability Architecture

### 9.1 AWS Network Availability

AWS Site-to-Site VPN provides two tunnel endpoints.

Both tunnels must be configured and tested before claiming successful redundancy.

The Transit Gateway is a managed AWS service, but operational availability still depends on correct attachment configuration, routing and the health of connected networks.

### 9.2 Application Availability

Two Development private subnets exist across separate Availability Zones.

However, a single application instance or ECS task would not automatically provide multi-AZ service resilience.

Application availability depends on the final compute deployment.

Possible enhancements include:

- Multiple ECS tasks across Availability Zones.
- EC2 Auto Scaling.
- Appropriate load balancing.
- Automated health checks.
- Controlled deployment strategies.

### 9.3 Database Availability

The database destination has not yet been selected.

Possible resilience approaches include:

- Amazon RDS automated backups.
- RDS Multi-AZ deployments.
- Self-managed PostgreSQL backup and recovery.
- PostgreSQL replication.
- Recovery through infrastructure redeployment.

The selected approach must be justified against downtime tolerance, data loss tolerance and cost.

### 9.4 On-Premises Limitations

The on-premises environment depends on:

- One physical Intel MacBook Pro.
- VMware Fusion.
- A residential router.
- One strongSwan gateway VM.
- A residential internet connection.

These are known single points of failure.

The lab therefore cannot claim production-grade end-to-end high availability.

## 10. Recovery Objectives

Define two recovery measures:

**Recovery Time Objective (RTO):** Maximum acceptable duration to restore service after disruption.

**Recovery Point Objective (RPO):** Maximum acceptable period of data loss, expressed as time.

RTO and RPO requirements have not yet been formally established.

Proposed measurement categories include:

| Scenario | Measurement |
|---|---|
| VPN tunnel interruption | Connectivity restoration duration |
| Application process failure | Time to restore application health |
| Application deployment failure | Time to restore the previous release |
| Database restore | Time to recover a usable database |
| Migration cutover failure | Time to restore the approved service path |

Actual values will be recorded during testing.

Recovery objectives must not be claimed as achieved until supported by evidence.

## 11. Backup Strategy

### 11.1 On-Premises Database

Before migration:

1. Capture a consistent PostgreSQL backup.
2. Verify backup integrity.
3. Record database schema and table counts.
4. Protect the backup from unauthorised access.
5. Test restoration where practical.
6. Preserve the source database during initial cutover.

A backup is only a credible recovery control when restoration has been validated.

### 11.2 AWS Database

The backup strategy will depend on the selected destination.

For Amazon RDS, evaluate automated backups, retention and restore procedures.

For self-managed PostgreSQL, configure and test appropriate backup and restore mechanisms.

### 11.3 Application Infrastructure

Use Terraform to reproduce infrastructure configuration.

Retain application source code, deployment configuration and required runtime dependencies.

Terraform configuration alone is not a substitute for backing up application data.

### 11.4 Terraform State

Preserve protected state versions and maintain documented recovery procedures.

Avoid manual state modification except through a controlled, justified recovery process.

## 12. Migration Cutover Controls

Before cutover:

1. Confirm destination readiness.
2. Verify source and destination data consistency.
3. Confirm network connectivity.
4. Test application functionality.
5. Verify logging and monitoring.
6. Complete a backup or approved recovery checkpoint.
7. Establish a rollback decision point.
8. Record responsible actions and expected outcomes.

During cutover:

1. Restrict or pause writes where necessary.
2. Complete final database synchronisation.
3. Validate the destination.
4. Activate the AWS application.
5. Perform smoke tests.
6. Monitor errors and availability.
7. Decide whether to accept or reverse the cutover.

The final procedure will be maintained as an operational runbook.

## 13. Rollback Strategy

Rollback must restore application functionality without introducing unacceptable data loss.

### 13.1 Rollback Triggers

Potential triggers include:

- Failed application health checks.
- Database integrity mismatches.
- Unexpected database errors.
- Unacceptable application performance.
- Persistent network failures.
- Security or operational incidents.

### 13.2 Application Rollback

Restore the previous approved application deployment or redirect clients to the preserved on-premises application.

Verify application availability and dependencies.

### 13.3 Database Rollback

Determine whether the AWS database accepted new writes after cutover.

If destination-only transactions exist:

- Prevent further divergence.
- Determine the appropriate recovery point.
- Reconcile transactions where possible.
- Restore an approved consistent database state.
- Validate application functionality.

The original source must not be assumed current after destination writes begin.

### 13.4 Network Rollback

If a network change causes failure:

1. Identify the affected Terraform change.
2. Inspect effective routes and attachments.
3. Prepare a reviewed corrective Terraform plan.
4. Restore the approved routing configuration.
5. Validate bidirectional traffic.
6. Record the recovery outcome.

Avoid ad hoc manual infrastructure changes that introduce unmanaged Terraform drift.

## 14. Disaster Recovery Testing

The project should include selected controlled failure exercises.

### Scenario 1: Application Failure

Stop the application service or task.

Measure detection, recovery and validation.

### Scenario 2: VPN Tunnel Failure

Interrupt one configured IPsec tunnel.

Observe route selection and connectivity recovery.

Do not claim seamless failover unless demonstrated.

### Scenario 3: Database Recovery

Restore the database from a known backup into a safe test destination.

Validate recovered data and application compatibility.

### Scenario 4: Failed Migration Cutover

Simulate or execute a controlled rollback after destination validation failure.

Verify that service and data are returned to an approved consistent state.

### Scenario 5: Infrastructure Configuration Error

Introduce a controlled, reversible test change where safe.

Use Terraform planning and state-aware recovery to restore the approved configuration.

No destructive tests should be performed against unprotected data.

## 15. Cost and Operational Trade-Offs

Resilience features introduce financial and operational costs.

Cost assessment must consider:

- Transit Gateway attachment charges.
- VPN connection charges.
- EC2 or ECS compute costs.
- Database hosting costs.
- Multi-AZ database costs where applicable.
- Backup retention and storage.
- CloudWatch logs and metrics.
- VPC endpoints.
- Data transfer and processing.

The lab will prioritise controls that provide measurable security or recovery value.

Higher-cost production resilience features may be documented as future enhancements rather than deployed unnecessarily.

## 16. Consequences

### Positive

- Clear security and operational boundaries.
- Structured approach to protecting migration data.
- Documented recovery and rollback expectations.
- Improved operational visibility.
- Repeatable validation and failure testing.
- Honest distinction between implemented and planned resilience.

### Negative

- Additional deployment and maintenance complexity.
- Monitoring and backup costs.
- Recovery procedures require periodic testing.
- Some single points of failure remain.
- Production-grade redundancy is outside the initial lab scope.

## 17. Implementation Status

**Completed**

- Created the AWS multi-account architecture.
- Deployed private Development subnets.
- Configured cross-account Transit Gateway connectivity.
- Provisioned AWS Site-to-Site VPN infrastructure.
- Configured restrictive default VPC security group.
- Enabled initial on-premises host firewall controls.
- Established protected S3 Terraform state storage.
- Deployed and validated source application and database services.
- Recorded source database baseline information.

**Pending**

- Establish IPsec tunnels.
- Verify effective routing and traffic restrictions.
- Deploy application-specific security groups.
- Deploy AWS migration destinations.
- Configure workload secrets management.
- Configure relevant CloudWatch monitoring and alarms.
- Implement destination database backups.
- Execute migration and rollback.
- Test selected recovery scenarios.
- Record actual RTO and RPO results.
- Complete operational handover documentation.

## 18. Acceptance Criteria

The security and recovery strategy will be considered validated when:

1. AWS account boundaries are verified.
2. Workload network access is restricted appropriately.
3. VPN encryption and connectivity are operational.
4. Application credentials are handled securely.
5. Relevant logs and monitoring are available.
6. Database backup restoration has been tested.
7. Application recovery procedures are demonstrated.
8. Migration rollback procedures are documented and tested.
9. Recovery measurements are recorded.
10. Known single points of failure and residual risks are documented.
11. Cost and operational implications are assessed.
12. The final architecture accurately reflects implemented capabilities.

## 19. References

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [AWS Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html)
- [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)
- [AWS Site-to-Site VPN](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
- [Terraform State](https://developer.hashicorp.com/terraform/language/state)
