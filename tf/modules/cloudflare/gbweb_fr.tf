resource "cloudflare_zone" "gbweb_fr" {
  account = {
    id = var.account_id
  }
  name = "gbweb.fr"
  type = "full"
}

resource "cloudflare_dns_record" "hetzner_ha_server_a_record" {
  zone_id = cloudflare_zone.gbweb_fr.id
  name = "${var.hetzner_server_name}.${cloudflare_zone.gbweb_fr.name}"
  content = var.hetzner_server_ipv4
  ttl = 1 # Default Cloudflare TTL
  # We should switch to a 60s TTL one or two days before redeploying the server.
  type = "A"
  proxied = false
  comment = "Managed by Terraform"
}

resource "cloudflare_dns_record" "home_a_record" {
  zone_id = cloudflare_zone.gbweb_fr.id
  type = "A"
  name = "home.${cloudflare_zone.gbweb_fr.name}"
  content = var.home_ipv4
  ttl = 1 # Default Cloudflare TTL
  proxied = true
  comment = "Managed by Terraform"
}

resource "cloudflare_dns_record" "home_aaaa_record" {
  zone_id = cloudflare_zone.gbweb_fr.id
  type = "AAAA"
  name = "home.${cloudflare_zone.gbweb_fr.name}"
  content = var.home_server_ipv6
  ttl = 1 # Default Cloudflare TTL
  proxied = true
  comment = "Managed by Terraform"
}

resource "cloudflare_dns_record" "ionos_gateway_vps_a_record" {
  zone_id = cloudflare_zone.gbweb_fr.id
  name = "${var.ionos_gateway_name}.${cloudflare_zone.gbweb_fr.name}"
  content = var.ionos_gateway_ipv4
  ttl = 1 # Default Cloudflare TTL
  # We should switch to a 60s TTL one or two days before redeploying the server.
  type = "A"
  proxied = false
  comment = "Managed by Terraform"
}

resource "cloudflare_dns_record" "ionos_gateway_vps_aaaa_record" {
  zone_id = cloudflare_zone.gbweb_fr.id
  name = "${var.ionos_gateway_name}.${cloudflare_zone.gbweb_fr.name}"
  content = var.ionos_gateway_ipv6
  ttl = 1 # Default Cloudflare TTL
  # We should switch to a 60s TTL one or two days before redeploying the server.
  type = "AAAA"
  proxied = false
  comment = "Managed by Terraform"
}
