
# ADR-009: Application Migration and Cutover Strategy

**Status:** Proposed  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## 1. Context

The project requires migration of an existing on-premises Python Flask application into a private AWS environment.

The application currently runs on a dedicated Ubuntu virtual machine within a physically separate VMware Fusion environment.

The objective is to demonstrate an enterprise-style workload migration covering discovery, dependency mapping, infrastructure preparation, application deployment, connectivity validation, cutover, rollback and operational handover.

The migration must preserve application functionality and database connectivity while minimising unnecessary downtime.

### 1.1 Existing Application Environment

| Component | Configuration |
|---|---|
| Operating system | Ubuntu 24.04 |
| Application framework | Python Flask |
| Application runtime | Python 3.12 |
| Application server | Gunicorn |
| Service manager | systemd |
| Service name | `migration-app` |
| Application IP | `10.10.0.10` |
| Database server | PostgreSQL 16 |
| Database IP | `10.10.0.20` |
| Database name | `migrationdb` |
| On-premises CIDR | `10.10.0.0/24` |
| AWS destination VPC | `10.30.0.0/16` |

The application exposes endpoints including:

- `/health`
- `/db-health`
- `/customers`
- `/products`
- `/orders`

These endpoints provide a useful foundation for functional and dependency validation.

### 1.2 Migration Requirements

The destination must:

- Run the existing application reliably.
- Preserve compatibility with the PostgreSQL database.
- Remain within private AWS networking.
- Support infrastructure provisioning through Terraform.
- Use controlled application and database security groups.
- Support application health checks and operational logging.
- Securely manage database credentials.
- Permit migration testing before production-style cutover.
- Support a documented rollback procedure.
- Provide measurable evidence of migration success.

## 2. Decision

The final application hosting platform remains under evaluation.

Two primary destinations will be assessed:

1. Amazon EC2 running Ubuntu, Python and Gunicorn.
2. Amazon ECS with AWS Fargate running a containerised Flask application.

The initial assessment will prioritise workload compatibility, migration complexity, operating cost and the ability to demonstrate a controlled migration.

A staged migration approach will be used:

1. Discover the existing application architecture.
2. Identify application and database dependencies.
3. Establish hybrid connectivity.
4. Prepare an AWS database destination.
5. Deploy the application into AWS.
6. Validate application functionality against the migrated database.
7. Execute controlled cutover.
8. Verify functionality and rollback readiness.

No final platform decision will be recorded as Accepted until the implementation approach is selected.

## 3. Alternatives Considered

### Option 1: Rehost on Amazon EC2

Deploy an Ubuntu EC2 instance in a private subnet and install the existing Python Flask and Gunicorn application.

**Advantages**

- Closely matches the existing on-premises operating environment.
- Minimises application changes.
- Demonstrates a traditional rehosting migration.
- Allows direct operating system and runtime administration.
- Supports straightforward troubleshooting and application comparison.

**Disadvantages**

- Requires operating system patching.
- Requires management of the application runtime and service.
- Additional configuration is required for scaling and availability.
- Instance-level monitoring, backup and recovery remain customer responsibilities.

**Assessment:** Strong candidate for an initial rehost migration.

### Option 2: Replatform to Amazon ECS with Fargate

Package the Flask application into a container image and run it as an ECS service using AWS Fargate.

**Advantages**

- Reduces direct operating system administration.
- Supports declarative application deployment.
- Integrates with Amazon ECR.
- Supports ECS service deployment and health monitoring.
- Can demonstrate containerisation and modernisation.
- Supports horizontal scaling when appropriately configured.

**Disadvantages**

- Requires containerisation of the existing application.
- Introduces ECS task definitions, services and IAM roles.
- Requires additional private network access to supporting AWS services.
- May require a load balancer or alternative access mechanism.
- Adds complexity compared with direct EC2 rehosting.

**Assessment:** Strong replatforming option, subject to cost and connectivity requirements.

### Option 3: AWS Elastic Beanstalk

Use a managed application platform supporting Python applications.

**Advantages**

- Simplifies application deployment.
- Integrates with AWS-managed infrastructure.
- Reduces some operational configuration.

**Disadvantages**

- Provides less direct exposure to the underlying infrastructure.
- Introduces platform-specific deployment conventions.
- Less suitable for demonstrating the selected infrastructure engineering objectives.

**Assessment:** Not preferred.

### Option 4: AWS Lambda and API Gateway

Refactor the application into a serverless architecture.

