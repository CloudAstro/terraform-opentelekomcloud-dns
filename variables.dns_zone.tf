variable "name" {
  type        = string
  nullable    = false
  description = "Zone FQDN ending in a dot, for example example.com. Changing it replaces the zone."

  validation {
    condition     = length(var.name) > 1 && endswith(var.name, ".") && length(regexall("\\s", var.name)) == 0
    error_message = "name must be a non-empty DNS zone name ending in a dot, without whitespace."
  }
}

variable "email" {
  type        = string
  default     = null
  description = "Optional contact email for the zone."
}

variable "type" {
  type        = string
  default     = "public"
  nullable    = false
  description = "Zone type: public or private. Private zones require routers. Changing it replaces the zone."

  validation {
    condition     = contains(["public", "private"], var.type)
    error_message = "type must be public or private."
  }
}

variable "ttl" {
  type        = number
  default     = null
  description = "Zone TTL in seconds. Omit to use the provider default."

  validation {
    condition     = var.ttl == null ? true : var.ttl >= 1 && var.ttl <= 2147483647 && floor(var.ttl) == var.ttl
    error_message = "ttl must be null or an integer from 1 to 2147483647."
  }
}

variable "description" {
  type        = string
  default     = null
  description = "Optional description of the zone."
}

variable "routers" {
  type = list(object({
    router_id     = string
    router_region = string
  }))
  default     = []
  nullable    = false
  description = "VPC IDs and regions to associate with the primary private zone. Required for private zones; leave empty for public zones. Explicit null is treated as an empty list."

  validation {
    condition     = var.type == "private" ? length(var.routers) > 0 : length(var.routers) == 0
    error_message = "Private zones require at least one router; public zones must not have routers."
  }

  validation {
    condition     = alltrue([for router in var.routers : try(length(trimspace(router.router_id)) > 0 && length(trimspace(router.router_region)) > 0, false)])
    error_message = "Each router must have a non-empty router_id and router_region."
  }
}

variable "peer_routers" {
  type = list(object({
    router_id     = string
    router_region = string
  }))
  default     = []
  nullable    = false
  description = <<DESCRIPTION
VPCs for an optional, separate private zone with the same name in a peer project.
The module copies recordsets into that zone; it does not share the primary zone
or establish network peering. Map opentelekomcloud.peer to the peer project.
Leave empty to omit the peer zone. Explicit null is treated as an empty list.
DESCRIPTION

  validation {
    condition     = length(var.peer_routers) == 0 || var.type == "private"
    error_message = "peer_routers is only supported for private zones."
  }

  validation {
    condition     = alltrue([for router in var.peer_routers : try(length(trimspace(router.router_id)) > 0 && length(trimspace(router.router_region)) > 0, false)])
    error_message = "Each peer router must have a non-empty router_id and router_region."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Optional tags applied to both zones."
}

variable "value_specs" {
  type        = map(string)
  default     = null
  description = "Optional additional provider options for both zones. Changing them replaces the zones."
}

variable "recordsets" {
  type = map(object({
    name        = string
    type        = string
    records     = list(string)
    ttl         = optional(number)
    description = optional(string)
    tags        = optional(map(string))
    value_specs = optional(map(string))
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Record sets keyed by stable Terraform resource keys. Names must end in a dot and
belong to the zone. Specify uppercase types (for example A, AAAA, MX, CNAME, TXT,
SRV, CAA or PTR) supported by the selected zone type. TXT values are plain text
without surrounding quotation marks. Optional TTL, description, tags and
value_specs apply to primary and peer record sets. Explicit null omits records.
DESCRIPTION

  validation {
    condition = alltrue([for record in var.recordsets : try(
      endswith(record.name, ".") && length(regexall("\\s", record.name)) == 0 &&
      (lower(record.name) == lower(var.name) || endswith(lower(record.name), ".${lower(var.name)}")), false)
    ])
    error_message = "Every record name must end in a dot, contain no whitespace and be within the zone."
  }

  validation {
    condition = alltrue([for record in var.recordsets : try(
      can(regex("^[A-Z][A-Z0-9]*$", record.type)) && length(record.records) > 0 && alltrue([for value in record.records : value != null]), false)
    ])
    error_message = "Every record set must have an uppercase DNS type and at least one non-null record value."
  }

  validation {
    condition = alltrue([for record in var.recordsets : try(record.ttl == null ? true :
      record.ttl >= 1 && record.ttl <= 2147483647 && floor(record.ttl) == record.ttl, false)
    ])
    error_message = "Record TTLs must be null or integers from 1 to 2147483647."
  }
}

variable "ptr_records" {
  type = map(object({
    name          = string
    floatingip_id = string
    description   = optional(string)
    ttl           = optional(number)
    tags          = optional(map(string))
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Reverse DNS entries keyed by stable Terraform resource keys. Each associates an
existing FloatingIP/EIP ID with a domain name, using the default provider only.
These records are independent of zone recordsets and are not copied to the peer.
TTL must be 300–2147483647 seconds when supplied. Explicit null omits PTR records.
This module always creates a primary zone, even when only PTR records are supplied.
DESCRIPTION

  validation {
    condition = alltrue([for record in var.ptr_records : try(
      length(trimspace(record.name)) > 0 && length(trimspace(record.floatingip_id)) > 0, false)
    ])
    error_message = "PTR records must contain a non-empty name and floatingip_id."
  }

  validation {
    condition = alltrue([for record in var.ptr_records : try(record.ttl == null ? true :
      record.ttl >= 300 && record.ttl <= 2147483647 && floor(record.ttl) == record.ttl, false)
    ])
    error_message = "PTR TTLs must be null or integers from 300 to 2147483647."
  }
}
