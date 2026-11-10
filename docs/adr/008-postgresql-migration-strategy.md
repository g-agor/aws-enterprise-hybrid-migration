
# ADR-008: PostgreSQL Database Migration Strategy

**Status:** Proposed  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## 1. Context

The project requires migration of an existing PostgreSQL database from a physically separate on-premises VMware environment into AWS.

The migration must demonstrate an enterprise-style process covering discovery, assessment, migration execution, data integrity, cutover, validation and rollback.

The source database supports a Python Flask application and must retain its data, schema and application compatibility following migration.

### 1.1 Source Environment

| Component | Configuration |
|---|---|
| Database server | Ubuntu 24.04 VM |
| PostgreSQL version | PostgreSQL 16 |
| Source IP | `10.10.0.20` |
| Database | `migrationdb` |
| Application | Python Flask / Gunicorn |
| Application server IP | `10.10.0.10` |
| On-premises LAN | `10.10.0.0/24` |
| AWS destination network | `10.30.0.0/16` |
| Connectivity | AWS Site-to-Site VPN via Transit Gateway |

The source database contains four application tables.

### 1.2 Source Data Baseline

| Table | Row Count |
|---|---:|
| customers | 1,000 |
| products | 100 |
| orders | 5,000 |
| order_items | 10,000 |
| **Total** | **16,100** |

Recorded initial database size: approximately 9.4 MB.

The database is intentionally small, allowing migration approaches to be compared without requiring extensive production-scale infrastructure.

### 1.3 Migration Requirements

The migration must:

- Preserve application data and relational integrity.
- Minimise unnecessary application downtime.
- Use private hybrid connectivity where applicable.
- Avoid exposing PostgreSQL publicly.
- Support repeatable validation.
- Provide a documented rollback mechanism.
- Demonstrate realistic migration tooling and operational decisions.
- Control AWS resource costs.

## 2. Decision

The final migration implementation remains under evaluation.

The project will assess:

1. PostgreSQL native backup and restore.
2. AWS Database Migration Service (AWS DMS).
3. PostgreSQL logical replication.

The selected approach will be based on migration complexity, downtime requirements, learning objectives and cost.

The destination database platform must also be selected before implementation.

Potential destinations include:

- Amazon RDS for PostgreSQL.
- Self-managed PostgreSQL on a private Amazon EC2 instance.

The preferred evaluation approach is to assess AWS DMS for demonstrating enterprise migration capabilities while retaining native PostgreSQL tools as a reliable baseline and recovery mechanism.

No final migration method or destination has yet been approved.

## 3. Alternatives Considered

### Option 1: Native PostgreSQL Backup and Restore

Use PostgreSQL utilities such as `pg_dump`, `pg_restore` and `psql` to transfer the database into the destination environment.

**Advantages**

- Straightforward for small databases.
- Supported by native PostgreSQL tooling.
- No dedicated AWS migration service required.
- Relatively low operational complexity.
- Provides a portable logical backup.
- Suitable for initial migration validation and rollback preparation.

**Disadvantages**

- Typically requires a controlled write freeze for a consistent final cutover.
- Does not continuously replicate subsequent source changes.
- Migration downtime increases with database size and restore duration.
- Requires separate planning for users, roles, extensions and database-level objects.

**Assessment:** Strong baseline option for the existing small dataset.

### Option 2: AWS Database Migration Service

Use AWS DMS to migrate supported database objects and data from on-premises PostgreSQL to an AWS destination.

Evaluate full-load migration and, where supported, ongoing change data capture (CDC).

**Advantages**

- Purpose-built AWS database migration tooling.
- Supports full-load migration.
- Supports ongoing replication through CDC for compatible configurations.
- Provides migration task monitoring and progress metrics.
- Useful for reducing cutover downtime.
- Demonstrates enterprise-relevant AWS migration capabilities.

**Disadvantages**

- Additional AWS resource and operational costs.
- Requires source and target endpoint configuration.
- PostgreSQL CDC may require logical replication settings and appropriate permissions.
- Network access must be available between DMS and database endpoints.
- DMS does not replace all schema, role and extension migration tasks.
- More configuration complexity than a simple native dump and restore.

**Assessment:** Preferred candidate for demonstrating an enterprise migration process, subject to compatibility and cost assessment.

