# Root outputs for the infrastructure

# Hetzner outputs
output "hetzner_server_id" {
  description = "ID of the Hetzner server"
  value       = module.hetzner.server_id
}

output "hetzner_server_name" {
  description = "Name of the Hetzner server"
  value       = module.hetzner.server_name
}

output "hetzner_server_status" {
  description = "Status of the Hetzner server"
  value       = module.hetzner.server_status
}

output "hetzner_ssh_key_ids" {
  description = "IDs of the SSH keys"
  value       = module.hetzner.ssh_key_ids
}

output "hetzner_firewall_id" {
  description = "ID of the firewall"
  value       = module.hetzner.firewall_id
}

output "hetzner_volume_id" {
  description = "ID of the additional volume"
  value       = module.hetzner.volume_id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the server"
  value       = module.hetzner.ssh_connection_command
}

# IP outputs
output "primary_ipv4" {
  description = "Primary IPv4 address (vps instance dependent)"
  value       = module.hetzner.primary_ipv4
}

output "primary_ipv6" {
  description = "Primary IPv6 address (vps instance dependent)"
  value       = module.hetzner.primary_ipv6
}

output "primary_ipv6_network" {
  description = "Primary IPv6 network (vps instance dependent)"
  value       = module.hetzner.primary_ipv6_network
}

output "secondary_ipv4" {
  description = "Secondary floating IPv4 address (on-demand)"
  value       = module.hetzner.secondary_ipv4
}

output "secondary_ipv6" {
  description = "Secondary floating IPv6 address (on-demand)"
  value       = module.hetzner.secondary_ipv6
}

output "floating_ip_summary" {
  description = "Summary of all floating IPs"
  value       = module.hetzner.floating_ip_summary
}

# Future modules outputs can be added here
# output "cloudflare_zone_id" {
#   description = "Cloudflare zone ID"
#   value       = module.cloudflare.zone_id
# }
