terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region              = "eu-west-2"
  profile             = "project3-dev-terraform"
  allowed_account_ids = ["614084726927"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "development" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "project3-development-vpc"
    Project = "aws-enterprise-hybrid-migration"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id                  = aws_vpc.development.id
  cidr_block              = cidrsubnet(aws_vpc.development.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name    = "project3-private-${count.index + 1}"
    Project = "aws-enterprise-hybrid-migration"
  }
}

resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.development.id

  tags = {
    Name    = "project3-private-rt-${count.index + 1}"
    Project = "aws-enterprise-hybrid-migration"
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.development.id

  tags = {
    Name    = "project3-default-sg-restricted"
    Project = "aws-enterprise-hybrid-migration"
  }
}

output "development_vpc_id" {
  value = aws_vpc.development.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "availability_zones" {
  value = aws_subnet.private[*].availability_zone
}