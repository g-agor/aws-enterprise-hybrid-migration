# ADR-004: AWS Transit Gateway Hub-and-Spoke Architecture

## Context

The hybrid migration environment requires private, bidirectional connectivity between an on-premises VMware network and AWS workloads.

The architecture must support centralised network management, cross-account connectivity, controlled routing and future workload expansion without duplicating VPN infrastructure.

## Decision

Deploy **AWS Transit Gateway in the Network account** as the central connectivity hub, with the Development VPC and Site-to-Site VPN connected as spokes.

The Transit Gateway operates in `eu-west-2` using ASN `64512` and is shared with the Development account through AWS Resource Access Manager (RAM).

Routing uses dedicated Transit Gateway route tables, explicit attachment associations and static routes. Default route-table association and propagation are disabled.

### Network Architecture

| Component | Network |
|---|---|
| On-premises VMware LAN | `10.10.0.0/24` |
| strongSwan VPN gateway | `10.10.0.2` |
| Development VPC | `10.30.0.0/16` |
| Private subnet A | `10.30.0.0/24` |
| Private subnet B | `10.30.1.0/24` |

The logical traffic path is:

**VMware network → strongSwan → AWS Site-to-Site VPN → Transit Gateway → Development VPC → Private workloads**

### Routing Design

| Route table | Destination | Target |
|---|---|---|
| TGW VPN attachment | `10.30.0.0/16` | Development VPC attachment |
| TGW Development attachment | `10.10.0.0/24` | VPN attachment |
| Development private subnets | `10.10.0.0/24` | Transit Gateway |

Separate route tables establish controlled bidirectional forwarding without allowing unrestricted routing between future workload spokes.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| VPC peering | Rejected | No transitive routing and unsuitable as the central hybrid connectivity solution |
| Direct VPC-attached VPN | Rejected | Simpler for one VPC but less scalable across workload accounts |
| Transit Gateway hub-and-spoke | Selected | Centralised connectivity, cross-account sharing and route-table segmentation |

## Implementation

The architecture includes:

- Transit Gateway deployed in the Network account.
- Organisation-scoped AWS RAM resource sharing.
- Cross-account Development VPC attachment.
- Dedicated Transit Gateway route tables and static routes.
- Private subnet routing towards the on-premises network.
- Two configured strongSwan IPsec tunnels.
- Application and PostgreSQL workloads hosted in private AWS subnets.

Both VPN tunnels were independently tested, including manual tunnel switching and restoration.

The Development VPC has no Internet Gateway or NAT Gateway, and its application and database resources are not publicly accessible.

Routing controls are complemented by security groups and workload-level authentication.

## Consequences

**Benefits**

- Centralised hybrid connectivity and network ownership.
- Private communication between VMware and AWS.
- Clear separation between networking and workload accounts.
- Scalable foundation for additional VPC attachments.
- Explicit route-table-based network segmentation.

**Trade-offs**

- Additional Transit Gateway and VPN operating costs.
- Cross-account dependencies and more complex troubleshooting.
- Static routes require controlled administration.
- Shared Transit Gateway connectivity introduces a central dependency.
- VPN tunnel failover is manual rather than automatic.

## Validation

- Cross-account Transit Gateway attachment confirmed operational.
- Static bidirectional routing established between `10.10.0.0/24` and `10.30.0.0/16`.
- Both IPsec tunnels tested successfully.
- Private EC2 access verified over the VPN.
- PostgreSQL migration traffic successfully traversed the hybrid connection.
- On-premises access to the migrated AWS Flask application demonstrated.

## References

- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
- [Transit Gateway Route Tables](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html)
- [AWS Resource Access Manager](https://docs.aws.amazon.com/ram/latest/userguide/what-is.html)