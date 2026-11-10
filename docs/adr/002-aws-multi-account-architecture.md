
# ADR-002: AWS Multi-Account Architecture

**Status:** Accepted  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## Context

The project demonstrates migration of an on-premises application and PostgreSQL database to AWS using an enterprise-style multi-account architecture.

The design must enforce separation between centralised networking, workload infrastructure and management functions. It must also remain isolated from an existing AWS portfolio project.

A single-account architecture would reduce deployment complexity but would not adequately demonstrate organisational governance, workload isolation or shared networking patterns.

## Decision

Use three AWS accounts within AWS Organizations:

| Account | Responsibility |
|---|---|
| Management | AWS Organizations, central billing and Terraform remote state |
| Network | Transit Gateway, Site-to-Site VPN, Customer Gateway and shared network routing |
| Development | Application VPC, private subnets and migration workloads |

The Network account owns the Transit Gateway and shares it with Development using AWS Resource Access Manager (RAM).

The Development account attaches its VPC to the shared Transit Gateway.

Terraform deployments are separated into account-specific root modules, with explicit AWS provider profiles and `allowed_account_ids`.

## Alternatives Considered

### Option 1: Single AWS Account

**Advantages**
- Simpler deployment and IAM management
- Fewer cross-account dependencies
- Reduced operational overhead

**Disadvantages**
- Weaker account-level isolation
- Larger blast radius
- Less representative of enterprise environments

**Decision:** Rejected.

### Option 2: Multi-Account with Decentralised Networking

Each workload account maintains its own hybrid connectivity.

**Advantages**
- Greater autonomy for workload teams
- Independent network deployment cycles

**Disadvantages**
- Duplicated VPN connectivity
- Increased network management complexity
- More difficult centralised governance

**Decision:** Rejected.

### Option 3: Multi-Account with Centralised Networking

A dedicated Network account provides shared connectivity through Transit Gateway.

**Advantages**
- Centralised network administration
- Separation of networking and workloads
- Scalable foundation for additional AWS accounts
- Consistent hybrid routing architecture

**Disadvantages**
- Additional cross-account dependencies
- More complex Terraform deployment sequence
- Transit Gateway and VPN operating costs

**Decision:** Selected.

## Consequences

### Positive

- Clear account-level security and operational boundaries
- Centralised management of hybrid connectivity
- Separation of networking from application workloads
- Supports adding future workload accounts
- Independent Terraform state for Network and Development

### Negative

- AWS RAM configuration and cross-account attachment acceptance are required
- Troubleshooting spans IAM, Organizations, RAM, VPC and Transit Gateway
- Deployment order must account for cross-account dependencies
- Shared network infrastructure incurs ongoing costs

## Implementation

The following have been deployed in `eu-west-2`:

- AWS Organizations Management, Network and Development accounts
- S3-backed Terraform remote state
- Transit Gateway in the Network account
- Site-to-Site VPN attached to the Transit Gateway
- RAM resource share restricted to the Organization
- Development VPC (`10.30.0.0/16`)
- Two private subnets in separate Availability Zones
- Cross-account VPC attachment, confirmed `available`
- Dedicated Transit Gateway route tables and VPC routes

The on-premises VMware network uses `10.10.0.0/24`.

The AWS-side networking has been provisioned, but the on-premises IPsec tunnels and end-to-end connectivity are not yet operational.

## Security Considerations

- Apply account-specific IAM roles and temporary credentials.
- Enforce account restrictions using Terraform `allowed_account_ids`.
- Restrict RAM sharing to the AWS Organization.
- Keep Terraform state, credentials and VPN secrets out of Git.
- Apply least-privilege security group and firewall rules.
- Review cost, operational ownership and change management for shared network services.

## Validation

**Completed**
- Verified account identities and Organization membership
- Verified AWS RAM sharing
- Confirmed Transit Gateway VPC attachment is `available`
- Deployed Development private subnets and route tables

**Pending**
- Verify all effective route-table entries
- Establish Site-to-Site VPN tunnels
- Test end-to-end hybrid connectivity
- Validate security controls and application migration

## References

- [AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
- [AWS Resource Access Manager](https://docs.aws.amazon.com/ram/latest/userguide/what-is.html)
