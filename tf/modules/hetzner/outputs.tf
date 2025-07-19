# Output values for the Hetzner Cloud VPS module

output "server_id" {
  description = "ID of the created server"
  value       = hcloud_server.web_server.id
}

output "server_name" {
  description = "Name of the created server"
  value       = hcloud_server.web_server.name
}

output "server_status" {
  description = "Status of the server"
  value       = hcloud_server.web_server.status
}

output "ssh_key_ids" {
  description = "IDs of the SSH keys"
  value       = hcloud_ssh_key.ssh_keys[*].id
}

output "firewall_id" {
  description = "ID of the firewall"
  value       = hcloud_firewall.web_firewall.id
}

output "volume_id" {
  description = "ID of the additional volume"
  value       = hcloud_volume.data_volume.id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the server"
  value       = var.ssh_port != 22 ? "ssh -p ${var.ssh_port} ${var.admin_username}@${hcloud_server.web_server.ipv4_address}" : "ssh ${var.admin_username}@${hcloud_server.web_server.ipv4_address}"
}

# IP outputs
output "primary_ipv4" {
  description = "Primary IPv4 address (vps instance dependent)"
  value       = hcloud_server.web_server.ipv4_address
}

output "primary_ipv6" {
  description = "Primary IPv6 address (vps instance dependent)"
  value       = hcloud_server.web_server.ipv6_address
}

output "primary_ipv6_network" {
  description = "Primary IPv6 network (vps instance dependent)"
  value       = hcloud_server.web_server.ipv6_network
}

output "secondary_ipv4" {
  description = "Secondary floating IPv4 address (on-demand)"
  value       = var.enable_secondary_ipv4 ? hcloud_floating_ip.secondary_ipv4[0].ip_address : null
}

output "secondary_ipv6" {
  description = "Secondary floating IPv6 address (on-demand)"
  value       = var.enable_secondary_ipv6 ? hcloud_floating_ip.secondary_ipv6[0].ip_address : null
}

output "floating_ip_summary" {
  description = "Summary of all floating IPs"
  value = {
    secondary_ipv4 = var.enable_secondary_ipv4 ? hcloud_floating_ip.secondary_ipv4[0].ip_address : "disabled"
    secondary_ipv6 = var.enable_secondary_ipv6 ? hcloud_floating_ip.secondary_ipv6[0].ip_address : "disabled"
  }
}

output "fqdn" {
  description = "Fully qualified domain name of the server"
  value       = "${var.server_name}.${var.domain}"
}