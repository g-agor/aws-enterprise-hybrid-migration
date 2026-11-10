
# ADR-007: Private Network Segmentation and Security

**Status:** Accepted  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## 1. Context

The project demonstrates migration of an on-premises application and PostgreSQL database to AWS using a centralised hybrid network architecture.

The AWS environment must provide network isolation, controlled connectivity and a secure foundation for hosting application and database workloads.

The on-premises environment contains:

- Application server: `10.10.0.10`
- PostgreSQL server: `10.10.0.20`
- VPN gateway: `10.10.0.2`
- On-premises LAN: `10.10.0.0/24`

The AWS Development environment uses:

- VPC: `10.30.0.0/16`
- Private subnet A: `10.30.0.0/24`
- Private subnet B: `10.30.1.0/24`
- Availability Zones: `eu-west-2a` and `eu-west-2b`
- Transit Gateway attachment to the Network account

The design must limit unnecessary public exposure while permitting controlled connectivity from the on-premises environment.

## 2. Decision

Deploy application and database migration destinations within private subnets in the Development VPC.

The initial implementation uses:

1. A dedicated Development VPC.
2. Two private subnets across separate Availability Zones.
3. Separate route tables for each private subnet.
4. No automatic public IPv4 assignment.
5. No Internet Gateway or NAT Gateway in the initial VPC.
6. A restrictive default security group.
7. Explicit routing to the on-premises network through AWS Transit Gateway.
8. Account-level isolation between Network and Development.

Workload-specific security groups will be created before application and database deployment.

Private access to AWS services will be evaluated using VPC endpoints or other controlled connectivity mechanisms.

## 3. Alternatives Considered

### Option 1: Public Subnets for Application and Database

Deploy instances into public subnets with internet-routable addresses.

**Advantages**

- Simple direct access for administration
- Straightforward internet connectivity
- Fewer private connectivity dependencies

**Disadvantages**

- Increased exposure to internet-originated traffic
- Greater reliance on perimeter rules
- Inappropriate public exposure for database workloads
- Less representative of private enterprise migration targets

**Outcome:** Rejected.

### Option 2: Private Subnets with NAT Gateway

Deploy workloads privately while routing outbound internet traffic through a managed NAT Gateway.

**Advantages**

- Enables outbound internet access without public instance addresses
- Supports operating system updates and external package downloads
- Common AWS workload architecture
- Reduces the need for direct internet access to instances

**Disadvantages**

- Introduces NAT Gateway hourly and data-processing charges
- Requires Internet Gateway and public subnet infrastructure
- Provides outbound access that may not be necessary for all workloads
- Adds infrastructure and routing complexity

**Outcome:** Deferred until a workload requirement justifies it.

### Option 3: Private Subnets with Transit Gateway Connectivity

Deploy private workloads with explicit routes to the on-premises environment through a centrally managed Transit Gateway.

**Advantages**

- No requirement for public workload IP addresses
- Supports private hybrid application and database traffic
- Centralises shared network connectivity
- Maintains workload and network account separation
- Provides a scalable foundation for additional AWS networks

**Disadvantages**

- Requires functioning hybrid connectivity
- Introduces Transit Gateway routing dependencies
- Private workloads may require VPC endpoints or controlled egress to reach AWS services
- More complex troubleshooting across network boundaries

**Outcome:** Selected.

## 4. Network Architecture

```text
                  AWS NETWORK ACCOUNT
                    Transit Gateway
                          |
             Cross-account VPC attachment
                          |
                 AWS DEVELOPMENT ACCOUNT
                      10.30.0.0/16
                          |
             +------------+------------+
             |                         |
       Private Subnet A          Private Subnet B
        10.30.0.0/24              10.30.1.0/24
          eu-west-2a                eu-west-2b
             |                         |
        Route Table A             Route Table B
             |                         |
             +------------+------------+
                          |
                 Route to 10.10.0.0/24
                  via Transit Gateway
                          |
                  AWS Site-to-Site VPN
                          |
                  On-premises network
                     10.10.0.0/24
```

The diagram represents the intended logical connectivity.

The AWS infrastructure and VPC routes have been deployed, but end-to-end hybrid connectivity has not yet been validated.

## 5. Subnet and Routing Design

### 5.1 VPC Address Space

The Development VPC uses:

`10.30.0.0/16`

The address range does not overlap the on-premises network:

`10.10.0.0/24`

Non-overlapping CIDR ranges are required for straightforward routing between the environments.

### 5.2 Private Subnets

| Subnet | CIDR | Availability Zone |
|---|---|---|
| Private A | `10.30.0.0/24` | `eu-west-2a` |
| Private B | `10.30.1.0/24` | `eu-west-2b` |

Both subnets are configured with:

`map_public_ip_on_launch = false`

This prevents automatic public IPv4 assignment for instances launched into these subnets.

### 5.3 Private Route Tables

Each private subnet has its own route table.

