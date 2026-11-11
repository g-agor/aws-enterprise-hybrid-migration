
# =====================================================
# Project 3 - Private AWS Flask Application Server
# =====================================================

# Register the on-premises application's SSH public key
resource "aws_key_pair" "migration_app" {
  key_name   = "project3-migration-app-key"
  public_key = trimspace(file("${path.module}/project3-app.pub"))

  tags = {
    Project = "Project3-HybridMigration"
  }
}

# Ubuntu Server 24.04 LTS AMI
data "aws_ami" "migration_app" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for private application access
resource "aws_security_group" "migration_app" {
  name        = "project3-migration-app-sg"
  description = "Private Flask application access from on-premises"
  vpc_id      = aws_vpc.development.id

  ingress {
    description = "SSH from on-premises application server"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.10/32"]
  }

  ingress {
    description = "Flask application from on-premises"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/24"]
  }

  egress {
    description = "PostgreSQL access within Development VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.30.0.0/16"]
  }

  tags = {
    Name    = "project3-migration-app-sg"
    Project = "Project3-HybridMigration"
  }
}

# Private Ubuntu application server
resource "aws_instance" "migration_app" {
  ami           = data.aws_ami.migration_app.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private[0].id

  vpc_security_group_ids = [
    aws_security_group.migration_app.id
  ]

  key_name = aws_key_pair.migration_app.key_name

  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 16
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "project3-migration-app"
    Project     = "Project3-HybridMigration"
    Environment = "Development"
    Purpose     = "Application-Migration"
  }
}

output "migration_app_private_ip" {
  description = "Private IP of the AWS application server"
  value       = aws_instance.migration_app.private_ip
}

output "migration_app_instance_id" {
  description = "AWS application server instance ID"
  value       = aws_instance.migration_app.id
}
