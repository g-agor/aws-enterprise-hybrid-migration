
# Enable after Development creates its VPC attachment
variable "enable_development_attachment" {
  description = "Enable cross-account Development attachment acceptance"
  type        = bool
  default     = false
}

variable "development_attachment_id" {
  description = "Development VPC TGW attachment ID"
  type        = string
  default     = null

  validation {
    condition = (
      var.development_attachment_id == null ||
      can(regex("^tgw-attach-[0-9a-f]+$", var.development_attachment_id))
    )
    error_message = "Provide a valid TGW attachment ID."
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "development" {
  count = var.enable_development_attachment ? 1 : 0

  transit_gateway_attachment_id = var.development_attachment_id

  tags = {
    Name = "project3-development-tgw-attachment"
  }

  lifecycle {
    precondition {
      condition = (
        var.development_attachment_id != null
      )
      error_message = "Set development_attachment_id before enabling acceptance."
    }
  }
}

# Associate traffic arriving from Development with its TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "development" {
  count = var.enable_development_attachment ? 1 : 0

  transit_gateway_attachment_id = (
    aws_ec2_transit_gateway_vpc_attachment_accepter.development[0].id
  )

  transit_gateway_route_table_id = (
    aws_ec2_transit_gateway_route_table.development.id
  )
}

# Traffic arriving from on-premises goes to the Development VPC
resource "aws_ec2_transit_gateway_route" "to_development" {
  count = var.enable_development_attachment ? 1 : 0

  destination_cidr_block = "10.30.0.0/16"

  transit_gateway_attachment_id = (
    aws_ec2_transit_gateway_vpc_attachment_accepter.development[0].id
  )

  transit_gateway_route_table_id = (
    aws_ec2_transit_gateway_route_table.vpn.id
  )
}
