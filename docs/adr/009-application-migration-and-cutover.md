# ADR-009: Application Migration and Cutover Strategy

## Context

The project required migration of an existing Python Flask application from an on-premises VMware environment to AWS while preserving functionality, PostgreSQL connectivity and operational control.

The source application ran on Ubuntu 24.04 using Python 3.12, Gunicorn and systemd.

The migration needed to demonstrate a practical workload rehosting approach using private AWS infrastructure, with controlled cutover and rollback capabilities.

## Decision

**Rehost the Flask application on a private Amazon EC2 Ubuntu instance**, retaining the existing Python runtime, Gunicorn application server and systemd service management.

Use a database-first migration strategy, with PostgreSQL migrated to Amazon RDS before final application cutover.

The application is deployed in the Development VPC (`10.30.0.0/16`) without a public IP address or direct internet access.

Access is provided through AWS Site-to-Site VPN and Transit Gateway.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Amazon EC2 rehosting | Selected | Minimal application changes, straightforward migration and direct infrastructure control |
| Amazon ECS with Fargate | Rejected | Containerisation and additional service dependencies unnecessary for the migration objectives |
| AWS Elastic Beanstalk | Rejected | Less direct control over the underlying infrastructure |
| AWS Lambda with API Gateway | Rejected | Requires application refactoring beyond the intended rehosting scope |

## Implementation

The migrated application runs on a private Ubuntu 24.04 EC2 instance (`10.30.0.155`) with:

- Python 3.12 and an isolated virtual environment.
- Flask and Gunicorn managed through systemd.
- Offline Python dependency installation over the VPN.
- Dedicated application security group.
- SSH access restricted to the authorised on-premises application host.
- TLS-verified connections to private Amazon RDS PostgreSQL.
- Dedicated read-only PostgreSQL application credentials.
- Protected local environment configuration.

The migration followed a controlled sequence:

1. Deployed and validated the private EC2 application.
2. Connected the application to the initially migrated RDS database.
3. Stopped the on-premises application to establish a write-freeze window.
4. Restored the final PostgreSQL backup into `migrationdb_cutover`.
5. Updated the AWS application database configuration.
6. Restarted Gunicorn and validated database connectivity.

The original on-premises application and database were preserved for rollback.

## Operational Design

Gunicorn runs as a systemd service named `migration-app`, supporting service restart and automatic startup.

Application health and database connectivity are exposed through:

- `/health`
- `/db-health`
- `/customers`
- `/products`
- `/orders`

The application uses local service logs accessible through `journalctl`.

CloudWatch alarms monitor RDS CPU utilisation and free storage; centralised application logging and application-specific CloudWatch alarms are not implemented.

## Consequences

**Benefits**

- Minimal changes to the original application architecture.
- Private workload hosting without internet exposure.
- Controlled application and database cutover.
- Reusable Terraform-managed infrastructure.
- Practical demonstration of Linux administration and hybrid application migration.
- Preserved rollback options.

**Trade-offs**

- Operating system and application patching remain customer-managed.
- Single EC2 instance introduces an availability dependency.
- Offline deployment requires additional package management.
- Application secrets are stored in a protected local environment file.
- Automatic scaling and deployment pipelines are not implemented.

A containerised ECS deployment would provide a potential future replatforming option.

## Validation

- Flask application deployed successfully to private EC2.
- Gunicorn service operational under systemd.
- Application health and database-backed endpoints returned successful responses.
- On-premises connectivity to the AWS application verified over the VPN.
- Application connected successfully to the final RDS cutover database.
- Original on-premises environment retained for rollback.

Rollback procedures are documented, but a complete application rollback exercise was not performed.

## References

- [Amazon EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)
- [Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
- [AWS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)