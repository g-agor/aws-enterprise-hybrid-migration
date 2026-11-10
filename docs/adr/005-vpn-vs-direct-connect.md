
# ADR-005: AWS Site-to-Site VPN versus Direct Connect

**Status:** Accepted  
**Date:** 2026-11-10  
**Project:** AWS Enterprise Hybrid Infrastructure & Migration

## 1. Context

The project requires hybrid connectivity between a physically separate on-premises VMware environment and an AWS Development VPC.

### On-premises environment

- VMware Fusion running on an Intel MacBook Pro
- Ubuntu application server: `10.10.0.10`
- PostgreSQL database server: `10.10.0.20`
- Ubuntu strongSwan VPN gateway: `10.10.0.2`
- On-premises network: `10.10.0.0/24`
- Internet connectivity through a residential router using NAT

### AWS environment

- Region: `eu-west-2` (London)
- Transit Gateway hosted in a dedicated Network account
- Development VPC: `10.30.0.0/16`
- Private workload subnets across two Availability Zones

The solution must provide private-address communication between the two environments to support application migration, database migration, validation and cutover.

The design must also consider cost, operational complexity, reliability, security and future scalability.

## 2. Decision

Use **AWS Site-to-Site VPN with IKEv2/IPsec** as the hybrid transport for the project.

Terminate the AWS VPN connection on the Transit Gateway and use strongSwan on the dedicated Ubuntu VPN gateway as the customer-side IPsec implementation.

The customer gateway operates behind a residential router with UDP 500 and UDP 4500 forwarded to the VPN VM.

Use NAT traversal (NAT-T) where required.

The initial implementation uses static routing between:

- On-premises: `10.10.0.0/24`
- AWS Development VPC: `10.30.0.0/16`

The AWS Site-to-Site VPN provides two tunnel endpoints.

Both tunnel configurations will be implemented and tested where supported by the on-premises gateway.

## 3. Alternatives Considered

### Option 1: AWS Site-to-Site VPN

**Advantages**

- Uses the existing internet connection
- Supports encrypted IPsec tunnels
- Integrates with AWS Transit Gateway
- No dedicated leased network circuit required
- Suitable for a limited-duration hybrid migration lab
- Demonstrates enterprise-relevant VPN and routing concepts

**Disadvantages**

- Dependent on public internet performance and availability
- Latency, jitter and bandwidth are less predictable
- Residential public IPv4 may change
- NAT and firewall configuration add troubleshooting complexity
- VPN connection and Transit Gateway charges continue while provisioned

**Outcome:** Selected.

### Option 2: AWS Direct Connect

**Advantages**

- Dedicated connectivity between customer networks and AWS
- More predictable network performance than ordinary internet-based VPN
- Available in multiple bandwidth and connectivity options
- Supports connectivity through a Direct Connect gateway to appropriate AWS network targets
- Suitable for sustained enterprise hybrid workloads

**Disadvantages**

- Requires physical connectivity through a Direct Connect location or connectivity provider
- Longer provisioning and operational coordination
- Port, provider and data transfer charges
- Not economically or operationally appropriate for a small residential lab
- Direct Connect traffic is not inherently IPsec-encrypted

**Outcome:** Rejected for this implementation.

### Option 3: Direct Connect with VPN Encryption

Use Direct Connect as the private transport, with IPsec VPN or another supported encryption mechanism protecting traffic as required.

**Advantages**

- Combines more predictable private transport with encrypted connectivity
- Suitable for regulated environments requiring additional confidentiality controls
- Can form part of a resilient hybrid architecture

**Disadvantages**

- Higher cost and operational complexity
- More demanding infrastructure prerequisites
- Unnecessary for the scale of this lab

**Outcome:** Not implemented; a potential enterprise extension.

### Option 4: Simulated On-Premises Environment in AWS

Host the source servers in another VPC and simulate migration across AWS networks.

**Advantages**

- Easier deployment
- No residential router or NAT dependency
- Fully cloud-based automation

**Disadvantages**

- Does not demonstrate physical separation between source and destination
- Avoids real customer-gateway and internet-based VPN configuration
- Less representative of an actual on-premises-to-cloud migration

**Outcome:** Rejected.

## 4. Selected Architecture

```text
ON-PREMISES / VMWARE FUSION

Application VM      PostgreSQL VM
10.10.0.10          10.10.0.20
       \               /
        \             /
          10.10.0.0/24
                |
       strongSwan VPN Gateway
           10.10.0.2
                |
       Residential Router / NAT
                |
           Public Internet
                |
         IKEv2 / IPsec VPN
         Tunnel 1 / Tunnel 2
                |
AWS NETWORK ACCOUNT (eu-west-2)
       AWS Site-to-Site VPN
                |
         Transit Gateway
                |
       AWS RAM Shared TGW
                |
AWS DEVELOPMENT ACCOUNT
         VPC 10.30.0.0/16
                |
      Private Application and
       Database Destinations
```

