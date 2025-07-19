# Cloudflare module (placeholder for future implementation)
# This module will manage Cloudflare DNS and CDN configuration

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.7"
    }
  }
}


# resource "cloudflare_record" "a" {
#   zone_id = cloudflare_zone.main.id
#   name    = "@"
#   value   = var.server_ipv4
#   type    = "A"
#   ttl     = 300
# }

# resource "cloudflare_record" "www" {
#   zone_id = cloudflare_zone.main.id
#   name    = "www"
#   value   = var.domain
#   type    = "CNAME"
#   ttl     = 300
# }
