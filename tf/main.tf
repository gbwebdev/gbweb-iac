# Root Terraform configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    # ionoscloud = {
    #   source = "ionos-cloud/ionoscloud"
    #   version = ">= 6.4.10"
    # }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.7"
    }
  }
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hetzner_token
}

# # Configure the IONOS Cloud Provider
# provider "ionoscloud" {
#   token             = var.ionos_token
# }

# Configure the Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token  
}


# Local values for workspace-aware naming
locals {
  workspace_suffix = (terraform.workspace == "default" || terraform.workspace == "production") ? "" : "-${terraform.workspace}"
  server_name_with_workspace = "${var.hetzner_server_name}${local.workspace_suffix}"
  
  # Comprehensive trusted CIDR lists for security
  trusted_cidrs = concat(
    var.extra_trusted_cidrs,
    [
      "${var.home_ipv4}/32",      # Home IPv4 as single IP
      var.home_ipv6_range         # Home IPv6 range
    ]
  )
}

# Hetzner Cloud VPS Module
module "hetzner" {
  source = "./modules/hetzner"

  # Pass variables to the module
  project_name        = var.project_name
  server_name         = local.server_name_with_workspace  # Workspace-aware naming
  domain              = var.domain
  server_image        = var.hetzner_server_image
  server_type         = var.hetzner_server_type
  server_location     = var.hetzner_server_location
  admin_username      = var.admin_username
  ssh_public_keys     = var.ssh_public_keys
  ssh_key_names       = var.ssh_key_names
  environment         = var.environment
  data_volume_size    = var.hetzner_data_volume_size
  ssh_allowed_ips     = local.trusted_cidrs
  ssh_port            = var.ssh_port
  enable_secondary_ipv4 = var.hetzner_enable_secondary_ipv4
  enable_secondary_ipv6 = var.hetzner_enable_secondary_ipv6
}

module "cloudflare" {
  source = "./modules/cloudflare"
  account_id = var.cloudflare_account_id
  # Pass Hetzner module outputs
  hetzner_server_name = module.hetzner.server_name
  hetzner_server_ipv4 = module.hetzner.primary_ipv4
  # Pass home network configuration using our local values
  home_ipv4 = var.home_ipv4
  home_server_ipv6 = var.home_server_ipv6
  trusted_cidrs = local.trusted_cidrs
  ionos_gateway_name = var.ionos_gateway_name
  ionos_gateway_ipv4 = var.ionos_gateway_ipv4
  ionos_gateway_ipv6 = var.ionos_gateway_ipv6
}