This diagram represents the intended connectivity design. The IPsec tunnels have not yet been established.

## 5. VPN Design Considerations

### 5.1 Tunnel Redundancy

AWS provisions two VPN tunnel endpoints to support redundancy.

Both tunnels must be configured and tested before claiming tunnel-level failover capability.

The presence of two AWS tunnel endpoints alone does not demonstrate successful failover.

### 5.2 NAT Traversal

The Ubuntu strongSwan gateway is behind a residential router.

UDP 500 is used for IKE negotiation, while UDP 4500 supports IPsec NAT traversal.

Correct port forwarding, firewall rules, NAT behaviour and public IP configuration are required.

### 5.3 Routing

The VPN uses static routing for the initial implementation.

AWS-side route tables are configured to forward traffic between the on-premises subnet and the Development VPC.

On-premises hosts must also have appropriate return routes through the strongSwan gateway.

### 5.4 Encryption and Secrets

IKEv2/IPsec provides encrypted communication across the public internet.

Pre-shared keys and tunnel parameters must be retrieved securely and stored outside version control.

Tunnel secrets must not appear in public GitHub documentation, screenshots or Terraform outputs.

### 5.5 Public IP Dependency

The AWS Customer Gateway references the on-premises public IPv4 address.

If the residential public address changes, VPN connectivity may fail until the customer-gateway configuration is updated.

A production design should use appropriately managed connectivity endpoints and operational monitoring.

## 6. Enterprise Production Considerations

For a production migration, the connectivity decision should be based on:

- Required migration throughput and data volume
- Available migration window
- Latency sensitivity
- Reliability and availability requirements
- Security and encryption requirements
- Existing WAN and colocation infrastructure
- Commercial lead times
- Cost of connectivity and data transfer

For sustained enterprise connectivity, Direct Connect may be preferable.

Where resilience is important, an architecture may combine Direct Connect connections with VPN backup, subject to routing and failover design.

The migration strategy should be validated against actual business requirements rather than assuming Direct Connect is always the superior option.

## 7. Consequences

### Positive

- Physically separate source and destination environments
- Real IPsec connectivity implementation
- Integration with centralised AWS networking
- Lower infrastructure commitment than Direct Connect
- Demonstrates customer gateway, NAT-T, firewall and routing concepts
- Supports end-to-end migration testing

### Negative

- Residential connectivity is not production-grade
- Public IP changes can disrupt the tunnel
- Internet performance is variable
- VPN configuration and troubleshooting may be complex
- Charges continue while AWS connectivity resources exist
- End-to-end connectivity depends on correct on-premises routing

## 8. Implementation Status

**Completed**

- Installed strongSwan on the Ubuntu VPN gateway
- Enabled IP forwarding
- Configured initial host firewall rules
- Forwarded UDP 500 and 4500 on the residential router
- Created AWS Customer Gateway
- Created AWS Site-to-Site VPN connection
- Attached the VPN to the Transit Gateway
- Created AWS-side routing infrastructure

**Pending**

- Retrieve and securely configure both AWS tunnel specifications
- Configure strongSwan connections and authentication
- Bring up the IPsec tunnels
- Verify tunnel status and negotiated security associations
- Configure and validate on-premises return routes
- Perform end-to-end application and database connectivity tests
- Test tunnel failure and recovery

## 9. Validation Criteria

The implementation will be considered successful when:

1. At least one IPsec tunnel is established.
2. strongSwan reports an established IKE security association and CHILD_SA.
3. AWS reports the corresponding tunnel as UP.
4. On-premises and AWS private IP connectivity works in both directions, subject to workload firewalls.
5. Application and database traffic can pass through the hybrid connection.
6. Traffic remains confined to the intended network paths.
7. Where both tunnels are configured, tunnel failover is tested and recorded.

## 10. References

- [AWS Site-to-Site VPN](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
- [AWS Site-to-Site VPN Tunnel Options](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPNTunnels.html)
- [AWS Direct Connect](https://docs.aws.amazon.com/directconnect/latest/UserGuide/Welcome.html)
- [AWS Direct Connect Gateway](https://docs.aws.amazon.com/directconnect/latest/UserGuide/direct-connect-gateways.html)
- [strongSwan Documentation](https://docs.strongswan.org/)
