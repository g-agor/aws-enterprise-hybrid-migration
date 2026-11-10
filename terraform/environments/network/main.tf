
terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region              = "eu-west-2"
  profile             = "project3-network-terraform"
  allowed_account_ids = ["077542728634"]

  default_tags {
    tags = {
      Project     = "project3-hybrid-migration"
      Environment = "network"
      ManagedBy   = "Terraform"
    }
  }
}

# Central Transit Gateway
resource "aws_ec2_transit_gateway" "hybrid" {
  description = "Project 3 enterprise hybrid connectivity"

  amazon_side_asn = 64512

  dns_support = "enable"

  auto_accept_shared_attachments = "disable"

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  vpn_ecmp_support = "enable"

  tags = {
    Name = "project3-hybrid-tgw"
  }
}

# Share the Transit Gateway with the Development account
resource "aws_ram_resource_share" "tgw" {
  name                      = "project3-tgw-share"
  allow_external_principals = false

  tags = {
    Name = "project3-tgw-share"
  }
}

resource "aws_ram_resource_association" "tgw" {
  resource_share_arn = aws_ram_resource_share.tgw.arn
  resource_arn       = aws_ec2_transit_gateway.hybrid.arn
}

resource "aws_ram_principal_association" "development" {
  resource_share_arn = aws_ram_resource_share.tgw.arn
  principal          = "614084726927"
}

output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.hybrid.id
}

output "transit_gateway_arn" {
  value = aws_ec2_transit_gateway.hybrid.arn
}

output "ram_share_arn" {
  value = aws_ram_resource_share.tgw.arn
}
