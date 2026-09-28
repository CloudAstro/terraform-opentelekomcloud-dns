output "dns_zone_v2" {
  value       = opentelekomcloud_dns_zone_v2.dns_zone_v2
  description = "Primary zone object, including id, name, type, ttl and masters."
}

output "recordsets" {
  value       = opentelekomcloud_dns_recordset_v2.dns_recordset_v2
  description = "Primary record set objects keyed by the recordsets input keys."
}

output "ptr_records" {
  value       = opentelekomcloud_dns_ptrrecord_v2.dns_ptrrecord_v2
  description = "PTR record objects keyed by the ptr_records input keys, including address and region:EIP ID."
}

output "peer_dns_zone_v2" {
  value       = try(opentelekomcloud_dns_zone_v2.dns_zone_v2_peer["this"], null)
  description = "Separate peer zone object, or null when peer_routers is empty."
}

output "peer_recordsets" {
  value       = opentelekomcloud_dns_recordset_v2.dns_recordset_v2_peer
  description = "Peer record set objects keyed by the recordsets input keys; empty when there is no peer zone."
}
