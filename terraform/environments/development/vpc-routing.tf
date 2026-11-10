
# Enable after the Network account accepts the TGW attachment
variable "enable_onprem_routes" {
  description = "Enable VPC routes towards the on-premises network"
  type        = bool
  default     = false
}

# Route private subnet traffic to on-premises via Transit Gateway
resource "aws_route" "to_onprem" {
  count = var.enable_onprem_routes ? length(aws_route_table.private) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "10.10.0.0/24"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.development
  ]
}
