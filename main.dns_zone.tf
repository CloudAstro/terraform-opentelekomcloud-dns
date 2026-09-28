resource "opentelekomcloud_dns_zone_v2" "dns_zone_v2" {
  name        = var.name
  email       = var.email
  type        = var.type
  ttl         = var.ttl
  description = var.description
  tags        = var.tags
  value_specs = var.value_specs

  dynamic "router" {
    for_each = var.routers
    content {
      router_id     = router.value.router_id
      router_region = router.value.router_region
    }
  }
}

# A separate private zone in the peer project; this does not share the primary zone.
resource "opentelekomcloud_dns_zone_v2" "dns_zone_v2_peer" {
  for_each = length(var.peer_routers) > 0 ? { "this" = true } : {}

  provider    = opentelekomcloud.peer
  name        = var.name
  email       = var.email
  type        = var.type
  ttl         = var.ttl
  description = var.description
  tags        = var.tags
  value_specs = var.value_specs

  dynamic "router" {
    for_each = var.peer_routers
    content {
      router_id     = router.value.router_id
      router_region = router.value.router_region
    }
  }
}

resource "opentelekomcloud_dns_recordset_v2" "dns_recordset_v2" {
  for_each = var.recordsets

  zone_id     = opentelekomcloud_dns_zone_v2.dns_zone_v2.id
  name        = each.value.name
  type        = each.value.type
  ttl         = each.value.ttl
  description = each.value.description
  records     = each.value.records
  tags        = each.value.tags
  value_specs = each.value.value_specs
}

resource "opentelekomcloud_dns_recordset_v2" "dns_recordset_v2_peer" {
  for_each = length(var.peer_routers) > 0 ? var.recordsets : {}

  provider    = opentelekomcloud.peer
  zone_id     = opentelekomcloud_dns_zone_v2.dns_zone_v2_peer["this"].id
  name        = each.value.name
  type        = each.value.type
  ttl         = each.value.ttl
  description = each.value.description
  records     = each.value.records
  tags        = each.value.tags
  value_specs = each.value.value_specs
}

resource "opentelekomcloud_dns_ptrrecord_v2" "dns_ptrrecord_v2" {
  for_each = var.ptr_records

  name          = each.value.name
  floatingip_id = each.value.floatingip_id
  description   = each.value.description
  ttl           = each.value.ttl
  tags          = each.value.tags
}
