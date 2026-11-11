
# =====================================================
# Project 3 - AWS PostgreSQL Migration Destination
# =====================================================

# Private RDS subnet group across two Availability Zones
resource "aws_db_subnet_group" "migration" {
  name       = "project3-migration-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name    = "project3-migration-db-subnets"
    Project = "Project3-HybridMigration"
  }
}

# Allow PostgreSQL access from on-premises over VPN
resource "aws_security_group" "migration_db" {
  name        = "project3-migration-postgresql-sg"
  description = "Private PostgreSQL migration access"
  vpc_id      = aws_vpc.development.id

  ingress {
    description = "PostgreSQL from on-premises network"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/24"]
  }

  ingress {
    description = "PostgreSQL from Development VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.30.0.0/16"]
  }

  tags = {
    Name    = "project3-migration-postgresql-sg"
    Project = "Project3-HybridMigration"
  }
}

# Private PostgreSQL 16 migration target
resource "aws_db_instance" "migration" {
  identifier = "project3-migration-postgresql"

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "migrationdb"
  username = "migrationadmin"

  # AWS manages the master password in Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.migration.name
  vpc_security_group_ids = [aws_security_group.migration_db.id]

  publicly_accessible = false
  multi_az            = false
  port                = 5432

  backup_retention_period = 7
  copy_tags_to_snapshot   = true

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "project3-migration-postgresql-final"

  auto_minor_version_upgrade = true

  tags = {
    Name        = "project3-migration-postgresql"
    Project     = "Project3-HybridMigration"
    Environment = "Development"
    Purpose     = "PostgreSQL-Migration"
  }
}

output "migration_rds_endpoint" {
  description = "Private PostgreSQL database endpoint"
  value       = aws_db_instance.migration.address
}

output "migration_rds_port" {
  description = "PostgreSQL listener port"
  value       = aws_db_instance.migration.port
}

output "migration_rds_secret_arn" {
  description = "ARN of the RDS-managed master credential secret"
  value       = aws_db_instance.migration.master_user_secret[0].secret_arn
}
