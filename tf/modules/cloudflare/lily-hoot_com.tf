resource "cloudflare_zone" "lily-hoot_com" {
  account = {
    id = var.account_id
  }
  name = "lily-hoot.com"
  type = "full"
}