| Destination | Target |
|---|---|
| `10.30.0.0/16` | Local |
| `10.10.0.0/24` | Transit Gateway |

No default route to an Internet Gateway or NAT Gateway is configured.

Consequently, workloads do not have general internet egress through the current VPC routing configuration.

### 5.4 Hybrid Routing

Traffic destined for the on-premises LAN is routed through the Transit Gateway.

The Network account maintains Transit Gateway routes towards the Site-to-Site VPN attachment.

On-premises return routing must direct AWS-bound traffic through the strongSwan gateway.

The presence of routes alone does not establish connectivity; IPsec, firewall and workload permissions must also be functional.

## 6. Security Group Strategy

### 6.1 Default Security Group

The Terraform-managed default security group is configured without ingress or egress rules.

This prevents the default security group from providing unrestricted connectivity.

Workloads must use explicitly defined security groups appropriate to their function.

### 6.2 Application Security Group

A dedicated application security group will be created during workload deployment.

Planned controls include:

- Allow only required application ports.
- Restrict sources to approved on-premises networks or designated internal components.
- Avoid unrestricted administrative access.
- Permit outbound connections required by the application.
- Use Systems Manager where feasible for administrative access.

The final ports and rules must match the deployed application architecture.

### 6.3 Database Security Group

A dedicated PostgreSQL security group will be created during database deployment.

Planned controls include:

- Permit TCP 5432 only from approved application components and authorised migration sources.
- Deny direct public exposure.
- Restrict administrative connectivity.
- Apply least-privilege outbound access where appropriate.

Database network access must be validated independently of database authentication and authorisation.

## 7. Network ACL Strategy

Use the VPC's default Network ACL during initial deployment unless testing identifies a requirement for additional subnet-level controls.

Security groups are stateful, while Network ACLs are stateless.

Custom Network ACL rules must explicitly account for required return traffic, including ephemeral ports.

Additional Network ACL restrictions should only be introduced when they provide a justified security benefit.

## 8. Private Access to AWS Services

Private subnets without internet egress may need access to AWS services for:

- Systems Manager
- Secrets Manager
- CloudWatch Logs
- Amazon ECR
- Amazon S3
- AWS Backup or other operational services

VPC endpoints will be evaluated and deployed according to actual workload requirements.

Interface endpoints may introduce additional hourly and data-processing charges.

Required endpoints depend on the selected application hosting and operational architecture.

The project must not assume that private subnet workloads can reach every AWS API without an appropriate network path.

## 9. Account-Level Isolation

The Network account owns:

- Transit Gateway
- Site-to-Site VPN
- Customer Gateway
- Shared Transit Gateway routing

The Development account owns:

- Workload VPC
- Private subnets
- VPC route tables
- Application and database migration targets

AWS RAM permits controlled sharing of the Transit Gateway.

Account-level separation reduces the potential blast radius of workload changes, but it does not replace IAM permissions, security groups or network policy controls.

## 10. Availability and Resilience

The two private subnets occupy separate Availability Zones.

This supports future multi-AZ workload deployment.

However, multiple subnets alone do not guarantee:

- Application high availability
- Database replication
- Automatic failover
- Disaster recovery
- Elimination of single points of failure

These capabilities require additional workload-specific design and testing.

## 11. Consequences

### Positive

- Reduced internet-facing attack surface
- Separation of network and workload responsibilities
- Explicit hybrid network routing
- Foundation for least-privilege security groups
- Support for future multi-AZ application deployments
- No unnecessary NAT Gateway in the initial deployment

### Negative

- Additional connectivity requirements for AWS service APIs
- Dependence on Transit Gateway and VPN routing
- More complex private workload administration
- Additional endpoint or egress costs when introduced
- Security controls require coordination across multiple layers

## 12. Implementation Status

**Completed**

- Created Development VPC with `10.30.0.0/16`
- Created two private subnets across two Availability Zones
- Disabled automatic public IP assignment
- Created dedicated private route tables
- Configured routes to the on-premises LAN through Transit Gateway
- Restricted the default security group
- Created and accepted the cross-account Transit Gateway attachment

**Pending**

- Deploy workload-specific security groups
- Deploy application and database migration destinations
- Evaluate and configure required VPC endpoints
- Establish IPsec connectivity
- Validate end-to-end traffic restrictions
- Enable appropriate operational logging and monitoring

## 13. Validation Criteria

The design will be validated through:

1. Verification of VPC and subnet CIDR ranges.
2. Confirmation of subnet Availability Zone placement.
3. Inspection of effective route-table entries.
4. Verification that private workloads receive no public IPv4 addresses.
5. Review of security group ingress and egress rules.
6. Controlled connectivity tests from approved on-premises sources.
7. Negative tests demonstrating that unauthorised traffic is blocked.
8. Verification of required private AWS service connectivity.

## 14. References

- [AWS VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [VPC Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html)
- [VPC Route Tables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html)
- [VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)
- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
