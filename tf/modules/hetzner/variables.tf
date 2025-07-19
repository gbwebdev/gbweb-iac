# Variables for Hetzner Cloud VPS module

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "server_name" {
  description = "Name of the server"
  type        = string
}

variable "domain" {
  description = "Domain for the server"
  type        = string
}

variable "server_image" {
  description = "Server image to use"
  type        = string
  default     = "ubuntu-24.04"
}

variable "server_type" {
  description = "Server type (size)"
  type        = string
  default     = "cx11"  # 1 vCPU, 2GB RAM
}

variable "server_location" {
  description = "Server location"
  type        = string
  default     = "nbg1"  # Nuremberg
}

variable "admin_username" {
  description = "Username for the admin user"
  type        = string
  default     = "admin"
}

variable "ssh_public_keys" {
  description = "List of SSH public keys to add to the server"
  type        = list(string)
}

variable "ssh_key_names" {
  description = "List of names for the SSH keys (must match the number of keys, or leave empty for auto-generated names)"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "data_volume_size" {
  description = "Size of the data volume in GB"
  type        = number
  default     = 10
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses/CIDR blocks allowed to access SSH"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "ssh_port" {
  description = "SSH port to use for the server"
  type        = number
  default     = 22  
}

variable "enable_secondary_ipv4" {
  description = "Create a secondary IPv4 floating IP (on-demand)"
  type        = bool
  default     = false
}

variable "enable_secondary_ipv6" {
  description = "Create a secondary IPv6 floating IP (on-demand)"
  type        = bool
  default     = false
}
