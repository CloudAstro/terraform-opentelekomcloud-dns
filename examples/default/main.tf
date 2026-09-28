module "dns" {
  source = "../.."

  providers = {
    opentelekomcloud      = opentelekomcloud
    opentelekomcloud.peer = opentelekomcloud
  }

  # Reserved example domain and documentation address; no public delegation.
  name  = "example.com."
  email = "admin@example.com"
  type  = "public"

  recordsets = {
    www = {
      name    = "www.example.com."
      type    = "A"
      ttl     = 300
      records = ["192.0.2.10"]
    }
  }
}
