
# Project 3 — Migration, Cutover and Recovery Runbook

## 1. Purpose

Document the migration of a VMware-hosted Flask/PostgreSQL
application to private AWS EC2 and Amazon RDS in eu-west-2.

This runbook describes the implemented migration process,
rollback procedures, recovery options and known limitations.

## 2. Infrastructure

| Component | Location |
|---|---|
| Source application | onprem-ubu01 — 10.10.0.10 |
| Source PostgreSQL | onprem-db01 — 10.10.0.20 |
| VPN gateway | onprem-vpn01 — 10.10.0.2 |
| AWS application | EC2 — 10.30.0.155 |
| AWS RDS | project3-migration-postgresql |
| Active database | migrationdb_cutover |
| Previous AWS database | migrationdb |

The on-premises network communicates with AWS through
strongSwan, AWS Site-to-Site VPN and Transit Gateway.

## 3. Migration Procedure

1. Establish private connectivity between on-premises and AWS.
2. Provision Amazon RDS PostgreSQL 16.
3. Create a PostgreSQL custom-format source backup.
4. Restore the initial database to RDS.
5. Validate source and destination data.
6. Deploy the Flask application to private EC2.
7. Configure TLS and a restricted PostgreSQL application role.
8. Stop the source Flask service to begin final cutover.
9. Create the final source PostgreSQL backup.
10. Restore it into migrationdb_cutover.
11. Grant the application role read-only database access.
12. Update the AWS application DB_NAME configuration.
13. Restart the AWS application service.
14. Validate database health and application availability.

The initial migration contained 16,100 records and was
validated with matching row counts and MD5 checksums.

## 4. AWS Application Operations

Connect from an authorised on-premises host:

    ssh -i ~/.ssh/project3-aws-app ubuntu@10.30.0.155

Application directory:

    /home/ubuntu/migration-app

Check application status:

    sudo systemctl status migration-app --no-pager

Restart application:

    sudo systemctl restart migration-app

Review application logs:

    sudo journalctl -u migration-app -n 50 --no-pager

The application configuration is stored in a protected
.env file and must never be committed to Git.

## 5. Rollback to Previous AWS Database

Use only after confirming the target database contains
an acceptable recovery point.

1. Stop or isolate application traffic if writes are enabled.
2. Edit /home/ubuntu/migration-app/.env.
3. Change DB_NAME from migrationdb_cutover to migrationdb.
4. Restart the AWS application:

    sudo systemctl restart migration-app

5. Validate application connectivity.

WARNING: The previous database may contain older data.

This procedure is a configuration rollback, not a
synchronisation of changes made after cutover.

## 6. Rollback to On-Premises

1. Stop or redirect traffic away from the AWS application.
2. Establish the appropriate source data recovery point.
3. Confirm whether AWS-side writes require reconciliation.
4. On onprem-ubu01, start the original application:

    sudo systemctl start migration-app

5. Direct users or clients to the on-premises application.

The source PostgreSQL database was preserved during migration.

WARNING: Never assume the source database contains recent
AWS-side writes. Reconciliation may be necessary.

## 7. VPN Recovery

Two AWS VPN tunnels have been configured and independently
tested using strongSwan.

Manual failover was demonstrated.

On the VPN gateway, the available connections are:

    aws-tunnel1
    aws-tunnel2

To switch manually from tunnel 1 to tunnel 2:

    sudo ipsec down aws-tunnel1
    sudo ipsec up aws-tunnel2

Restore the primary tunnel:

    sudo ipsec down aws-tunnel2
    sudo ipsec up aws-tunnel1

Automatic failover is not implemented.

## 8. Database Backup and Recovery

RDS automated backup retention: 7 days.

Manual post-cutover snapshot:

    project3-post-cutover-snapshot

The snapshot request was submitted through AWS CLI.

Before using it for recovery, confirm that its status is
available.

To restore a manual RDS snapshot, use the AWS RDS
restore-db-instance-from-db-snapshot operation.

Restoring creates a separate RDS instance. It does not
overwrite the existing instance.

Following restoration, update networking, database
credentials and application configuration as required.

A complete snapshot restore has not been tested in this lab.

## 9. Monitoring

CloudWatch alarms:

- project3-rds-high-cpu
  CPU utilisation above 80% for 10 minutes.

- project3-rds-low-storage
  Free storage below 5 GiB for 5 minutes.

SNS notifications have not been configured.

## 10. Security Requirements

- Keep application and database resources private.
- Restrict SSH access to authorised on-premises hosts.
- Never commit database passwords or private SSH keys.
- Use TLS verification for PostgreSQL connections.
- Use a restricted database account for the application.
- Protect Terraform state and infrastructure credentials.
- Keep recovery copies separate from active workloads.

## 11. Known Limitations

- Manual rather than automatic VPN failover.
- Single EC2 application instance.
- Single-AZ RDS deployment.
- Database snapshot restoration not yet exercised.
- No centralised application log aggregation.
- No SNS notification delivery for CloudWatch alarms.
- Application database password stored in a local
  protected environment file.

## 12. Outcome

Successfully deployed a private AWS application and migrated
the PostgreSQL workload from an independent VMware environment.

Demonstrated hybrid networking, private workload hosting,
database migration, application cutover, manual VPN failover,
backup configuration and operational monitoring.
