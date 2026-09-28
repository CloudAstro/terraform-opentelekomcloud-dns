<!-- BEGINNING OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
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

```hcl
module "vpc" {
  source  = "CloudAstro/vpc/opentelekomcloud"
  version = "1.1.1"

  name        = "dns-example"
  description = "VPC for the private DNS example"
  cidr        = "10.42.0.0/16"
}

# Allocates a billable EIP to demonstrate reverse DNS; no server is created.
resource "opentelekomcloud_networking_floatingip_v2" "example" {}

module "dns" {
  source = "../.."

  providers = {
    opentelekomcloud      = opentelekomcloud
    opentelekomcloud.peer = opentelekomcloud
  }

  name        = "private.example.com."
  email       = "admin@example.com"
  type        = "private"
  ttl         = 300
  description = "Generic private DNS example"

  routers = [{
    router_id     = module.vpc.vpc_v1.id
    router_region = module.vpc.vpc_v1.region
  }]

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }

  recordsets = {
    www = {
      name        = "www.private.example.com."
      type        = "A"
      ttl         = 300
      description = "Illustrative web server addresses"
      records     = ["10.42.0.10", "10.42.0.11"]
      tags        = { role = "web" }
    }
    mail = {
      name    = "private.example.com."
      type    = "MX"
      ttl     = 300
      records = ["10 mail.private.example.com."]
    }
    mail_address = {
      name    = "mail.private.example.com."
      type    = "A"
      records = ["10.42.0.20"]
    }
    spf = {
      name    = "private.example.com."
      type    = "TXT"
      records = ["v=spf1 -all"]
    }
    app = {
      name    = "app.private.example.com."
      type    = "CNAME"
      records = ["www.private.example.com."]
    }
    server = {
      name    = "server01.private.example.com."
      type    = "A"
      records = [opentelekomcloud_networking_floatingip_v2.example.address]
    }
  }

  ptr_records = {
    server = {
      name          = "server01.private.example.com."
      floatingip_id = opentelekomcloud_networking_floatingip_v2.example.id
      description   = "Illustrative reverse DNS entry"
      ttl           = 300
      tags          = { environment = "example" }
    }
  }
}
```
<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12 |
| <a name="requirement_opentelekomcloud"></a> [opentelekomcloud](#requirement\_opentelekomcloud) | >= 1.36.68 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_opentelekomcloud"></a> [opentelekomcloud](#provider\_opentelekomcloud) | >= 1.36.68 |
| <a name="provider_opentelekomcloud.peer"></a> [opentelekomcloud.peer](#provider\_opentelekomcloud.peer) | >= 1.36.68 |

## Resources

| Name | Type |
|------|------|
| [opentelekomcloud_dns_ptrrecord_v2.dns_ptrrecord_v2](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_ptrrecord_v2) | resource |
| [opentelekomcloud_dns_recordset_v2.dns_recordset_v2](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_recordset_v2) | resource |
| [opentelekomcloud_dns_recordset_v2.dns_recordset_v2_peer](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_recordset_v2) | resource |
| [opentelekomcloud_dns_zone_v2.dns_zone_v2](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_zone_v2) | resource |
| [opentelekomcloud_dns_zone_v2.dns_zone_v2_peer](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_zone_v2) | resource |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Zone FQDN ending in a dot, for example example.com. Changing it replaces the zone. | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Optional description of the zone. | `string` | `null` | no |
| <a name="input_email"></a> [email](#input\_email) | Optional contact email for the zone. | `string` | `null` | no |
| <a name="input_peer_routers"></a> [peer\_routers](#input\_peer\_routers) | VPCs for an optional, separate private zone with the same name in a peer project.<br/>The module copies recordsets into that zone; it does not share the primary zone<br/>or establish network peering. Map opentelekomcloud.peer to the peer project.<br/>Leave empty to omit the peer zone. Explicit null is treated as an empty list. | <pre>list(object({<br/>    router_id     = string<br/>    router_region = string<br/>  }))</pre> | `[]` | no |
| <a name="input_ptr_records"></a> [ptr\_records](#input\_ptr\_records) | Reverse DNS entries keyed by stable Terraform resource keys. Each associates an<br/>existing FloatingIP/EIP ID with a domain name, using the default provider only.<br/>These records are independent of zone recordsets and are not copied to the peer.<br/>TTL must be 300–2147483647 seconds when supplied. Explicit null omits PTR records.<br/>This module always creates a primary zone, even when only PTR records are supplied. | <pre>map(object({<br/>    name          = string<br/>    floatingip_id = string<br/>    description   = optional(string)<br/>    ttl           = optional(number)<br/>    tags          = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_recordsets"></a> [recordsets](#input\_recordsets) | Record sets keyed by stable Terraform resource keys. Names must end in a dot and<br/>belong to the zone. Specify uppercase types (for example A, AAAA, MX, CNAME, TXT,<br/>SRV, CAA or PTR) supported by the selected zone type. TXT values are plain text<br/>without surrounding quotation marks. Optional TTL, description, tags and<br/>value\_specs apply to primary and peer record sets. Explicit null omits records. | <pre>map(object({<br/>    name        = string<br/>    type        = string<br/>    records     = list(string)<br/>    ttl         = optional(number)<br/>    description = optional(string)<br/>    tags        = optional(map(string))<br/>    value_specs = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_routers"></a> [routers](#input\_routers) | VPC IDs and regions to associate with the primary private zone. Required for private zones; leave empty for public zones. Explicit null is treated as an empty list. | <pre>list(object({<br/>    router_id     = string<br/>    router_region = string<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Optional tags applied to both zones. | `map(string)` | `null` | no |
| <a name="input_ttl"></a> [ttl](#input\_ttl) | Zone TTL in seconds. Omit to use the provider default. | `number` | `null` | no |
| <a name="input_type"></a> [type](#input\_type) | Zone type: public or private. Private zones require routers. Changing it replaces the zone. | `string` | `"public"` | no |
| <a name="input_value_specs"></a> [value\_specs](#input\_value\_specs) | Optional additional provider options for both zones. Changing them replaces the zones. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_zone_v2"></a> [dns\_zone\_v2](#output\_dns\_zone\_v2) | Primary zone object, including id, name, type, ttl and masters. |
| <a name="output_peer_dns_zone_v2"></a> [peer\_dns\_zone\_v2](#output\_peer\_dns\_zone\_v2) | Separate peer zone object, or null when peer\_routers is empty. |
| <a name="output_peer_recordsets"></a> [peer\_recordsets](#output\_peer\_recordsets) | Peer record set objects keyed by the recordsets input keys; empty when there is no peer zone. |
| <a name="output_ptr_records"></a> [ptr\_records](#output\_ptr\_records) | PTR record objects keyed by the ptr\_records input keys, including address and region:EIP ID. |
| <a name="output_recordsets"></a> [recordsets](#output\_recordsets) | Primary record set objects keyed by the recordsets input keys. |

## Modules

No modules.

## 🌐 Additional Information

- Intended public address: `CloudAstro/dns/opentelekomcloud`, published from `terraform-opentelekomcloud-dns`.
- Use `module.dns.dns_zone_v2.id` for the primary zone ID. Existing `dns_zone_v2`, `recordsets` and `ptr_records` outputs are retained.
- Run `terraform init`, `terraform plan` and `terraform apply` inside an example directory after setting your provider environment. Examples create resources in that project; the full example allocates a billable EIP. Use `terraform destroy` there to remove them.
- Example domains and IPs illustrate configuration. No servers, public delegation or end-to-end DNS checks are created. Replace the public example domain with one you control and delegate it to OTC to serve real public DNS. Private resolution requires clients to use the appropriate OTC DNS resolvers.
- The full example derives the VPC region from its provider-managed VPC. Its private forward records do not establish public forward/reverse DNS consistency for the example EIP.

## Peer Project Configuration

`peer_routers` creates a **second private zone** using `opentelekomcloud.peer`.
It does not associate VPCs across projects with the primary zone, create VPC
peering or synchronize edits made outside Terraform. Both zones receive the
same `recordsets`, zone options and tags. PTR records use the default provider only.

For this option, configure a second root provider for the peer project and map:

```hcl
providers = {
  opentelekomcloud      = opentelekomcloud
  opentelekomcloud.peer = opentelekomcloud.peer
}
```

Use `type = "private"`, supply primary VPCs in `routers` and peer-project VPCs in
`peer_routers`. Each association needs its VPC ID and region. Use a distinct peer
project to avoid managing the same zone twice. `peer_dns_zone_v2` is null and
`peer_recordsets` is empty when the peer option is unused.

## 📚 Resources

- [DNS Zone Resource](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_zone_v2)
- [DNS Record Set Resource](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_recordset_v2)
- [DNS PTR Record Resource](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_ptrrecord_v2)
- [OTC DNS API Reference](https://docs.otc.t-systems.com/domain-name-service/dns-api-ref.pdf)
- [Contributing](CONTRIBUTING.md)

## ⚠️ Notes

- Zone and record set names must end in a dot. Record names must be at the zone apex or beneath it. Record types and values must also meet the OTC API requirements for the selected zone type.
- Pass TXT values as plain text without surrounding quotation marks; the provider adds them. An omitted record TTL uses the provider default, not the module's zone TTL.
- This module always creates a primary zone. PTR records are independent of that zone, but this is not a PTR-only module.
- Import existing resources before managing them. The provider may treat a matching pre-existing record set as shared instead of managing its lifecycle; do not rely on creating a duplicate to adopt it.
- Null lists/maps are treated as empty collections. Private zones still require primary VPC associations.
- Resource addresses remain unchanged. The former peer-zone `prevent_destroy` and `ignore_changes` rules have been removed: Terraform now manages its complete configuration and can destroy it with the module. Review plans when upgrading an existing deployment.
- Generate this README with `terraform-docs .`; edit `_header.md`, `_footer.md` and Terraform descriptions. Shared workflows assume a standalone repository root. Release Please reads the configured initial version `1.0.0`.

## 🧾 License

[Apache License 2.0](LICENSE), as declared in the existing module documentation.
<!-- END OF PRE-COMMIT-OPENTOFU DOCS HOOK -->