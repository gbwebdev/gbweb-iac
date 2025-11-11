# Root variables for the infrastructure

# Global/Common variables

## Environment configuration
    variable "project_name" {
    description = "Name of the project (used for resource naming)"
    type        = string
    default     = "gbweb"
    }

    variable "environment" {
    description = "Environment name"
    type        = string
    default     = "dev"
    }

    variable "domain" {
    description = "Primary domain for the project"
    type        = string
    default     = "gbweb.fr"
    }

    ## Server administration variables
    variable "admin_username" {
    description = "Username for the admin user on servers"
    type        = string
    default     = "admin"
    }

    variable "ssh_allowed_ips" {
    description = "List of IP addresses/CIDR blocks allowed to access SSH on servers"
    type        = list(string)
    sensitive   = true
    default     = ["0.0.0.0/0", "::/0"]  # Default allows access from anywhere
    }

    variable "ssh_port" {
    description = "SSH port to use for servers"
    type        = number
    sensitive   = false
    default     = 22  
    }

    variable "ssh_public_keys" {
    description = "List of SSH public keys used to connect to servers"
    type        = list(string)
    default     = []
    }

    variable "ssh_key_names" {
    description = "List of names for the SSH keys (must match the number of keys, or leave empty for auto-generated names)"
    type        = list(string)
    default     = []
    }


    variable "home_ipv4" {
      description = "Home IPv4 - this is secret and proxied by Cloudflare"
      type        = string
      sensitive   = true
    }

    variable "home_ipv6_range" {
      description = "Home IPv6 range - this is secret and used for firewalling"
      type        = string
      sensitive   = true
    }

variable "home_server_ipv6" {
  description = "Home IPv6 - this is secret and proxied by Cloudflare"
  type        = string
  sensitive   = true
}

variable "extra_trusted_cidrs" {
  description = "Additional trusted CIDR blocks (work, friends, etc.)"
  type        = list(string)
  default     = []
  sensitive   = true
}

# Hetzner Cloud specific variables

variable "hetzner_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "hetzner_server_name" {
  description = "Name of the Hetzner server"
  type        = string
  default     = "gbweb-vps"
}

variable "hetzner_server_image" {
  description = "Hetzner server image to use"
  type        = string
  default     = "ubuntu-24.04"
}

variable "hetzner_server_type" {
  description = "Hetzner server type (size)"
  type        = string
  default     = "cx11"  # 1 vCPU, 2GB RAM
}

variable "hetzner_server_location" {
  description = "Hetzner server location"
  type        = string
  default     = "nbg1"  # Nuremberg
}

variable "hetzner_data_volume_size" {
  description = "Size of the Hetzner data volume in GB"
  type        = number
  default     = 10
}

variable "hetzner_enable_secondary_ipv4" {
  description = "Create a secondary IPv4 floating IP for Hetzner server"
  type        = bool
  default     = false
}

variable "hetzner_enable_secondary_ipv6" {
  description = "Create a secondary IPv6 floating IP for Hetzner server"
  type        = bool
  default     = false
}


variable "ionos_gateway_name" {
  description = "Name of the IONOS gateway VPS"
  type        = string
  default     = "ionos-gateway"
}

variable "ionos_gateway_ipv4" {
  description = "IPv4 address of the IONOS gateway VPS"
  type        = string
  default     = ""
}

variable "ionos_gateway_ipv6" {
  description = "IPv6 address of the IONOS gateway VPS"
  type        = string
  default     = ""
}

# Cloudflare specific variables
variable "cloudflare_api_token" {
  description = "Cloudflare API token for managing DNS and other services"
  type        = string
  sensitive   = true
}

# Cloudflare specific variables
variable "cloudflare_account_id" {
  description = "Cloudflare account ID for managing DNS and other services"
  type        = string
  sensitive   = true
}

