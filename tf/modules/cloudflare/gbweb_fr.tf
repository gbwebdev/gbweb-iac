resource "cloudflare_zone" "gbweb_fr" {
  account = {
    id = var.account_id
  }
  name = "gbweb.fr"
  type = "full"
}

resource "cloudflare_dns_record" "example_dns_record" {
  zone_id = cloudflare_zone.gbweb_fr.id
  name = "${var.hetzner_server_name}.${cloudflare_zone.gbweb_fr.name}"
  content = var.hetzner_server_ipv4
  ttl = 1  # With Cloudflare, a TTL of 1 means "automatic" and will use Cloudflare's default TTL.
  # We should switch to a 60s TTL one or two days before redeploying the server.
  type = "A"
  proxied = false
  comment = "Managed by Terraform"
}