### Option 3: PostgreSQL Logical Replication

Configure PostgreSQL native logical replication between compatible source and destination systems.

**Advantages**

- Supports ongoing replication of selected database tables.
- Can reduce cutover downtime.
- Does not require a separate managed migration service.
- Demonstrates native PostgreSQL replication concepts.

**Disadvantages**

- Requires additional PostgreSQL replication configuration.
- Schema changes and some database objects require separate management.
- Sequences and other database state require particular attention.
- Replication monitoring and failover procedures must be implemented.
- Cutover and rollback remain operational responsibilities.

**Assessment:** Useful alternative for deeper database engineering experience.

## 4. Destination Database Platform

### 4.1 Amazon RDS for PostgreSQL

**Advantages**

- Managed database operations.
- Automated backup capabilities.
- Integration with AWS monitoring and security services.
- Supports managed availability and recovery features depending on configuration.

**Disadvantages**

- Ongoing database instance and storage charges.
- Less operating system and database host control.
- Certain PostgreSQL administrative operations are restricted.
- Private network access must be configured appropriately.

### 4.2 Self-Managed PostgreSQL on EC2

**Advantages**

- Direct control over PostgreSQL and the operating system.
- Familiar administration model based on the on-premises source.
- Supports detailed migration and troubleshooting demonstrations.

**Disadvantages**

- Customer-managed patching, backups and recovery.
- Additional database operational responsibility.
- High availability must be designed separately.

### 4.3 Decision Status

The database destination will be selected after evaluating:

- Migration learning objectives.
- Compatibility requirements.
- Operational ownership.
- AWS infrastructure cost.
- Backup and recovery requirements.
- Required level of managed service adoption.

The decision and rationale will be recorded before migration execution.

## 5. Proposed Migration Workflow

### Phase 1: Discovery and Assessment

Identify:

- PostgreSQL version.
- Database size and table counts.
- Schema definitions and relationships.
- Constraints and indexes.
- Extensions and dependencies.
- Database roles and permissions.
- Application connection configuration.
- Source database write activity.

Record baseline metrics before changing the source.

### Phase 2: Destination Preparation

1. Select the AWS database platform.
2. Deploy the database into a private network.
3. Create workload-specific security groups.
4. Configure database authentication and encryption.
5. Establish a supported network path.
6. Verify source-to-destination connectivity.
7. Prepare schema, roles and required extensions.

### Phase 3: Migration Execution

For native PostgreSQL migration:

1. Create a consistent logical backup.
2. Securely transfer the backup.
3. Restore the database.
4. Reconcile roles and database objects.
5. Validate the restored schema and data.

For AWS DMS:

1. Verify source PostgreSQL prerequisites.
2. Configure source and destination endpoints.
3. Deploy the required DMS migration resources.
4. Configure migration and, if applicable, CDC tasks.
5. Execute the initial load.
6. Monitor migration progress and replication latency.
7. Validate database consistency.

### Phase 4: Cutover

1. Announce the planned migration window.
2. Restrict or pause application writes.
3. Complete the final data synchronisation.
4. Verify source and destination consistency.
5. Update application database configuration.
6. Restart or redeploy application components as required.
7. Execute application smoke tests.
8. Record cutover timing and outcomes.

### Phase 5: Post-Migration Validation

Validate:

- Database availability.
- Schema compatibility.
- Table row counts.
- Primary and foreign key relationships.
- Data integrity.
- Application read operations.
- Application write operations.
- Error logs and database performance.

## 6. Data Integrity Validation

The source database provides a baseline of 16,100 application records.

Migration validation must compare source and destination data after establishing a consistent comparison point.

### 6.1 Row Counts

Expected initial source counts:

| Table | Expected Rows |
|---|---:|
| customers | 1,000 |
| products | 100 |
| orders | 5,000 |
| order_items | 10,000 |

These counts represent the initial baseline and must be refreshed if the source data changes.

### 6.2 Referential Integrity

Verify:

- Orders reference valid customers.
- Order items reference valid orders.
- Order items reference valid products.
- Primary key uniqueness is preserved.
- Foreign key constraints remain valid.

### 6.3 Checksums

Use deterministic, reproducible data comparison methods.

The original source dataset has recorded reference checksums:

| Table | Baseline MD5 |
|---|---|
| customers | `ed20d2fc49fc244ecd2f084119a982ed` |
| products | `dbd5ccd073e5090f97ae531a68b16add` |
| orders | `b3324b428f890f96a2bc21c484b0eedc` |
| order_items | `8cc16ab04988d84a18dbc3d421d1cc43` |

These checksums are only comparable if the same deterministic canonicalisation, row ordering and hashing process is used.

The original checksum calculation procedure must be verified before treating matching MD5 values as migration evidence.

Row counts alone are insufficient to prove data integrity.

## 7. Downtime and Cutover Strategy

For a small database, native backup and restore may provide an acceptable downtime window.

For larger or frequently updated databases, CDC may reduce the interruption required at cutover.

The project will measure:

- Initial migration duration.
- Final synchronisation duration.
- Application write-freeze duration.
- Database connection switch time.
- Application recovery time.
- Post-cutover validation duration.

No downtime target will be claimed before testing.

## 8. Rollback Strategy

The on-premises PostgreSQL database will be retained during initial migration validation.

If cutover fails:

1. Stop application writes to the AWS destination.
2. Assess whether any writes were accepted after cutover.
3. Prevent simultaneous writes to source and destination.
4. Restore application connectivity to the approved source database.
5. Validate application functionality.
6. Reconcile any destination-only transactions before declaring rollback successful.

Switching the connection string back to the original database is not sufficient if new transactions have already been committed to the AWS destination.

Data reconciliation and the chosen recovery point must be explicitly documented.

## 9. Security Considerations

- Restrict database access to authorised private networks and security groups.
- Do not expose PostgreSQL directly to the public internet.
- Use encrypted transport when required by the security design.
- Store database credentials securely.
- Apply least-privilege permissions to migration identities.
- Protect backup files and migration artifacts.
- Avoid including database passwords in GitHub or documentation.
- Monitor database and migration activity.

## 10. Cost Considerations

The database migration assessment should include:

- Destination compute or RDS charges.
- Database storage and backup charges.
- AWS DMS resource charges if selected.
- Required VPC endpoints or other connectivity costs.
- Transit Gateway data processing.
- Site-to-Site VPN charges.
- Data transfer costs where applicable.

Given the small source dataset, operational complexity and fixed service charges may be more significant than the actual data-transfer volume.

A cost estimate must be prepared before deploying migration-specific paid resources.

## 11. Consequences

### Positive

- Structured evaluation of migration alternatives.
- Evidence-based platform and tooling selection.
- Repeatable database integrity testing.
- Explicit cutover and rollback planning.
- Opportunity to demonstrate AWS-native migration capabilities.

### Negative

- Additional migration tooling may increase cost.
- CDC requires additional source database preparation.
- Hybrid connectivity introduces networking dependencies.
- Database consistency must be managed during cutover.
- Rollback becomes more complex after destination writes begin.

## 12. Implementation Status

**Completed**

- Provisioned on-premises PostgreSQL 16 database.
- Created and populated application tables.
- Established initial row-count baseline.
- Recorded reference checksums.
- Deployed AWS network infrastructure.
- Created the Development VPC and private subnets.

**Pending**

- Establish IPsec hybrid connectivity.
- Select the destination database platform.
- Select and approve the migration method.
- Deploy the destination database.
- Complete source compatibility assessment.
- Prepare migration-specific credentials and security rules.
- Execute test migration.
- Validate data integrity.
- Perform application cutover and rollback testing.
- Record measured migration performance and downtime.

## 13. Acceptance Criteria

The database migration will be considered successful when:

1. The destination database is operational.
2. Required schemas and database objects are present.
3. All intended application records have been migrated.
4. Referential integrity is preserved.
5. The Flask application connects successfully to the destination.
6. Application read and write operations pass validation.
7. Actual cutover downtime is recorded.
8. Rollback has been tested or its limitations explicitly documented.
9. Migration costs and operational implications are documented.

## 14. References

- [AWS Database Migration Service](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html)
- [AWS DMS PostgreSQL Source](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html)
- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [PostgreSQL Backup and Restore](https://www.postgresql.org/docs/16/backup.html)
- [PostgreSQL Logical Replication](https://www.postgresql.org/docs/16/logical-replication.html)
