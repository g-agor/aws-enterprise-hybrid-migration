
# ADR-004: AWS Transit Gateway Hub-and-Spoke Architecture

**Status:** Accepted  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## 1. Context

The project requires private connectivity between an on-premises VMware environment and workloads hosted in AWS.

The on-premises environment contains:

- Application server: `10.10.0.10`
- PostgreSQL database server: `10.10.0.20`
- strongSwan VPN gateway: `10.10.0.2`
- On-premises LAN: `10.10.0.0/24`

The AWS Development environment contains:

- VPC: `10.30.0.0/16`
- Private subnet A: `10.30.0.0/24`
- Private subnet B: `10.30.1.0/24`

The architecture requires centralised hybrid connectivity, network isolation, controlled routing and support for additional workload accounts.

## 2. Decision

Deploy an AWS Transit Gateway in a dedicated Network account in `eu-west-2`.

Use a hub-and-spoke topology where:

- The Transit Gateway acts as the central network hub.
- The Development VPC connects as a spoke.
- The Site-to-Site VPN connects the on-premises environment to the hub.
- AWS RAM shares the Transit Gateway with the Development account.
- Dedicated Transit Gateway route tables control traffic between attachments.

The Transit Gateway uses Amazon ASN `64512`.

Automatic default route-table association and propagation are disabled.

Routing is configured explicitly through Terraform.

## 3. Architecture

```text
             ON-PREMISES ENVIRONMENT
                  10.10.0.0/24
                        |
                strongSwan Gateway
                    10.10.0.2
                        |
                 Internet / IPsec
                        |
                  AWS VPN Connection
                        |
                NETWORK ACCOUNT
                Transit Gateway
                 ASN 64512
                        |
              +---------+---------+
              |                   |
        VPN TGW Route       Development TGW
            Table             Route Table
              |                   |
        10.30.0.0/16          10.10.0.0/24
        -> Dev VPC            -> VPN
              |                   |
              +---------+---------+
                        |
               Development VPC
                  10.30.0.0/16
                        |
               Two private subnets
```

The diagram is a logical representation of routing relationships, not a depiction of physical network connections.

## 4. Transit Gateway Routing Design

Two dedicated Transit Gateway route tables provide explicit routing between the VPN and Development VPC attachments.

### VPN Route Table

Associated with the VPN attachment.

| Destination | Target |
|---|---|
| `10.30.0.0/16` | Development VPC attachment |

Traffic arriving from on-premises is forwarded towards the Development VPC.

### Development Route Table

Associated with the Development VPC attachment.

| Destination | Target |
|---|---|
| `10.10.0.0/24` | VPN attachment |

Traffic arriving from Development is forwarded towards the on-premises network.

### Development VPC Route Tables

Both private subnet route tables contain:

| Destination | Target |
|---|---|
| `10.30.0.0/16` | Local VPC route |
| `10.10.0.0/24` | Transit Gateway |

The Transit Gateway and VPC route tables work together to provide bidirectional forwarding.

Actual connectivity additionally depends on VPN tunnel establishment, on-premises routing, firewalls and workload security controls.

## 5. Alternatives Considered

### Option 1: VPC Peering

**Advantages**
- Simple private connectivity between VPCs
- No Transit Gateway required

**Disadvantages**
- Does not provide transitive routing
- Less suitable for centralised connectivity across many VPCs
- Does not directly replace a hybrid VPN transit architecture

**Outcome:** Rejected.

### Option 2: Direct VPC-Attached Site-to-Site VPN

**Advantages**
- Simpler for a single VPC
- Fewer Transit Gateway dependencies
- Potentially lower cost for a small deployment

**Disadvantages**
- Connectivity is tied to a particular VPC
- Additional workload VPCs may require duplicated connectivity or a revised architecture
- Less representative of centralised enterprise networking

**Outcome:** Rejected.

### Option 3: Transit Gateway Hub-and-Spoke

**Advantages**
- Centralises hybrid connectivity
- Supports multiple AWS workload accounts and VPCs
- Enables route-table-based network segmentation
- Reduces the need to duplicate hybrid connectivity
- Aligns with enterprise shared-network architectures

**Disadvantages**
- Additional complexity
- Transit Gateway attachment and data-processing charges
- Requires careful cross-account configuration
- Introduces dependencies on central networking services

**Outcome:** Selected.

## 6. Routing and Segmentation Controls

The design uses:

- Dedicated Transit Gateway route tables
- Explicit route-table associations
- Static routes for known CIDR ranges
- Disabled default association and propagation
- Organisation-restricted AWS RAM sharing
- Private workload subnets
- Restrictive default security groups

Dedicated route tables allow future workload spokes to have distinct routing policies.

However, route-table separation alone is not a complete security boundary. Security groups, network ACLs, host firewalls and IAM controls remain necessary.

## 7. Deployment Sequence

The Transit Gateway infrastructure was deployed using Terraform in the following order:

1. Create Transit Gateway in the Network account.
2. Create dedicated Transit Gateway route tables.
3. Create AWS RAM resource share.
4. Associate Transit Gateway and Development account with the share.
5. Create Development VPC and private subnets.
6. Create cross-account Transit Gateway VPC attachment.
7. Accept the attachment in the Network account.
8. Associate the VPC attachment with its Transit Gateway route table.
9. Configure static Transit Gateway routes.
10. Add on-premises routes to Development private subnet route tables.

The Development attachment was subsequently verified as `available`.

## 8. Operational Considerations

### Availability

The Development attachment uses subnets in two Availability Zones.

This provides multi-AZ attachment coverage, but does not independently guarantee application or database high availability.

### Monitoring

Operational monitoring should cover:

- Transit Gateway attachment state
- VPN tunnel availability
- Routing configuration
- Network traffic and throughput
- CloudWatch metrics and alarms
- Network connectivity and reachability

### Cost

Transit Gateway introduces ongoing charges for attachments and data processing.

The Site-to-Site VPN also incurs recurring charges.

The environment should be decommissioned or managed carefully when not in active use.

### Change Management

Routing changes should be reviewed through Terraform plans before deployment.

Cross-account attachment changes must account for both Network and Development Terraform states.

## 9. Consequences

### Positive

- Centralised AWS hybrid network architecture
- Explicit routing between on-premises and AWS
- Separation of workload and networking responsibilities
- Scalable foundation for additional AWS accounts
- Documented network segmentation controls

### Negative

- Increased operational complexity
- Additional networking costs
- Cross-account deployment dependencies
- Potential central connectivity failure domain
- Requirement for careful troubleshooting across multiple routing layers

## 10. Validation

**Completed**
- Transit Gateway deployed in Network account
- RAM sharing configured successfully
- Development VPC attachment created and accepted
- Attachment state confirmed as `available`
- Dedicated TGW route tables deployed
- Static AWS-side routing provisioned through Terraform

**Pending**
- Verify effective Transit Gateway route-table entries
- Establish strongSwan IPsec tunnels
- Verify on-premises return routes
- Test bidirectional connectivity
- Validate security controls and traffic restrictions
- Capture operational evidence and metrics

## 11. References

- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
- [Transit Gateway Route Tables](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html)
- [Transit Gateway Attachments](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-attachments.html)
- [AWS Resource Access Manager](https://docs.aws.amazon.com/ram/latest/userguide/what-is.html)
