
# Project 3 - Development VPC routing
# On-premises network: 10.10.0.0/24
# AWS Development VPC: 10.30.0.0/16

# Enable routes to the on-premises environment.
# The Transit Gateway attachment has already been accepted.
variable "enable_onprem_routes" {
  description = "Enable VPC routes towards the on-premises network"
  type        = bool
  default     = true
}

# Route traffic from private subnets to on-premises via TGW.
resource "aws_route" "to_onprem" {
  count = var.enable_onprem_routes ? length(aws_route_table.private) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "10.10.0.0/24"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.development
  ]
}
