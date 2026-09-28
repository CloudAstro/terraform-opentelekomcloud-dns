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
