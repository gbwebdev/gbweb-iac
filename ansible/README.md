# Ansible Infrastructure Management

This directory contains Ansible configuration for managing your Hetzner VPS infrastructure. The setup includes automated Python environment management, SOPS-encrypted secrets handling, and simplified operations through a comprehensive Makefile.

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Create Python virtual environment and install Ansible + SOPS
make venv-create

# Configure SOPS (if not already done)
# Set up your GPG key or cloud KMS for SOPS encryption
```

### 2. Test Connection

```bash
# Test connection to your servers
make ping
```

## 📁 Project Structure

```
ansible/
├── Makefile                       # Main automation and task runner
├── inventory.yml                 # Static server inventory (FQDN-based)
├── group_vars/all/secrets.yml    # SOPS-encrypted secrets
├── .sops.yaml                    # SOPS configuration (optional)
├── venv/                         # Python virtual environment (auto-created)
└── README.md                     # This file
```

## 🐍 Python Environment Management

The Makefile **requires** a Python virtual environment - no system fallback:

### Commands
- `make venv-create` - Create virtual environment with Ansible and community.sops
- `make venv-check` - Check virtual environment status
- **All Ansible commands require the venv to exist**

### Features
- ✅ **Mandatory venv**: All commands fail if venv doesn't exist
- ✅ **Simple setup**: One command creates everything needed
- ✅ **SOPS Integration**: Installs community.sops collection automatically
- ✅ **No confusion**: Always uses the same Python environment
- ✅ **Clear errors**: Helpful error messages when venv is missing

### How It Works
```bash
# First time setup - REQUIRED
make venv-create

# All commands require venv to exist
make ping              # ✅ Works with venv
                      # ❌ Fails without venv

# Check if venv exists
make venv-check
```

## 🔐 SOPS Encryption Management

Secure secret management with Mozilla SOPS - **use SOPS directly, no wrapper needed**:

### Direct SOPS Commands (Recommended)
```bash
# Edit encrypted secrets
sops group_vars/all/secrets.yml

# View secrets (decrypted, read-only)
sops -d group_vars/all/secrets.yml

# Create new encrypted file
sops secrets.yml

# Encrypt existing file
sops -e -i plaintext.yml

# Decrypt to stdout
sops -d secrets.yml
```

### Why Direct SOPS?
- ✅ **KISS Principle**: No unnecessary wrapper complexity
- ✅ **Standard Commands**: Learn SOPS properly, not custom wrappers
- ✅ **Full Feature Access**: Access all SOPS options directly
- ✅ **Less Maintenance**: One less layer to maintain

### SOPS File Template
Create your first secret file:
```bash
# Create and edit in one command
sops group_vars/all/secrets.yml
```

Add this content:
```yaml
# SOPS Encrypted Variables
ssh_port: 22
# Add other secrets as needed
```

## 🎯 Inventory Configuration

### Current Setup
- **Host**: `ha-server` (ha-server.gbweb.fr)
- **User**: `ansible`
- **SSH Key**: `~/.ssh/id_rsa`
- **SOPS Variables**: SSH port from encrypted secrets

### Inventory Structure
```yaml
all:
  children:
    hetzner:
      hosts:
        ha-server:
          ansible_host: ha-server.gbweb.fr
          ansible_port: "{{ ssh_port }}"
          ansible_user: ansible
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

## 📋 Common Operations

### Connection Testing
```bash
make ping              # Test connection to all hosts
make facts             # Gather system facts
make uptime            # Check server uptime
make disk-usage        # Check disk space
make services          # Check failed systemd services
```

### Secret Management
```bash
# Direct SOPS usage (recommended)
sops group_vars/all/secrets.yml        # Edit secrets
sops -d group_vars/all/secrets.yml     # View secrets
```

### Playbook Execution
```bash
make setup             # Run setup.yml if it exists
make playbook PLAY=deploy    # Run specific playbook

# Examples
make playbook PLAY=webserver
make playbook PLAY=security-hardening
```

### Advanced Operations
```bash
make shell HOST=ha-server    # Open interactive shell
make test                    # Run ping test
make up                      # Alias for ping
make status                  # Alias for facts
```

## 🔧 Configuration Files

### .sops.yaml (Optional)
Configure SOPS encryption rules:
```yaml
creation_rules:
  - path_regex: \.secrets\.ya?ml$
    pgp: 'your-pgp-fingerprint'
  - path_regex: \.secrets\.ya?ml$
    kms: 'arn:aws:kms:region:account:key/key-id'
```

