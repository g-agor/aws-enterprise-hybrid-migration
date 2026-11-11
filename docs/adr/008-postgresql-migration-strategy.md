# ADR-008: PostgreSQL Database Migration Strategy

## Context

The project required migration of an on-premises PostgreSQL 16 database running on VMware to AWS, while preserving application compatibility, data integrity and a recovery path.

The source database, `migrationdb`, contained four application tables totalling **16,100 records** and approximately 9.4 MB of data.

The migration required private hybrid connectivity, controlled application cutover and a cost-effective destination platform.

## Decision

Use **native PostgreSQL `pg_dump` and `pg_restore`** to migrate the database to **Amazon RDS for PostgreSQL 16**, hosted in private subnets in the Development VPC.

The migration uses AWS Site-to-Site VPN and Transit Gateway connectivity between the on-premises PostgreSQL server (`10.10.0.20`) and the private RDS instance.

The selected approach provides a straightforward, repeatable migration method without requiring additional replication infrastructure.

A controlled application write freeze is used for final cutover rather than continuous change data capture (CDC).

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Native PostgreSQL backup and restore | Selected | Appropriate for a small database, low complexity and minimal additional AWS cost |
| AWS Database Migration Service | Rejected | Full-load and CDC capabilities were unnecessary for the dataset and acceptable cutover model |
| PostgreSQL logical replication | Rejected | Additional replication management was not justified by the workload |
| Self-managed PostgreSQL on EC2 | Rejected | Greater administration, patching and backup responsibility than managed RDS |

Amazon RDS was selected for managed database operations, automated backups, encryption and integration with AWS monitoring services.

## Implementation

The migration was executed in two stages.

**Initial migration**

1. Created a custom-format PostgreSQL backup using `pg_dump`.
2. Restored the database to Amazon RDS using `pg_restore`.
3. Compared source and destination row counts and deterministic MD5 checksums.
4. Deployed the Flask application to private EC2.
5. Configured TLS-verified PostgreSQL connectivity and a dedicated read-only application role.

**Final cutover**

1. Stopped the on-premises Flask application to prevent further application writes.
2. Created a final source database backup.
3. Restored the backup into a separate RDS database, `migrationdb_cutover`.
4. Granted the application role read-only access.
5. Switched the AWS Flask application to the cutover database.
6. Restarted Gunicorn and validated database connectivity.

The original on-premises database and the earlier AWS `migrationdb` database were retained as recovery options.

## Data Integrity and Validation

The initial migration produced matching source and destination record counts.

| Table | Records |
|---|---:|
| customers | 1,000 |
| products | 100 |
| orders | 5,000 |
| order_items | 10,000 |
| **Total** | **16,100** |

Four source-to-destination MD5 checksum comparisons also matched, providing additional evidence of data consistency.

The final cutover database was restored successfully, and the migrated Flask application established a healthy connection to it.

Application endpoints were tested against the AWS environment.

The final cutover database was not subjected to a separate full checksum comparison, and write-operation testing was outside the scope of the read-only application implementation.

## Recovery Strategy

The migration retains three database copies:

- **On-premises `migrationdb`:** Original source database.
- **AWS `migrationdb`:** Earlier validated migration.
- **AWS `migrationdb_cutover`:** Final application database.

Application rollback can be performed by changing the database connection configuration or restoring the original on-premises service.

RDS automated backups are configured with seven-day retention, and a manual post-cutover snapshot was requested.

Rollback procedures are documented but were not exercised as a complete end-to-end recovery test.

Any writes introduced after cutover would require reconciliation before reverting to an older database.

## Consequences

**Benefits**

- Cost-effective migration without AWS DMS infrastructure.
- Private database transfer over encrypted hybrid connectivity.
- Managed PostgreSQL operations through Amazon RDS.
- Verified initial data integrity.
- Controlled cutover with preserved recovery copies.
- Straightforward migration and troubleshooting process.

**Trade-offs**

- Requires a controlled write freeze for final synchronisation.
- No continuous replication or CDC.
- Less suitable for large databases requiring minimal downtime.
- Recovery to an older database may require data reconciliation.
- Single-AZ RDS does not provide automatic database failover.

For larger enterprise migrations with strict downtime requirements, AWS DMS with CDC or PostgreSQL logical replication would warrant further consideration.

## References

- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [PostgreSQL Backup and Restore](https://www.postgresql.org/docs/16/backup.html)
- [AWS Database Migration Service](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html)
- [PostgreSQL Logical Replication](https://www.postgresql.org/docs/16/logical-replication.html)