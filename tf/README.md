# Terraform Infrastructure

This directory contains the Terraform configuration for managing my cloud infrastructure.

## 🏗️ Architecture Overview

The infrastructure is organized into modular components:

- **Root Configuration** (`main.tf`): Orchestrates the overall infrastructure
- **Hetzner Module** (`modules/hetzner/`): Manages Hetzner Cloud VPS, storage, networking, and security
- **Cloudflare Module** (`modules/cloudflare/`): Handles DNS and CDN configuration (currently commented out)

## 📁 Directory Structure

```text
tf/
├── main.tf                       # Root Terraform configuration
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
│   └── production.secrets.tfvars # Production secrets (not on git)
├── terraform.tfstate.d/          # Workspace-specific state files
└── scripts/
    └── tfstate-crypto.sh         # State file encryption utilities
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://terraform.io) >= 1.0
- [Hetzner Cloud](https://www.hetzner.com/cloud) account and API token
- SSH key pair for server access
- GPG for state file encryption (optional but recommended)

### 1. Initial Setup

```bash
# Navigate to the tf directory
cd tf

# Set up state file encryption (first time or new machine)
make setup-encryption    # Creates/imports GPG key for state encryption

# Set up variables and secrets from templates
make setup-variables
make setup-secrets

# Edit your environment-specific configuration
make edit-variables ENV=production
make edit-secrets ENV=production
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

**production.secrets.tfvars**:

```hcl
hetzner_token = "your-hetzner-api-token"
ssh_public_keys = ["ssh-ed25519 AAAAC... your-key"]
ssh_allowed_ips = ["your.ip.address/32"]
```

### 3. Deploy Infrastructure

```bash
# Decrypt any existing state files (after git pull)
make decrypt-states

# Initialize Terraform
make init ENV=production

# Review the planned changes
make plan ENV=production

# Apply the configuration
make apply ENV=production

# Encrypt state files before committing
make encrypt-states
```

## 🛠️ Available Commands

The `Makefile` provides convenient commands for infrastructure management:

### Core Operations

- `make init ENV=<env>` - Initialize Terraform for an environment
- `make plan ENV=<env>` - Preview infrastructure changes
- `make apply ENV=<env>` - Apply infrastructure changes
- `make destroy ENV=<env>` - Destroy infrastructure

### Configuration Management

- `make setup-variables` - Create variable files from templates
- `make setup-secrets` - Create secret files from templates
- `make edit-variables ENV=<env>` - Edit environment variables
- `make edit-secrets ENV=<env>` - Edit environment secrets

### Security

- `make setup-encryption` - Initial setup for state encryption (creates/imports GPG key)
- `make encrypt-states` - Encrypt all state files
- `make decrypt-states` - Decrypt state files for operations
- `make cleanup-states` - Remove plaintext state files
- `make export-key` - Export GPG key for use on other machines
- `make import-key` - Import GPG key on new machine

### Validation

- `make fmt` - Format Terraform files
- `make validate` - Validate Terraform configuration

## 🔧 Infrastructure Components

### Hetzner Cloud Resources

The Hetzner module creates:

- **VPS Server**: Configurable server type and location
- **SSH Keys**: Managed SSH key deployment
- **Firewall**: Security rules for SSH, HTTP, and HTTPS
- **Additional Storage**: Optional data volume
- **Networking**: IPv4/IPv6 configuration with optional secondary IPs

### Server Configuration

- **Operating System**: Ubuntu (configurable)
- **Initial Setup**: Cloud-init for automated server configuration
- **Security**: Firewall rules, SSH key authentication
- **Storage**: Root volume + optional additional data volume

## 🔐 Security Features

### State File Encryption

- Terraform state files contain sensitive information and are automatically encrypted
- Uses portable GPG encryption with fixed key identifier (hostname independent)
- Use `make decrypt-states` after `git pull` to decrypt state files
- Use `make encrypt-states` before `git push` to encrypt state files
- Supports multi-environment setup: export key from one machine, import on others

**Multi-Machine Setup:**

```bash
# On primary machine:
make setup-encryption    # Create GPG key (asks for confirmation)
make export-key          # Export key for other machines

# On new machines (after copying key files):
make import-key          # Import existing GPG key
```

### Access Control

- SSH access restricted to specified IP addresses
- Configurable SSH port
- Firewall rules for web traffic (HTTPS)

### Secrets Management

- Sensitive variables stored in separate `.secrets.tfvars` files
- Templates provided for easy setup
- Git-ignored to prevent accidental commits

## 🌍 Multi-Environment Support

The infrastructure supports multiple environments through Terraform workspaces:

```bash
# Create a new environment
terraform workspace new staging

# Deploy to staging
make init ENV=staging
make apply ENV=staging
```

Each environment has its own:

- Variable files (`<env>.tfvars`, `<env>.secrets.tfvars`)
- State files (in `terraform.tfstate.d/<env>/`)
- Resource naming (includes workspace suffix)

## 📊 Outputs

After deployment, the following information is available:

- Server details (ID, name, status, IPs)
- SSH key IDs
- Firewall configuration
- Volume information
- Network configuration

View outputs with:

```bash
terraform output
```

## 🔄 Maintenance

### Regular Tasks

- Keep Terraform and provider versions updated
- Rotate SSH keys periodically
- Review and update firewall rules
- Monitor resource usage and costs

### Backup Strategy

- State files are backed up automatically (`.backup` files)
- Encrypt state files for secure storage
- Consider remote state backend for production

## 📚 Additional Resources

- [Hetzner Cloud API Documentation](https://docs.hetzner.cloud/)
- [Terraform Hetzner Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## ⚠️ Important Notes

1. **State Security**: Always encrypt state files before committing to version control
2. **API Tokens**: Keep your Hetzner API token secure and rotate it regularly
3. **SSH Access**: Restrict SSH access to known IP addresses only
4. **Cost Monitoring**: Monitor your Hetzner Cloud usage to avoid unexpected charges

## 🐛 Troubleshooting

### Common Issues

**State Lock Error**:

```bash
# If state is locked, check and remove if necessary
terraform force-unlock <lock-id>
```

**Provider Authentication**:

```bash
# Verify your Hetzner token is correct
export HCLOUD_TOKEN="your-token"
hcloud server list
```

**SSH Connection Issues**:

- Verify your public key is correctly configured
- Check firewall rules allow your IP address
- Ensure SSH port is correct (default: 22)

For more detailed troubleshooting, check the Terraform and provider documentation.
