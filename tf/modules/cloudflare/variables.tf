# Cloudflare module variables

variable "account_id" {
  description = "The Cloudflare account ID"
  type        = string
}

variable "hetzner_server_name" {
  description = "The server name from Hetzner module"
  type        = string
}

variable "hetzner_server_ipv4" {
  description = "The primary IPv4 address from Hetzner module"
  type        = string
}

# Add more variables as needed for Cloudflare configuration
