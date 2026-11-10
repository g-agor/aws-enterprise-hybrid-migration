
# Public IPv4 of the Virgin Media router
variable "onprem_public_ip" {
  description = "Public IPv4 address of the on-premises VPN gateway NAT router"
  type        = string

  validation {
    condition     = can(cidrnetmask("${var.onprem_public_ip}/32"))
    error_message = "Provide a valid IPv4 address."
  }
}

# Represents the on-premises strongSwan gateway
resource "aws_customer_gateway" "onprem" {
  bgp_asn    = 65000
  ip_address = var.onprem_public_ip
  type       = "ipsec.1"

  tags = {
    Name = "project3-onprem-cgw"
  }
}

# AWS-managed Site-to-Site VPN connection
resource "aws_vpn_connection" "onprem" {
  customer_gateway_id = aws_customer_gateway.onprem.id
  transit_gateway_id  = aws_ec2_transit_gateway.hybrid.id

  type               = "ipsec.1"
  static_routes_only = true

  local_ipv4_network_cidr  = "10.10.0.0/24"
  remote_ipv4_network_cidr = "10.30.0.0/16"

  tunnel1_ike_versions = ["ikev2"]
  tunnel2_ike_versions = ["ikev2"]

  preshared_key_storage = "SecretsManager"

  tags = {
    Name = "project3-onprem-site-to-site-vpn"
  }
}

# Non-sensitive identifiers for subsequent configuration
output "customer_gateway_id" {
  value = aws_customer_gateway.onprem.id
}

output "vpn_connection_id" {
  value = aws_vpn_connection.onprem.id
}

output "vpn_attachment_id" {
  value = aws_vpn_connection.onprem.transit_gateway_attachment_id
}
