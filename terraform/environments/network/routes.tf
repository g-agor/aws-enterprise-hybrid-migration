
# Route table for traffic arriving from on-premises VPN
resource "aws_ec2_transit_gateway_route_table" "vpn" {
  transit_gateway_id = aws_ec2_transit_gateway.hybrid.id

  tags = {
    Name = "project3-tgw-vpn-rt"
  }
}

# Route table for traffic arriving from the Development VPC
resource "aws_ec2_transit_gateway_route_table" "development" {
  transit_gateway_id = aws_ec2_transit_gateway.hybrid.id

  tags = {
    Name = "project3-tgw-development-rt"
  }
}

output "vpn_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.vpn.id
}

output "development_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.development.id
}
