
# Associate the VPN attachment with the VPN route table.
# Traffic arriving from on-premises uses this routing domain.

resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  transit_gateway_attachment_id  = aws_vpn_connection.onprem.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn.id
}

# Return route from Development towards on-premises.
# The VPN attachment is the next hop for 10.10.0.0/24.

resource "aws_ec2_transit_gateway_route" "to_onprem" {
  destination_cidr_block = "10.10.0.0/24"

  transit_gateway_attachment_id  = aws_vpn_connection.onprem.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.development.id
}
