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