**Advantages**

- Managed compute and scaling.
- Reduced server administration.
- Potentially cost-efficient for intermittent request volume.

**Disadvantages**

- Requires application redesign.
- Database connection management must be reconsidered.
- Introduces additional architectural changes beyond the initial migration scope.
- Less appropriate for demonstrating a controlled rehost or replatform migration.

**Assessment:** Deferred as a possible future modernisation exercise.

## 4. Migration Strategy

The application migration will follow a phased approach.

### Phase 1: Application Discovery

Document:

- Operating system version.
- Python and Flask versions.
- Gunicorn configuration.
- systemd service configuration.
- Installed Python dependencies.
- Environment variables.
- Database connection requirements.
- Application ports.
- File system dependencies.
- Required outbound connectivity.
- Application logs.
- Authentication and security dependencies.

Capture the existing application configuration without committing secrets.

### Phase 2: Dependency Mapping

Identify communication between the application and its supporting infrastructure.

| Source | Destination | Purpose |
|---|---|---|
| Application VM | PostgreSQL VM | Database connectivity |
| Application clients | Flask application | HTTP requests |
| Application | Local operating system | Runtime, logging and service management |
| AWS migration destination | Required AWS services | Logging, secrets and deployment operations |

The database dependency must be assessed before cutover.

### Phase 3: Destination Infrastructure

After selecting the application platform:

1. Deploy the required compute infrastructure.
2. Select the appropriate private subnet or subnets.
3. Create dedicated security groups.
4. Configure application IAM permissions.
5. Provide secure access to database credentials.
6. Configure operational logging.
7. Configure health monitoring.
8. Establish database connectivity.
9. Document the deployment and recovery procedure.

Infrastructure should be managed through Terraform wherever practical.

### Phase 4: Application Deployment

For EC2:

1. Provision the instance.
2. Install the required Python runtime.
3. Install application dependencies.
4. Deploy the Flask application.
5. Configure Gunicorn.
6. Configure the systemd service.
7. Configure application environment variables securely.
8. Start the application.
9. Validate local and network connectivity.

For ECS Fargate:

1. Create the application container image.
2. Test the container locally.
3. Publish the image to Amazon ECR.
4. Create the ECS task definition.
5. Configure task execution and application IAM roles.
6. Configure environment variables and secrets.
7. Create the ECS service.
8. Configure networking and required endpoints.
9. Verify task health and application responses.

## 5. Database Dependency Strategy

The application relies on the PostgreSQL `migrationdb` database.

The migration must preserve connectivity to the required database throughout testing and cutover.

Two approaches may be considered.

### Database-First Migration

Migrate PostgreSQL before switching the application to AWS.

**Advantages**

- Allows database validation before application cutover.
- Reduces the number of simultaneous changes during application migration.

**Disadvantages**

- The on-premises application may temporarily connect to an AWS-hosted database over the VPN.
- Hybrid latency and network availability may affect application performance.

### Application-First Migration

Deploy the application into AWS while initially retaining the on-premises database.

**Advantages**

- Allows early validation of the AWS application runtime.
- Separates application hosting changes from database migration.

**Disadvantages**

- Database traffic traverses the hybrid network.
- Temporary dependency on the VPN may affect performance and availability.

### Proposed Approach

Deploy and test the AWS application independently, prepare the AWS database destination, then perform a coordinated migration and cutover.

The exact sequence will be selected after testing latency, database compatibility and migration tooling.

## 6. Network and Security Design

The Development VPC uses:

`10.30.0.0/16`

Application infrastructure will be deployed into private subnets.

No public IPv4 address is required for the initial private migration target.

Network access will be controlled through:

- Dedicated application security groups.
- Dedicated database security groups.
- Transit Gateway routing.
- Site-to-Site VPN connectivity.
- Workload-specific IAM roles.
- Controlled access to supporting AWS services.

Administrative access should avoid exposing SSH directly to the internet.

AWS Systems Manager will be evaluated for EC2 administration if the selected architecture supports it.

Database credentials must not be embedded in application images, Terraform files or GitHub repositories.

## 7. Application Cutover Strategy

Cutover will be performed only after the AWS application and database destinations have passed validation.

### Pre-Cutover Checks

1. Confirm the AWS application is healthy.
2. Confirm database connectivity.
3. Verify data migration consistency.
4. Confirm network routes and security rules.
5. Verify logging and monitoring.
6. Confirm rollback procedures.
7. Record the source application state.
8. Establish a controlled cutover window.

