# ADR-006: Static Routing versus BGP for Hybrid Connectivity

## Context

The hybrid architecture requires bidirectional routing between an on-premises VMware network (`10.10.0.0/24`) and an AWS Development VPC (`10.30.0.0/16`) through AWS Site-to-Site VPN and Transit Gateway.

With two fixed network prefixes and a limited number of routing domains, the primary decision was whether to use manually configured routes or dynamic route exchange through Border Gateway Protocol (BGP).

## Decision

Implement **static routing** across the hybrid environment.

The AWS Site-to-Site VPN uses `static_routes_only = true`, with dedicated Transit Gateway route tables and explicit routes between the VPN and Development VPC attachments.

| Routing location | Destination | Next hop |
|---|---|---|
| TGW VPN attachment | `10.30.0.0/16` | Development VPC attachment |
| TGW Development attachment | `10.10.0.0/24` | VPN attachment |
| Development private subnets | `10.10.0.0/24` | Transit Gateway |
| On-premises application/database VMs | `10.30.0.0/16` | strongSwan gateway (`10.10.0.2`) |

Automatic Transit Gateway default route-table association and propagation are disabled to maintain explicit routing control.

BGP is not configured. The Transit Gateway ASN (`64512`) and Customer Gateway ASN (`65000`) do not represent an active BGP peering relationship.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Static routing | Selected | Simple, predictable and appropriate for fixed network prefixes |
| Dynamic BGP routing | Rejected | Adds routing daemon, peering and policy complexity unnecessary for this topology |
| Static initially, BGP later | Future option | Provides a potential scalability improvement if the network expands |

## Implementation

Static routing is configured across the Transit Gateway, Development VPC and on-premises Ubuntu hosts.

The strongSwan gateway provides IPsec connectivity and forwards traffic between the VMware LAN and AWS.

Two AWS VPN tunnels are configured and have been independently tested, including manual tunnel switching and recovery.

**Static routing does not provide automatic route withdrawal or tunnel failover.** The current implementation requires operator intervention to switch between tunnels.

AWS-side infrastructure routing is managed through Terraform, while on-premises host routing and strongSwan configuration are administered separately.

## Consequences

**Benefits**

- Reduced routing complexity.
- Explicit and predictable network paths.
- Straightforward troubleshooting.
- No BGP daemon or peering configuration required.
- Appropriate for the current hybrid migration architecture.

**Trade-offs**

- Network prefix changes require manual route updates.
- Route management becomes less scalable as networks expand.
- No dynamic route advertisement or withdrawal.
- VPN recovery requires manual intervention.

A larger enterprise environment with multiple sites, changing network prefixes or stronger availability requirements could benefit from BGP-based dynamic routing.

## Validation

- Transit Gateway and private subnet routing configured successfully.
- On-premises hosts established connectivity through the strongSwan gateway.
- Private communication verified between VMware and AWS.
- Both VPN tunnels independently tested.
- Manual VPN failover and restoration demonstrated.
- PostgreSQL migration and private EC2 application access completed over the hybrid connection.

## References

- [AWS Site-to-Site VPN Routing Options](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPNRoutingTypes.html)
- [AWS Transit Gateway Route Tables](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html)
- [strongSwan Documentation](https://docs.strongswan.org/)