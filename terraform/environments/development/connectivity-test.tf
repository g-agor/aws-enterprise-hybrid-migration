
# Project 3 — Private hybrid connectivity test
# Existing Development VPC: 10.30.0.0/16

data "aws_ami" "connectivity_test" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
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

resource "aws_security_group" "connectivity_test" {
  name        = "project3-hybrid-connectivity-test-sg"
  description = "Allow ICMP testing from on-premises network"
  vpc_id      = "vpc-077a298324f002a9f"

  ingress {
    description = "ICMP from on-premises LAN"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.10.0.0/24"]
  }

  tags = {
    Name    = "project3-hybrid-connectivity-test-sg"
    Project = "Project3-HybridMigration"
  }
}

resource "aws_instance" "connectivity_test" {
  ami                         = data.aws_ami.connectivity_test.id
  instance_type               = "t3.micro"
  subnet_id                   = "subnet-022aecfac36266cbf"
  vpc_security_group_ids      = [aws_security_group.connectivity_test.id]
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name    = "project3-hybrid-connectivity-test"
    Project = "Project3-HybridMigration"
    Purpose = "VPN-Connectivity-Validation"
  }
}

output "connectivity_test_private_ip" {
  description = "Private IP address for on-premises VPN testing"
  value       = aws_instance.connectivity_test.private_ip
}

output "connectivity_test_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.connectivity_test.id
}
