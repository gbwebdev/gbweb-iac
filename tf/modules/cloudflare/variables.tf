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

variable "home_ipv4" {
  description = "Home IPv4 - this is secret and proxied by Cloudflare"
  type        = string
  sensitive   = true
}

variable "home_server_ipv6" {
  description = "Home server IPv6 - this is secret and proxied by Cloudflare"
  type        = string
  sensitive   = true
}

variable "trusted_cidrs" {
  description = "List of trusted CIDR blocks for security"
  type        = list(string)
  sensitive   = true
}

# Add more variables as needed for Cloudflare configuration
