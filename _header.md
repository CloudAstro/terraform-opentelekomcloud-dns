# OpenTelekomCloud DNS Terraform Module

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![Apache V2 License](https://img.shields.io/badge/license-Apache%20V2-orange.svg)](LICENSE)

This module manages an OTC public or private DNS zone, its record sets and
optional EIP reverse DNS records. It can also create a separate private zone
with matching records in a peer project.

# Features

- **Zone Management**: Public zones or private zones associated with one or more VPCs.
- **Record Sets**: Stable map keys, optional TTLs, descriptions and tags.
- **Peer Project**: Optional separate private zone and mirrored record sets through an aliased provider.
- **Reverse DNS**: PTR records for existing EIPs through the default provider.
- **Validation**: Zone names, VPC associations, record ownership and TTLs checked before deployment where inputs are known.

# Setup Requirements

Configure OTC credentials and region through supported provider environment
variables such as `OS_AUTH_URL`, `OS_USERNAME`, `OS_PASSWORD`, `OS_DOMAIN_NAME`,
`OS_PROJECT_NAME` and `OS_REGION`. The examples contain no personal project IDs,
credentials or fixed region, and have no required input variables.

Every caller must map `opentelekomcloud.peer`, including callers that do not use
`peer_routers`. In that case, map it to the default provider as shown below.

# Example Usage

The [default example](examples/default/main.tf) creates a public example zone
and one A record. The [full example](examples/full/main.tf) creates a VPC, a
private zone, several record types and an EIP with a PTR record:
