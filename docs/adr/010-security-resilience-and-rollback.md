# ADR-010: Security, Resilience and Rollback Strategy

## Context

The hybrid migration architecture spans an on-premises VMware environment and multiple AWS accounts. It requires protection of application and database workloads, secure connectivity, operational monitoring and a recoverable migration process.

As a controlled proof-of-concept rather than a production service, the design prioritises practical security controls and cost-effective recovery mechanisms over full infrastructure redundancy.

## Decision

Adopt a **risk-based, layered security and resilience strategy** combining private networking, restricted access, encryption, database backups, monitoring and documented rollback procedures.

Implement controls appropriate to the workload while explicitly recognising single points of failure and recovery limitations.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Basic infrastructure security only | Rejected | Insufficient monitoring and recovery capability |
| Fully redundant multi-AZ/multi-Region architecture | Rejected | Disproportionate cost and complexity for the lab |
| Risk-based security and resilience | Selected | Balances security, recoverability, operational learning and cost |

## Implemented Security Controls

The architecture includes:

- **Account separation:** Management, Network and Development responsibilities.
- **Private networking:** EC2 and RDS deployed without public exposure.
- **Access restrictions:** Dedicated security groups and SSH key authentication.
- **Hybrid encryption:** IKEv2/IPsec connectivity through AWS Site-to-Site VPN.
- **Data encryption:** Encrypted EBS and RDS storage, TLS-verified PostgreSQL connections and encrypted Terraform state.
- **Identity management:** Temporary AWS credentials and account-restricted Terraform providers.
- **Database least privilege:** Dedicated read-only PostgreSQL application role.
- **Secrets:** RDS administrator credentials managed through AWS Secrets Manager; application credentials stored in a protected local environment file.

The implementation uses administrative deployment permissions for infrastructure management rather than fully scoped production deployment roles.

## Resilience and Monitoring

| Component | Implemented capability |
|---|---|
| VPN | Two independently tested tunnels with manual failover |
| Application | Gunicorn managed by systemd with automatic service restart |
| Database | RDS PostgreSQL with seven-day automated backup retention |
| Recovery | Final source backup, preserved database copies and manual RDS snapshot requested |
| Monitoring | CloudWatch RDS CPU and free-storage alarms |
| Infrastructure | Version-controlled Terraform with remote-state locking and S3 versioning |

The manual RDS snapshot must reach `available` status before being treated as a completed recovery point.

CloudWatch alarms have no SNS notification actions, and centralised application logging has not been implemented.

## Migration Cutover and Rollback

The database-first migration retained the original on-premises application and database while deploying the AWS workload.

The final cutover involved:

1. Stopping the on-premises Flask service.
2. Creating a final PostgreSQL backup.
3. Restoring the database into `migrationdb_cutover` on Amazon RDS.
4. Updating the AWS application's database configuration.
5. Restarting Gunicorn and validating connectivity.

The previous AWS database and original on-premises environment remain available as rollback options.

Rollback is documented in the [Migration and Recovery Runbook](../migration/migration-runbook.md).

A complete rollback exercise has not been performed. Any destination-side writes following cutover would require reconciliation before reverting to an older database.

## Consequences

**Benefits**

- Reduced public attack surface.
- Layered network, identity and database controls.
- Preserved migration recovery points.
- Operational monitoring and service recovery mechanisms.
- Cost-conscious implementation of security and resilience.

**Trade-offs**

- Manual VPN tunnel failover.
- Single EC2 application instance and Single-AZ RDS.
- No measured recovery time or recovery point objectives.
- Database snapshot restoration not exercised.
- Application secrets remain locally stored.
- Limited centralised logging and alert notification capabilities.

These limitations are documented rather than represented as production-grade high availability or disaster recovery.

## Validation

- Private hybrid connectivity and both VPN tunnels tested.
- Restricted EC2 and RDS access used during migration.
- TLS-secured application-to-database connectivity verified.
- Initial PostgreSQL data integrity validated using row counts and checksums.
- Final application cutover completed successfully.
- CloudWatch RDS alarms configured.
- Backup and rollback procedures documented.

## References

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [AWS Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)