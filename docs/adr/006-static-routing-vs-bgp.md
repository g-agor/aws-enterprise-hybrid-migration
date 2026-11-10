# ADR-006: Static Routing versus BGP for Hybrid Connectivity

**Status:** Accepted  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## 1. Context

The project requires bidirectional routing between a VMware-based on-premises environment and a private AWS Development VPC.

The network topology comprises:

| Component | Network / Configuration |
|---|---|
| On-premises LAN | `10.10.0.0/24` |
| Application server | `10.10.0.10` |
| PostgreSQL server | `10.10.0.20` |
| strongSwan VPN gateway | `10.10.0.2` |
| Development VPC | `10.30.0.0/16` |
| AWS Region | `eu-west-2` |
| AWS Transit Gateway ASN | `64512` |
| Customer Gateway ASN | `65000` |

An AWS Site-to-Site VPN connects the customer gateway to a centrally managed Transit Gateway in the Network account.

The design must determine whether routes should be configured manually or exchanged dynamically using Border Gateway Protocol (BGP).

The initial environment contains only two principal network prefixes and a small number of routing domains.

## 2. Decision

Use **static routing** for the initial Site-to-Site VPN implementation.

Configure explicit routes between:

- `10.10.0.0/24` — On-premises network
- `10.30.0.0/16` — AWS Development VPC

The AWS Site-to-Site VPN connection uses:

`static_routes_only = true`

Configure dedicated Transit Gateway route tables to control forwarding between the VPN and Development VPC attachments.

Configure on-premises routes to forward traffic destined for AWS through the strongSwan gateway.

BGP will not be enabled during the initial implementation.

## 3. Alternatives Considered

### Option 1: Static Routing

Routes are configured explicitly by administrators or Infrastructure as Code.

**Advantages**

- Appropriate for a small number of predictable CIDR ranges
- Straightforward to implement and troubleshoot
- No BGP daemon or peering session required
- Makes routing paths explicit
- Reduces initial configuration complexity
- Suitable for a controlled hybrid migration laboratory

**Disadvantages**

- Changes to network prefixes require manual updates
- Does not dynamically advertise new network destinations
- Route management becomes increasingly complex as networks grow
- No BGP-based route withdrawal on connectivity failure
- Failover behaviour requires separate design and validation

**Outcome:** Selected.

### Option 2: Dynamic Routing Using BGP

Establish BGP sessions between the customer gateway and AWS VPN tunnel endpoints.

**Advantages**

- Supports dynamic route advertisements
- Automatically communicates route changes between supported peers
- Can improve operational scalability
- Supports route withdrawal when BGP adjacency is lost
- Integrates with AWS Transit Gateway and hybrid routing designs
- Useful when additional VPCs or on-premises networks are introduced

**Disadvantages**

- Requires BGP-capable customer gateway software and configuration
- Introduces autonomous system numbers, routing policies and peering management
- Adds operational and troubleshooting complexity
- Incorrect advertisements can cause routing instability or unintended reachability
- Requires failover and route-preference testing

**Outcome:** Not selected for the initial implementation.

### Option 3: Static Routing Initially, BGP Later

Use static routing for the baseline lab and evaluate a subsequent migration to BGP.

**Advantages**

- Enables faster initial implementation
- Separates IPsec troubleshooting from BGP troubleshooting
- Allows a controlled comparison between static and dynamic routing
- Demonstrates a realistic network evolution strategy

**Disadvantages**

- Requires additional configuration and testing later
- Potentially involves replacing or reconfiguring VPN routing settings
- Introduces a planned architectural transition

**Outcome:** Selected as the development approach, with BGP treated as a future enhancement rather than a completed capability.

## 4. AWS Transit Gateway Routing Design

The architecture uses two dedicated Transit Gateway route tables.

### 4.1 VPN Attachment Route Table

Associated with the Site-to-Site VPN attachment.

| Destination | Target |
|---|---|
| `10.30.0.0/16` | Development VPC attachment |

This table directs traffic arriving from on-premises towards AWS Development.

### 4.2 Development Attachment Route Table

Associated with the Development VPC attachment.

| Destination | Target |
|---|---|
| `10.10.0.0/24` | Site-to-Site VPN attachment |

This table directs traffic arriving from AWS Development towards the on-premises environment.

### 4.3 Development VPC Route Tables

Both private subnet route tables include:

| Destination | Target |
|---|---|
| `10.30.0.0/16` | Local VPC route |
| `10.10.0.0/24` | Transit Gateway |

Automatic Transit Gateway default route-table association and propagation are disabled.

Explicit route-table associations and static routes are managed with Terraform.

## 5. On-Premises Routing Requirements

The strongSwan VPN gateway has:

- On-premises LAN address: `10.10.0.2`
- IP forwarding enabled
- Firewall forwarding controls
- A separate WAN interface connected through the residential router

The application and database servers must have routes allowing traffic destined for `10.30.0.0/16` to reach the VPN gateway.

For example, a source server may require a route logically equivalent to:

`10.30.0.0/16 via 10.10.0.2`

The VPN gateway must then forward the relevant traffic through the established IPsec security associations.

Return traffic must be routed correctly through AWS Transit Gateway and the VPN.

These requirements must be validated on the actual Ubuntu hosts.

## 6. Static Routing and VPN Tunnel Redundancy

AWS Site-to-Site VPN provides two tunnel endpoints.

However, **two tunnel endpoints do not automatically prove that application traffic will fail over successfully**.

Under the selected static-routing design, the implementation must assess:

- How strongSwan selects the active tunnel
- Whether both tunnel configurations are established
- Which route or IPsec policy controls traffic forwarding
- How a tunnel failure is detected
- Whether traffic switches to the remaining tunnel
- Whether recovery creates asymmetric routing
- How routing behaves when both tunnels become unavailable

Static routing does not provide BGP-based dynamic route withdrawal.

Any failover behaviour must therefore be demonstrated through controlled testing, not assumed from the AWS VPN service configuration.

## 7. BGP Considerations for Enterprise Deployment

A production environment with multiple sites, AWS accounts or changing network prefixes may benefit from BGP.

In such a design:

- AWS Transit Gateway uses an Amazon-side ASN.
- The customer gateway uses its own ASN.
- BGP sessions operate over the supported VPN tunnel interfaces.
- Routing policies control advertised and accepted prefixes.
- Tunnel or peer failures can trigger route withdrawal.

The current AWS Transit Gateway ASN is `64512`, while the configured Customer Gateway ASN is `65000`.

These ASNs are recorded for architectural completeness but **do not establish BGP peering in the current static-routing configuration**.

Moving to BGP would require appropriate VPN settings, customer gateway configuration and routing validation.

For the current small lab, the added complexity is not justified.

## 8. Security and Operational Considerations

### Security

- Restrict route advertisements or configured static prefixes to authorised networks.
- Avoid unnecessarily broad routes such as `0.0.0.0/0`.
- Use security groups and host firewalls to restrict application access.
- Maintain route-table segmentation between Transit Gateway attachments.
- Ensure network connectivity does not imply unrestricted workload access.

### Monitoring

Monitor:

- VPN tunnel states
- strongSwan IKE and CHILD_SA status
- Transit Gateway attachment states
- Route-table entries
- Connectivity between approved endpoints
- Packet loss and tunnel recovery behaviour

### Change Management

Manage AWS-side routing through Terraform.

Review changes using `terraform plan` before deployment.

Document required on-premises route changes and validate return paths after modifying connectivity.

## 9. Consequences

### Positive

- Lower initial routing complexity
- Explicit and predictable routing configuration
- Easier fault isolation during first-time VPN establishment
- Suitable for the known on-premises and AWS CIDR ranges
- Clear migration path towards dynamic routing if requirements expand

### Negative

- Manual route maintenance
- Limited scalability as networks grow
- No BGP-based route advertisement or withdrawal
- Additional tunnel failover design and validation required
- Greater operational responsibility for maintaining correct routes

## 10. Implementation Status

**Completed**

- Configured AWS Site-to-Site VPN for static routing
- Deployed dedicated Transit Gateway route tables
- Configured static routes between Development and the VPN attachment
- Deployed private VPC subnet routes towards the on-premises network
- Enabled IP forwarding on the on-premises VPN gateway

**Pending**

- Configure strongSwan tunnel policies and authentication
- Implement and verify on-premises routes
- Verify effective AWS Transit Gateway route-table entries
- Establish the IPsec connection
- Validate bidirectional packet forwarding
- Test tunnel interruption and recovery
- Record the observed routing and failover behaviour

## 11. Validation Criteria

The routing design is considered operational when:

1. AWS Transit Gateway route tables contain the intended static routes.
2. Both Development private route tables direct `10.10.0.0/24` traffic to the Transit Gateway.
3. On-premises hosts route AWS-bound traffic through `10.10.0.2`.
4. At least one IPsec tunnel is established.
5. Approved traffic can travel between on-premises and AWS private endpoints.
6. Return traffic follows the expected route.
7. Any tunnel failover behaviour is tested and documented.

## 12. References

- [AWS Site-to-Site VPN Routing Options](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPNRoutingTypes.html)
- [AWS Transit Gateway Route Tables](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html)
- [AWS Site-to-Site VPN](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
- [strongSwan Documentation](https://docs.strongswan.org/)
