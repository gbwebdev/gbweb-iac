# OpenTofu Infrastructure

This directory contains the OpenTofu configuration for managing cloud infrastructure with SOPS encryption.

## 🏗️ Architecture Overview

The infrastructure is organized into modular components:

- **Root Configuration** (`main.tf`): Orchestrates the overall infrastructure
- **Hetzner Module** (`modules/hetzner/`): Manages Hetzner Cloud VPS, storage, networking, and security
- **Cloudflare Module** (`modules/cloudflare/`): Handles DNS and CDN configuration (currently commented out)

## 📁 Directory Structure

```text
tf/
├── main.tf                       # Root OpenTofu configuration
├── variables.tf                  # Input variables definition
├── outputs.tf                    # Output values
├── Makefile                      # Automation scripts for common tasks
├── modules/
│   ├── hetzner/                  # Hetzner Cloud infrastructure module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── cloud-init.yml.tpl
│   └── cloudflare/               # Cloudflare DNS/CDN module
├── tfvars/                       # Environment-specific variables
│   ├── _.tfvars.example          # Template for regular variables
│   ├── _secrets.tfvars.example   # Template for sensitive variables
│   ├── production.tfvars         # Production environment variables
│   └── production.secrets.tfvars # Production secrets (SOPS encrypted)
└── terraform.tfstate.d/          # Workspace-specific state files (SOPS encrypted)
```

## 🚀 Quick Start

### Prerequisites

- [OpenTofu](https://opentofu.org) >= 1.6 (required for SOPS support)
- [SOPS](https://github.com/mozilla/sops) for encryption
- [Hetzner Cloud](https://www.hetzner.com/cloud) account and API token
- SSH key pair for server access

### 1. Initial Setup

```bash
# Navigate to the tf directory
cd tf

# Set up variables and secrets from templates
make setup-variables
make setup-secrets

# Edit your environment-specific configuration
make edit-variables ENV=production
make edit-secrets ENV=production    # Will use SOPS for encryption
```

### 2. Configure Your Infrastructure

Edit the generated files in `tfvars/`:

**production.tfvars**:

```hcl
project_name = "your-project"
environment  = "production"
domain       = "yourdomain.com"
hetzner_server_name = "web-server"
hetzner_server_type = "cx22"
hetzner_data_volume_size = 10
```

**production.secrets.tfvars** (SOPS encrypted):

```hcl
hetzner_token = "your-hetzner-api-token"
ssh_public_keys = ["ssh-ed25519 AAAAC... your-key"]
ssh_allowed_ips = ["your.ip.address/32"]
```

### 3. Deploy Infrastructure

```bash
# Initialize OpenTofu
make init ENV=production

# Review the planned changes
make plan ENV=production

# Apply the configuration
make apply ENV=production
```

## 🔐 Security Features

### SOPS Encryption

- All state files and secrets are automatically encrypted with SOPS
- OpenTofu handles encryption/decryption transparently
- No manual encryption/decryption steps required
- Configure SOPS with your preferred key management system

### Access Control

- SSH access restricted to specified IP addresses
- Configurable SSH port
- Firewall rules for web traffic (HTTPS)

### Secrets Management

- Sensitive variables stored in SOPS-encrypted `.secrets.tfvars` files
- Templates provided for easy setup
- Automatic encryption when editing secrets

## 🌍 Multi-Environment Support

The infrastructure supports multiple environments through OpenTofu workspaces:

```bash
# Create a new environment
tofu workspace new staging

# Deploy to staging
make init ENV=staging
make apply ENV=staging
```

Each environment has its own:

- Variable files (`<env>.tfvars`, `<env>.secrets.tfvars`)
- State files (in `terraform.tfstate.d/<env>/`, SOPS encrypted)
- Resource naming (includes workspace suffix)

## ⚠️ Important Notes

1. **OpenTofu Required**: SOPS encryption requires OpenTofu, not standard Terraform
2. **SOPS Configuration**: Ensure SOPS is properly configured with your encryption keys
3. **API Tokens**: Keep your Hetzner API token secure and rotate it regularly
4. **SSH Access**: Restrict SSH access to known IP addresses only
5. **Cost Monitoring**: Monitor your Hetzner Cloud usage to avoid unexpected charges

## 🐛 Troubleshooting

### Common Issues

**SOPS Configuration**:
```bash
# Verify SOPS is properly configured
sops --version
sops -e /dev/null  # Test encryption setup
```

**State Lock Error**:
```bash
# If state is locked, check and remove if necessary
tofu force-unlock <lock-id>
```

**Provider Authentication**:
```bash
# Verify your Hetzner token is correct
export HCLOUD_TOKEN="your-token"
hcloud server list
```

For more detailed troubleshooting, check the OpenTofu and provider documentation.
