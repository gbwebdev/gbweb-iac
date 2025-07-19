resource "cloudflare_zone" "lily-hoot_fr" {
  account = {
    id = var.account_id
  }
  name = "lily-hoot.fr"
  type = "full"
}