### Makefile Variables
Key configuration in the Makefile:
```makefile
INVENTORY := inventory.yml
SOPS_FILE := group_vars/all/secrets.yml
VENV_DIR := venv
PYTHON := python3
```

## 🎨 Color-Coded Output

The Makefile provides beautiful, color-coded output:
- 🟢 **Green**: Success messages and operations
- 🟡 **Yellow**: Warnings and informational messages  
- 🔴 **Red**: Errors and missing requirements
- 📘 **Blue**: Help sections and categories

## 📖 Usage Examples

### First-Time Setup
```bash
# 1. Create environment
make venv-create

# 2. Setup SOPS (choose one method)
# Option A: GPG
gpg --generate-key
export SOPS_PGP_FP="your-pgp-fingerprint"

# Option B: AWS KMS
export SOPS_KMS_ARN="arn:aws:kms:region:account:key/key-id"

# 3. Configure secrets (direct SOPS usage)
sops group_vars/all/secrets.yml
# Add: ssh_port: 2222

# 4. Test connection
make ping
```

### Daily Operations
```bash
# Check server status
make uptime
make disk-usage

# Deploy changes
make playbook PLAY=deploy

# Update secrets (direct SOPS usage)
sops production.secrets.yml
```

### Troubleshooting
```bash
# Check environment
make help                    # Shows all status info
make venv-check             # Check Python environment

# Debug connection
make facts                  # Detailed server info
make shell HOST=ha-server   # Direct server access

# Test SOPS directly
sops -d group_vars/all/secrets.yml    # View encrypted secrets
```

## 🔒 SOPS Configuration

### Encryption Methods

**GPG (Local Development)**
```bash
# Generate GPG key
gpg --generate-key

# Get fingerprint
gpg --list-secret-keys --keyid-format LONG

# Set environment variable
export SOPS_PGP_FP="your-pgp-fingerprint"
```

**AWS KMS (Production)**
```bash
# Set KMS key ARN
export SOPS_KMS_ARN="arn:aws:kms:us-east-1:123456789:key/key-id"

# Or create .sops.yaml
echo 'creation_rules:
  - kms: "arn:aws:kms:us-east-1:123456789:key/key-id"' > .sops.yaml
```

**Multiple Keys (Team Setup)**
```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.secrets\.ya?ml$
    pgp: >-
      fingerprint1,
      fingerprint2,
      fingerprint3
    kms: arn:aws:kms:region:account:key/key-id
```

### File Naming Convention
- ✅ `*.secrets.yml` - Encrypted secret files
- ✅ `group_vars/all/secrets.yml` - Default secrets
- ✅ `host_vars/hostname/secrets.yml` - Host-specific secrets
- ✅ `environments/prod.secrets.yml` - Environment secrets

## 🚨 Git Integration

### Files to Ignore
Add to `.gitignore`:
```gitignore
# Python environment
venv/
__pycache__/

# Ansible artifacts
*.retry
.ansible_async_*

# Local SOPS keys (if using files)
.sops/

# Temporary decrypted files
*.decrypted.*
```

### Files to Commit
- ✅ `Makefile`
- ✅ `inventory.yml`
- ✅ `group_vars/all/secrets.yml` (SOPS encrypted)
- ✅ `.sops.yaml` (SOPS configuration)
- ✅ Playbook files (`*.yml`)
- ✅ `README.md`

## 🆘 Troubleshooting

### Common Issues

**SOPS Problems**
```bash
# Check SOPS configuration
sops --version

# Test decryption directly
sops -d group_vars/all/secrets.yml

# Re-encrypt if needed
sops updatekeys group_vars/all/secrets.yml
```

### Getting Help

```bash
make help              # Show all available commands
make venv-check        # Environment diagnostics
sops --help           # SOPS commands
```

## 🎯 Next Steps

1. **Create Playbooks**: Add `setup.yml`, `deploy.yml`, etc.
2. **Expand Inventory**: Add more hosts as infrastructure grows
3. **Role Organization**: Create `roles/` directory for reusable components
4. **Environment Separation**: Create separate SOPS files per environment
5. **CI/CD Integration**: Use Makefile targets in automated pipelines
6. **Key Rotation**: Set up regular SOPS key rotation

## 📚 Additional Resources

- [SOPS Documentation](https://github.com/mozilla/sops)
- [community.sops Collection](https://docs.ansible.com/ansible/latest/collections/community/sops/)
- [Ansible Documentation](https://docs.ansible.com/)
- [SSH Key Management](https://docs.ansible.com/ansible/latest/user_guide/connection_details.html#ssh-key-setup)
- [Inventory Best Practices](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)

---

**Happy Automating with SOPS! 🚀🔐**