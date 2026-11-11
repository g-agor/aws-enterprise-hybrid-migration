# ADR-002: AWS Multi-Account Architecture

## Context

The hybrid migration architecture requires separation between organisational management, shared networking and application workloads.

A multi-account design provides clearer infrastructure ownership, limits the potential impact of configuration errors and reflects enterprise AWS operating models.

## Decision

Use three AWS accounts within AWS Organizations, with centralised networking managed independently of application workloads.

| Account | Responsibility |
|---|---|
| Management | AWS Organizations, billing and Terraform remote state |
| Network | Transit Gateway, Site-to-Site VPN and hybrid routing |
| Development | VPC, private EC2 application and Amazon RDS PostgreSQL |

The Network account owns the Transit Gateway and shares it with Development through AWS Resource Access Manager (RAM).

Development attaches its VPC to the shared Transit Gateway, providing private connectivity to the on-premises VMware environment.

Terraform uses account-specific deployment profiles, independent state and `allowed_account_ids` restrictions.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| Single AWS account | Rejected | Larger blast radius and weaker responsibility separation |
| Multi-account with decentralised networking | Rejected | Duplicated VPN infrastructure and increased operational complexity |
| Multi-account with centralised networking | Selected | Shared connectivity, clear ownership and scalable network architecture |

## Implementation

The architecture was deployed in `eu-west-2` and includes:

- Transit Gateway and Site-to-Site VPN in the Network account.
- AWS RAM sharing and cross-account VPC attachment.
- Static routing between `10.10.0.0/24` and `10.30.0.0/16`.
- Two configured and independently tested IPsec tunnels.
- Private application and database workloads in Development.

The on-premises strongSwan gateway provides VPN connectivity to AWS. Both tunnels support manual failover, which was tested successfully.

The migrated Flask application runs on private EC2 and connects to Amazon RDS PostgreSQL without public internet exposure.

## Consequences

**Benefits**

- Clear separation of network and workload responsibilities.
- Centralised hybrid connectivity.
- Independent Terraform deployment boundaries.
- Foundation for additional workload VPCs and accounts.

**Trade-offs**

- Cross-account dependencies increase deployment and troubleshooting complexity.
- Shared networking introduces additional operating costs.
- Static routing requires manual administration.
- VPN tunnel failover is manual rather than automatic.

## Validation

- Cross-account Transit Gateway attachment operational.
- Private routing between VMware and AWS established.
- Both VPN tunnels tested independently.
- On-premises access to private EC2 and RDS verified.
- Flask application and PostgreSQL migration completed successfully.

## References

- [AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
- [AWS Resource Access Manager](https://docs.aws.amazon.com/ram/latest/userguide/what-is.html)