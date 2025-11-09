# gbweb-iac

Infrastructure as Code for GBweb.fr (Internet facing infra)

## 🚀 Overview

This repository contains the complete infrastructure setup for GBweb.fr using OpenTofu (Terraform) with a streamlined Makefile-based workflow. It provides secure, environment-specific infrastructure management with SOPS-encrypted state files and automated secrets handling.

## ✨ Features

- **🌐 Multi-environment support** (production, staging, development)
- **🔑 Secure secrets management** with SOPS encryption
- **🔒 Encrypted state files** using OpenTofu's native SOPS integration
- **🛠️ Flexible OpenTofu command runner** for any tofu operation
- **📝 Shell autocompletion** for bash and zsh
- **⚡ Environment variable support** for streamlined workflows

## Prerequisites

- **OpenTofu** (not Terraform) - Required for SOPS encryption support
- **SOPS** - For state file and secrets encryption
- **Pre-commit** - For automated checks to prevent pushing unencrypted files

## 📁 Project Structure

```
gbweb-iac/
├── README.md                    # This file
└── tf/                         # OpenTofu configuration
    ├── main.tf                 # Main infrastructure configuration
    ├── variables.tf            # Variable definitions
    ├── outputs.tf              # Output definitions
    ├── Makefile               # Enhanced workflow automation
    ├── modules/               # Reusable modules
    │   ├── cloudflare/        # Cloudflare DNS configuration
    │   └── hetzner/           # Hetzner Cloud configuration
    ├── tfvars/                # Environment-specific variables
    │   ├── _.tfvars.example   # Variables template
    │   ├── _secrets.tfvars.example  # Secrets template
    │   ├── production.tfvars  # Production variables
    │   └── production.secrets.tfvars  # Production secrets (SOPS encrypted)
    ├── terraform.tfstate.d/   # Workspace state files (SOPS encrypted)
    └── completion/            # Shell autocompletion scripts
        ├── install.sh         # Autocompletion installer
        ├── make-completion.bash  # Bash completion
        ├── _make-terraform    # Zsh completion
        └── README.md          # Completion documentation
```

## 🚀 Quick Start

### 1. Setup SOPS Encryption

Ensure SOPS is configured with your preferred key management system (Age, PGP, AWS KMS, etc.).

### 2. Setup Environment Variables

```bash
# Option 1: Use environment variable (recommended for daily use)
export TERRAFORM_ENV=production

# Option 2: Use command line parameter
# make <command> ENV=production
```

### 3. Install Shell Completion (Optional but Recommended)

```bash
cd tf/completion
./install.sh  # Auto-detects your shell (bash/zsh)
```

### 4. Initialize Infrastructure

```bash
# Create configuration files from templates
make setup-secrets
make setup-variables

# Edit your environment-specific configuration
make edit-secrets     # Edit secrets (uses $TERRAFORM_ENV or specify ENV=)
make edit-variables   # Edit variables

# Initialize and deploy
make init            # Initialize OpenTofu
make plan            # Review planned changes
make apply           # Apply changes
```

## 🔧 Available Commands

### Environment Configuration

You can specify the environment in two ways:

1. **Environment variable** (recommended):
   ```bash
   export TERRAFORM_ENV=production
   make plan  # Uses production environment
   ```

2. **Command line parameter**:
   ```bash
   make plan ENV=production
   ```

### Main Commands

| Command | Description |
|---------|-------------|
| `make help` | Show comprehensive help with all commands |
| `make init` | Initialize OpenTofu for environment |
| `make plan` | Plan infrastructure changes |
| `make apply` | Apply infrastructure changes |
| `make destroy` | Destroy infrastructure |
| `make tofu <args>` | Run any tofu command with proper setup |

### Secrets & Variables Management

| Command | Description |
|---------|-------------|
| `make setup-secrets` | Create all missing secrets files from templates |
| `make edit-secrets` | Edit secrets for specific environment |
| `make check-secrets` | Check if secrets exist for environment |
| `make setup-variables` | Create all missing variables files from templates |
| `make edit-variables` | Edit variables for specific environment |
| `make check-variables` | Check if variables exist for environment |

### Workspace Management

| Command | Description |
|---------|-------------|
| `make workspace-list` | List all workspaces |
| `make workspace-new` | Create new workspace |
| `make workspace-select` | Select workspace |
| `make workspace-current` | Show current workspace |

### Code Quality

| Command | Description |
|---------|-------------|
| `make fmt` | Format OpenTofu files |
| `make validate` | Validate OpenTofu configuration |

## 🔥 Advanced Usage

### Flexible OpenTofu Commands

The `make tofu` command allows you to run any OpenTofu command with automatic environment setup:

```bash
# Show current state
make tofu show

# Show outputs
make tofu output

# Import existing resources
make tofu import aws_instance.example i-1234567890abcdef0

# Advanced state management
make tofu state list
make tofu state show aws_instance.example
make tofu state mv aws_instance.old aws_instance.new

# Plan with specific targets
make tofu plan -target=module.cloudflare

# Apply with auto-approval (use with caution!)
make tofu apply -auto-approve
```

