resource "cloudflare_zone" "guili2025_fr" {
  account = {
    id = var.account_id
  }
  name = "guili2025.fr"
  type = "full"
}