### Cutover Execution

1. Stop or restrict application writes where required.
2. Complete final database synchronisation.
3. Confirm source and destination consistency.
4. Activate the AWS application destination.
5. Update the selected client access mechanism.
6. Execute application health checks.
7. Validate database-backed endpoints.
8. Monitor application errors and response times.
9. Record the cutover outcome.

The client access mechanism may involve an internal DNS record, load balancer or another controlled endpoint.

The final method must be selected and documented before cutover.

### Post-Cutover Validation

Verify:

- `/health`
- `/db-health`
- `/customers`
- `/products`
- `/orders`

Validate representative database reads and authorised writes.

Review application logs, database logs and network connectivity.

## 8. Rollback Strategy

The original on-premises application will be preserved during initial cutover validation.

Rollback conditions include:

- Application health-check failures.
- Database connectivity failures.
- Data inconsistency.
- Unexpected application errors.
- Unacceptable performance.
- Security or operational issues.

### Rollback Procedure

1. Declare the cutover unsuccessful.
2. Restrict writes to avoid divergent database state.
3. Determine whether the AWS destination accepted new transactions.
4. Reconcile any destination-only data.
5. Restore the approved database source.
6. Restore client access to the on-premises application.
7. Validate application and database functionality.
8. Record the incident and recovery outcome.

Rollback must account for database consistency.

Repointing clients to the original application is not sufficient if the destination database contains transactions absent from the source.

## 9. Monitoring and Operational Readiness

The AWS application destination should provide:

- Application health monitoring.
- Runtime or container logs.
- Application error visibility.
- Compute resource monitoring.
- Database connectivity monitoring.
- Deployment failure detection.
- Appropriate CloudWatch alarms.
- Documented restart and recovery procedures.

Operational evidence should demonstrate that the application can be supported after migration.

## 10. Performance Validation

Record baseline metrics from the on-premises application before migration.

Suggested measurements include:

- HTTP response times.
- Application startup time.
- Database query latency.
- Error rates.
- CPU and memory utilisation.
- Application availability.
- Time to recover from failure.

Compare equivalent workloads after migration.

Performance conclusions must be based on measured evidence rather than assumed AWS performance improvements.

## 11. Cost Considerations

The hosting decision must consider:

- EC2 instance charges.
- EBS storage.
- ECS Fargate compute charges where applicable.
- ECR storage.
- Load balancing charges if required.
- CloudWatch logging and monitoring.
- VPC endpoint charges.
- Database hosting charges.
- Transit Gateway and VPN charges.

A small intermittent lab may favour a different cost profile from a continuously running production service.

A cost estimate should be prepared before deploying application hosting resources.

## 12. Consequences

### Positive

- Structured migration process.
- Clear separation of deployment and cutover activities.
- Repeatable application testing.
- Opportunity to compare rehosting and replatforming.
- Documented security and operational requirements.
- Preserved rollback options during validation.

### Negative

- Additional infrastructure and operational complexity.
- Temporary dependencies across hybrid connectivity.
- Potential application configuration changes.
- Risk of database divergence following cutover.
- Additional costs for hosting, monitoring and supporting services.

## 13. Implementation Status

**Completed**

- Deployed the on-premises Flask application.
- Configured Gunicorn and systemd.
- Verified application and database health endpoints.
- Deployed the AWS Development VPC.
- Created private subnets across two Availability Zones.
- Configured AWS-side hybrid routing.
- Established the cross-account Transit Gateway attachment.

**Pending**

- Establish working IPsec connectivity.
- Select AWS application hosting platform.
- Select the destination database platform.
- Deploy destination application infrastructure.
- Configure application security groups.
- Deploy and test the application.
- Execute database migration.
- Complete cutover and rollback testing.
- Capture performance and operational evidence.

## 14. Acceptance Criteria

The migration will be considered successful when:

1. The application runs in the selected AWS environment.
2. Health-check endpoints respond correctly.
3. Database-backed endpoints return expected results.
4. Application data integrity is preserved.
5. Security controls restrict access to approved sources.
6. Application logs and metrics are available.
7. The cutover procedure has been executed and recorded.
8. Rollback has been tested or limitations explicitly documented.
9. Operational documentation is complete.
10. Migration cost and performance outcomes are recorded.

## 15. References

- [Amazon EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)
- [Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
- [AWS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Amazon ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
- [AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html)
- [AWS CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)
