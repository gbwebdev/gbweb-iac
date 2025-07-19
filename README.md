# gbweb-iac

Infrastructure as Code for GBweb.fr (Internet facing infra)

## 🚀 Overview

This repository contains the complete infrastructure setup for GBweb.fr using OpenTofu (Terraform) with a streamlined Makefile-based workflow. It provides secure, environment-specific infrastructure management with encrypted state files and automated secrets handling.

## ✨ Features

- **🌐 Multi-environment support** (production, staging, development)
- **🔐 Encrypted state files** with GPG encryption
- **🔑 Secure secrets management** per environment
- **🛠️ Flexible OpenTofu command runner** for any tofu operation
- **📝 Shell autocompletion** for bash and zsh
- **⚡ Environment variable support** for streamlined workflows

## 📁 Project Structure

```
gbweb-iac/
├── README.md                    # This file
├── scripts/
│   └── tfstate-crypto.sh       # State file encryption/decryption
└── tf/                         # Terraform/OpenTofu configuration
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
    │   └── production.secrets.tfvars  # Production secrets (encrypted)
    ├── terraform.tfstate.d/   # Workspace state files (encrypted)
    └── completion/            # Shell autocompletion scripts
        ├── install.sh         # Autocompletion installer
        ├── make-completion.bash  # Bash completion
        ├── _make-terraform    # Zsh completion
        └── README.md          # Completion documentation
```

## 🚀 Quick Start

### 1. Setup Environment

```bash
cd tf

# Option 1: Use environment variable (recommended for daily use)
export TERRAFORM_ENV=production

# Option 2: Use command line parameter
# make <command> ENV=production
```

### 2. Install Shell Completion (Optional but Recommended)

```bash
cd tf/completion
./install.sh  # Auto-detects your shell (bash/zsh)
```

### 3. Initialize Infrastructure

```bash
# Create configuration files from templates
make setup-secrets
make setup-variables

# Edit your environment-specific configuration
make edit-secrets     # Edit secrets (uses $TERRAFORM_ENV or specify ENV=)
make edit-variables   # Edit variables

# Initialize and deploy
make decrypt-states   # Decrypt state files (after git pull)
make init            # Initialize Terraform
make plan            # Review planned changes
make apply           # Apply changes
make encrypt-states  # Encrypt state files (before git push)
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
| `make init` | Initialize Terraform for environment |
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

### State File Management

| Command | Description |
|---------|-------------|
| `make encrypt-states` | Encrypt all .tfstate files to .tfstate.gpg |
| `make decrypt-states` | Decrypt all .tfstate.gpg files to .tfstate |
| `make cleanup-states` | Remove plaintext .tfstate files (keep encrypted) |
| `make check-states` | Check encryption status of state files |

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
| `make fmt` | Format Terraform files |
| `make validate` | Validate Terraform configuration |

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
make decrypt-states
make plan  # Review changes carefully
make apply
make encrypt-states
```

## 🔐 Security Features

### Encrypted State Files

- All `.tfstate` files are automatically encrypted with GPG
- Only encrypted `.tfstate.gpg` files are committed to git
- Use `make decrypt-states` after `git pull`
- Use `make encrypt-states` before `git push`

### Secrets Management

- Environment-specific secrets in `tfvars/*.secrets.tfvars`
- Secrets files are in `.gitignore` and never committed
- Templates provided for easy setup
- Automatic validation ensures secrets exist before operations

## 🖥️ Shell Completion

The project includes intelligent shell completion for both bash and zsh:

### Features
- ✅ Complete all Makefile targets
- ✅ Complete environment names (`production`, `staging`, `development`)
- ✅ Complete OpenTofu subcommands for `make tofu`
- ✅ Context-aware completion (knows when to suggest `ENV=`)

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
- **Never** commit `.tfstate` files or secrets
- **Always** review `make plan` output before `make apply`
- Use `make tofu plan -destroy` to preview destroy operations
- Keep encrypted state files (`*.tfstate.gpg`) in version control

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
