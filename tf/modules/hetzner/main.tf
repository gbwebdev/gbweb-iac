# Hetzner Cloud VPS Module
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Create SSH keys for server access
resource "hcloud_ssh_key" "ssh_keys" {
  count      = length(var.ssh_public_keys)
  name       = length(var.ssh_key_names) > 0 ? var.ssh_key_names[count.index] : "${var.project_name}-key-${count.index + 1}"
  public_key = var.ssh_public_keys[count.index]
}

# Create a firewall
resource "hcloud_firewall" "web_firewall" {
  name = "${var.project_name}-firewall"

  # SSH access
  rule {
    direction = "in"
    port      = var.ssh_port
    protocol  = "tcp"
    source_ips = var.ssh_allowed_ips
  }

  # HTTPS access
  rule {
    direction = "in"
    port      = "443"
    protocol  = "tcp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yml.tpl")
  vars = {
    admin_username = var.admin_username
    hostname        = var.server_name
    domain          = var.domain
    ssh_public_keys = jsonencode(var.ssh_public_keys)
    ssh_port        = var.ssh_port
  }
}

# Create the VPS
resource "hcloud_server" "web_server" {
  name        = var.server_name
  image       = var.server_image
  server_type = var.server_type
  location    = var.server_location
  ssh_keys    = hcloud_ssh_key.ssh_keys[*].id
  firewall_ids = [hcloud_firewall.web_firewall.id]

  # Basic server setup
  user_data = data.template_file.cloud_init.rendered

  labels = {
    environment = var.environment
    project     = var.project_name
  }
}

# Create a volume (optional)
resource "hcloud_volume" "data_volume" {
  name      = "${var.server_name}-volume"
  size      = var.data_volume_size
  location  = var.server_location
  labels = {
    environment = var.environment
    project     = var.project_name
  }
}

# Attach volume to server
resource "hcloud_volume_attachment" "data_volume_attachment" {
  volume_id = hcloud_volume.data_volume.id
  server_id = hcloud_server.web_server.id
  automount = true
}

# Reverse DNS for the server
resource "hcloud_rdns" "web_server_rdns" {
  server_id  = hcloud_server.web_server.id
  ip_address = hcloud_server.web_server.ipv4_address
  dns_ptr    = "${var.server_name}.${var.domain}"
}

# Secondary Floating IPs (on-demand, recreated when enabled)
resource "hcloud_floating_ip" "secondary_ipv4" {
  count         = var.enable_secondary_ipv4 ? 1 : 0
  type          = "ipv4"
  home_location = var.server_location
  name          = "${var.project_name}-secondary-ipv4"
  
  labels = {
    environment = var.environment
    project     = var.project_name
    type        = "secondary"
  }
}

resource "hcloud_floating_ip" "secondary_ipv6" {
  count         = var.enable_secondary_ipv6 ? 1 : 0
  type          = "ipv6"
  home_location = var.server_location
  name          = "${var.project_name}-secondary-ipv6"
  
  labels = {
    environment = var.environment
    project     = var.project_name
    type        = "secondary"
  }
}

# Assign secondary floating IPs to server (when enabled)
resource "hcloud_floating_ip_assignment" "secondary_ipv4" {
  count          = var.enable_secondary_ipv4 ? 1 : 0
  floating_ip_id = hcloud_floating_ip.secondary_ipv4[0].id
  server_id      = hcloud_server.web_server.id
}

resource "hcloud_floating_ip_assignment" "secondary_ipv6" {
  count          = var.enable_secondary_ipv6 ? 1 : 0
  floating_ip_id = hcloud_floating_ip.secondary_ipv6[0].id
  server_id      = hcloud_server.web_server.id
}
