
# Transit Gateway ID supplied by the Network environment
variable "transit_gateway_id" {
  description = "Project 3 Transit Gateway ID in the Network account"
  type        = string

  validation {
    condition     = can(regex("^tgw-[0-9a-f]+$", var.transit_gateway_id))
    error_message = "Provide a valid Transit Gateway ID."
  }
}


# Development VPC attachment to shared Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "development" {
  transit_gateway_id = var.transit_gateway_id

  vpc_id     = aws_vpc.development.id
  subnet_ids = aws_subnet.private[*].id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  # The TGW belongs to the Network account.
  # Route table associations and propagation are managed there.
  # Ignore unsupported drift detection on the RAM-shared TGW.
  lifecycle {
    ignore_changes = [
      transit_gateway_default_route_table_association,
      transit_gateway_default_route_table_propagation
    ]
  }

  tags = {
    Name = "project3-development-tgw-attachment"
  }
}

output "development_tgw_attachment_id" {
  description = "Development VPC Transit Gateway attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.development.id
}