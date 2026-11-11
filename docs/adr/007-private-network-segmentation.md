# ADR-007: Private Network Segmentation and Security

## Context

The hybrid migration architecture requires secure hosting of application and PostgreSQL workloads in AWS while maintaining controlled access from the on-premises VMware environment.

The design must minimise public exposure, enforce workload-level network restrictions and support private connectivity through the centralised Transit Gateway.

## Decision

Deploy the application and database within **private subnets in the Development VPC**, using dedicated security groups and explicit hybrid routing.

| Network component | Configuration |
|---|---|
| Development VPC | `10.30.0.0/16` |
| Private subnet A | `10.30.0.0/24` — `eu-west-2a` |
| Private subnet B | `10.30.1.0/24` — `eu-west-2b` |
| On-premises network | `10.10.0.0/24` |
| Hybrid connectivity | AWS Transit Gateway and Site-to-Site VPN |

The VPC has no Internet Gateway, NAT Gateway or general internet route. Private workloads do not receive public IPv4 addresses.

Each private subnet uses a dedicated route table with explicit routing towards the on-premises network.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Public application and database subnets | Rejected | Unnecessary public exposure and larger attack surface |
| Private subnets with NAT Gateway | Rejected | Additional cost and outbound internet access unnecessary for the implemented workloads |
| Private subnets with Transit Gateway connectivity | Selected | Controlled hybrid access without publicly exposing workloads |

## Implementation

The Development account hosts a private Ubuntu EC2 application server and Amazon RDS PostgreSQL 16.

Security controls include:

- **Default security group:** No ingress or egress rules.
- **Application security group:** SSH restricted to the on-premises application host; Flask port 5000 accessible from the approved on-premises subnet.
- **Database security group:** PostgreSQL port 5432 restricted to the Development VPC and authorised on-premises migration network.
- **Routing:** Private subnet routes to `10.10.0.0/24` through Transit Gateway.
- **Instance security:** SSH key authentication and IMDSv2 enforcement.
- **Database security:** Encrypted RDS storage, TLS-verified connections and a dedicated read-only application role.

Application source files and Python dependencies were transferred over the VPN and installed offline, avoiding the need for NAT Gateway access.

No VPC endpoints were required for the implemented application deployment.

The two private subnets span separate Availability Zones, although the application uses a single EC2 instance and RDS operates in Single-AZ mode.

## Consequences

**Benefits**

- Reduced internet-facing attack surface.
- Private application and database connectivity.
- Explicit network access restrictions.
- Separation of shared networking and workload infrastructure.
- Avoidance of unnecessary NAT Gateway charges.
- Foundation for future multi-AZ deployments.

**Trade-offs**

- Workload administration depends on private connectivity.
- No general internet egress for operating system updates or package installation.
- Future AWS service integrations may require VPC endpoints or controlled egress.
- Single-instance application hosting and Single-AZ RDS do not provide high availability.

## Validation

- Confirmed private EC2 access over the Site-to-Site VPN.
- Established PostgreSQL connectivity to private RDS.
- Deployed Flask and Python dependencies without internet access on EC2.
- Verified application-to-database connectivity using TLS.
- Successfully accessed the migrated Flask API from the on-premises network.
- Confirmed workload connectivity through the intended hybrid routing path.

## References

- [Amazon VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [VPC Route Tables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html)
- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)