### Environment-Specific Workflows

```bash
# Development workflow
export TERRAFORM_ENV=development
make setup-secrets && make setup-variables
make edit-secrets && make edit-variables
make init && make plan && make apply

# Production deployment
export TERRAFORM_ENV=production
make plan  # Review changes carefully
make apply
```

## 🔐 Security Features

### SOPS Encryption

- All state files and secrets are encrypted using SOPS
- OpenTofu natively supports SOPS encryption without manual steps
- Files are automatically encrypted/decrypted during operations
- Use your preferred SOPS key management (Age, PGP, AWS KMS, etc.)

### Secrets Management

- Environment-specific secrets in `tfvars/*.secrets.tfvars`
- All secrets files are SOPS encrypted
- Templates provided for easy setup
- Automatic validation ensures secrets exist before operations

## 🔄 Typical Workflows

### First Time Setup

```bash
export TERRAFORM_ENV=production
make setup-secrets && make setup-variables
make edit-secrets && make edit-variables
make init && make plan && make apply
```

### Daily Development

```bash
export TERRAFORM_ENV=development
make plan
make apply
```

### Production Deployment

```bash
export TERRAFORM_ENV=production
make plan  # Carefully review all changes
make apply
git add . && git commit -m "Deploy to production" && git push
```

## 🚨 Important Notes

- **OpenTofu Required**: SOPS encryption requires OpenTofu, not standard Terraform
- **SOPS Setup**: Ensure SOPS is properly configured with your key management
- **Always** review `make plan` output before `make apply`
- All sensitive files are automatically SOPS encrypted
- Pre-commit hooks prevent committing unencrypted sensitive files

## 📚 Documentation

- Run `make help` for complete command reference
- See `tf/completion/README.md` for autocompletion details
- Check individual module documentation in `tf/modules/*/README.md`

## 🤝 Contributing

1. Create feature branch
2. Test changes in development environment
3. Update documentation if needed
4. Ensure all state files are encrypted before committing
5. Submit pull request

## 📄 License

See `tf/LICENSE` for license information.
### Installation
```bash
cd tf/completion
./install.sh  # Auto-detects bash or zsh
```

### Examples
```bash
make <TAB>                    # Shows all available targets
make init ENV=<TAB>           # Completes environment names
make tofu <TAB>               # Shows OpenTofu subcommands
make tofu show ENV=<TAB>      # Completes environments for tofu command
```

## 🔄 Typical Workflows

### First Time Setup (Primary Machine)

```bash
export TERRAFORM_ENV=production
make setup-encryption    # Creates new GPG key (confirms first)
make export-key          # Export for other machines
make setup-secrets && make setup-variables
make edit-secrets && make edit-variables
make init && make plan && make apply
make encrypt-states
```

### New Machine Setup

```bash
# 1. Securely copy these files from primary machine:
#    - .terraform-state-passphrase
#    - .terraform-state-key.asc
# 2. Import the key:
make import-key
# 3. Ready to use normally:
export TERRAFORM_ENV=production
make decrypt-states
make plan && make apply
make encrypt-states
```

### Daily Development

```bash
export TERRAFORM_ENV=development
make decrypt-states
make plan
make apply
make encrypt-states
```

### Production Deployment

```bash
export TERRAFORM_ENV=production
make decrypt-states
make plan  # Carefully review all changes
make apply
make encrypt-states
git add . && git commit -m "Deploy to production" && git push
```

### Emergency Operations

```bash
# Quick state inspection
make tofu show ENV=production

# Emergency rollback (if supported by resources)
make tofu plan -destroy ENV=production
make tofu destroy ENV=production  # Use with extreme caution!
```

## 🛠️ Development

### Adding New Environments

1. Add the environment name to relevant Makefile loops
2. Create tfvars files: `make setup-secrets && make setup-variables`
3. Edit configuration: `make edit-secrets ENV=newenv && make edit-variables ENV=newenv`
4. Initialize: `make init ENV=newenv`

### Module Development

- Modules are located in `tf/modules/`
- Each module should have its own `main.tf`, `variables.tf`, and `outputs.tf`
- Test modules in development environment first

## 🚨 Important Notes

- **Always** run `make encrypt-states` before committing
- **Never** commit `.tfstate` files, secrets, or encryption keys
- **Always** review `make plan` output before `make apply`
- Use `make tofu plan -destroy` to preview destroy operations
- Keep encrypted state files (`*.tfstate.gpg`) in version control
- **Securely backup** your `.terraform-state-passphrase` and `.terraform-state-key.asc` files
- When setting up on multiple machines, securely transfer the encryption files (use scp, encrypted email, etc.)

## 📚 Documentation

- Run `make help` for complete command reference
- See `tf/completion/README.md` for autocompletion details
- Check individual module documentation in `tf/modules/*/README.md`

## 🤝 Contributing

1. Create feature branch
2. Test changes in development environment
3. Update documentation if needed
4. Ensure all state files are encrypted before committing
5. Submit pull request

## 📄 License

See `tf/LICENSE` for license information.
