# ADR-005: AWS Site-to-Site VPN versus Direct Connect

## Context

The project requires secure hybrid connectivity between a physically separate VMware environment and AWS workloads in `eu-west-2`.

The on-premises environment uses a residential internet connection with a strongSwan VPN gateway behind NAT. AWS hosts the migration workloads in private subnets connected to a centrally managed Transit Gateway.

The connectivity solution must support application migration, PostgreSQL data transfer and private workload access while balancing security, cost, reliability and operational complexity.

## Decision

Use **AWS Site-to-Site VPN with IKEv2/IPsec**, terminating on the Transit Gateway in the Network account.

An Ubuntu strongSwan gateway (`10.10.0.2`) establishes encrypted tunnels through the residential router using NAT traversal.

The implementation uses:

- Two AWS VPN tunnel endpoints.
- IKEv2/IPsec with pre-shared key authentication.
- UDP 500 and 4500 for IKE and NAT traversal.
- Static routing between `10.10.0.0/24` and `10.30.0.0/16`.
- Transit Gateway routing to private Development workloads.

Both tunnels have been configured and independently tested. Manual failover and restoration were demonstrated successfully.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Site-to-Site VPN | Selected | Encrypted connectivity over existing internet infrastructure at manageable cost |
| AWS Direct Connect | Rejected | Dedicated connectivity and provider provisioning are disproportionate to the lab's requirements |
| Direct Connect with VPN encryption | Rejected | Additional resilience and transport options, but unnecessary cost and complexity |
| Simulated on-premises VPC | Rejected | Does not demonstrate real customer-gateway, NAT traversal and physical environment separation |

## Implementation

The deployed architecture connects:

**VMware application/database servers → strongSwan gateway → Residential router → IPsec VPN → AWS Transit Gateway → Private Development VPC**

The customer gateway operates behind NAT with UDP 500 and 4500 forwarded to the Ubuntu VPN VM.

AWS-side routing is managed through dedicated Transit Gateway route tables, while on-premises hosts route AWS-bound traffic through the strongSwan gateway.

VPN pre-shared keys are stored outside source control.

The design uses static routes rather than BGP, and VPN tunnel failover requires manual intervention.

## Consequences

**Benefits**

- Secure connectivity between physically separate environments.
- No dedicated network circuit or colocation infrastructure required.
- Private access to AWS application and database workloads.
- Practical experience with IPsec, NAT-T, customer gateways and hybrid routing.
- Integration with centralised AWS networking.

**Trade-offs**

- Dependent on residential internet availability and performance.
- Public IPv4 changes can disrupt VPN connectivity.
- Manual tunnel recovery introduces operational dependency.
- VPN and Transit Gateway resources incur ongoing charges.
- Less predictable throughput and latency than appropriately provisioned dedicated connectivity.

For enterprise production environments, Direct Connect or a combined Direct Connect/VPN design may be preferable where throughput, availability and operational requirements justify it.

## Validation

- Both IKEv2/IPsec tunnels established successfully.
- strongSwan security associations confirmed.
- Manual tunnel switching and restoration tested.
- Private routing between on-premises and AWS verified.
- PostgreSQL migration completed over the VPN.
- SSH and Flask API access to private AWS EC2 demonstrated.

## References

- [AWS Site-to-Site VPN](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
- [AWS Direct Connect](https://docs.aws.amazon.com/directconnect/latest/UserGuide/Welcome.html)
- [strongSwan Documentation](https://docs.strongswan.org/)