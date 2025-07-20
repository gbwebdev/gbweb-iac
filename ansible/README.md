# Ansible Infrastructure Management

This directory contains Ansible configuration for managing your Hetzner VPS infrastructure. The setup includes automated Python environment management, encrypted secrets handling, and simplified operations through a comprehensive Makefile.

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Create Python virtual environment and install Ansible
make venv-create

# Create vault password file
make init-vault-password
# Then edit .vault-password-file with your actual password

# Create and edit your first vault file
make vault-edit
```

### 2. Test Connection

```bash
# Test connection to your servers
make ping
```

## 📁 Project Structure

```
ansible/
├── Makefile                    # Main automation and task runner
├── inventory.yml              # Static server inventory (FQDN-based)
├── .vault-password-file       # Vault password (git-ignored)
├── group_vars/all/vault.yml   # Encrypted secrets
├── venv/                      # Python virtual environment (auto-created)
└── README.md                  # This file
```

## 🐍 Python Environment Management

The Makefile automatically manages Python virtual environments:

### Commands
- `make venv-create` - Create virtual environment with Ansible
- `make venv-check` - Check virtual environment status
- All Ansible commands automatically use the venv if available

### Features
- ✅ **Auto-detection**: Automatically uses venv if present
- ✅ **Interactive setup**: Prompts to create venv when missing
- ✅ **Fallback support**: Works with system Ansible if no venv
- ✅ **Status display**: Shows venv status in help

## 🔐 Vault Management

Secure secret management with Ansible Vault:

### Commands
```bash
# Default vault (group_vars/all/vault.yml)
make vault-edit
make vault-view

# Custom vault files (positional arguments)
make vault-edit secrets.yml
make vault-edit environments/production.vault
make vault-view host_vars/server/secrets.yml

# Encryption operations
make vault-encrypt custom.vault
make vault-decrypt temp.vault
make check-vault-password
```

### Features
- ✅ **Auto-creation**: Creates vault files and directories if needed
- ✅ **Flexible paths**: Works with any vault file location
- ✅ **Template generation**: Pre-populates new vault files
- ✅ **Password validation**: Test vault password functionality

### Vault File Template
New vault files are created with this template:
```yaml
# Ansible Vault - Encrypted Variables
# Add your secrets here

# SSH configuration
ssh_port: 22

# Add other secrets as needed
```

## 🎯 Inventory Configuration

### Current Setup
- **Host**: `ha-server` (ha-server.gbweb.fr)
- **User**: `ansible`
- **SSH Key**: `~/.ssh/id_rsa`
- **Vault Variables**: SSH port from encrypted vault

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
make test                    # Run vault + ping test
make up                      # Alias for ping
make status                  # Alias for facts
```

## 🔧 Configuration Files

### .vault-password-file
Store your vault password securely:
```bash
# Create template
make init-vault-password

# Edit with your password
nano .vault-password-file
chmod 600 .vault-password-file
```

### Makefile Variables
Key configuration in the Makefile:
```makefile
INVENTORY := inventory.yml
VAULT_PASSWORD_FILE := .vault-password-file
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

# 2. Setup vault password
make init-vault-password
echo "my-secret-password" > .vault-password-file

# 3. Configure secrets
make vault-edit
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

# Update secrets
make vault-edit production.vault
```

### Troubleshooting
```bash
# Check environment
make help                    # Shows all status info
make venv-check             # Check Python environment
make check-vault-password   # Test vault access

# Debug connection
make facts                  # Detailed server info
make shell HOST=ha-server   # Direct server access
```

## 🔒 Security Best Practices

### Vault Password Management
- ✅ Store vault password in `.vault-password-file`
- ✅ Never commit vault passwords to git
- ✅ Use strong, unique passwords for production
- ✅ Regularly rotate vault passwords

### SSH Configuration
- ✅ Use SSH keys instead of passwords
- ✅ Configure custom SSH ports in vault
- ✅ Limit SSH access with `ansible` user
- ✅ Use `StrictHostKeyChecking=no` only for initial setup

### File Permissions
```bash
chmod 600 .vault-password-file
chmod 644 inventory.yml
chmod 600 ~/.ssh/id_rsa
```

## 🚨 Git Integration

### Files to Ignore
Add to `.gitignore`:
```gitignore
# Ansible secrets
.vault-password-file
*.vault-password*

# Python environment
venv/
__pycache__/

# Ansible artifacts
*.retry
.ansible_async_*
```

### Files to Commit
- ✅ `Makefile`
- ✅ `inventory.yml`
- ✅ `group_vars/all/vault.yml` (encrypted)
- ✅ Playbook files (`*.yml`)
- ✅ `README.md`

## 🆘 Troubleshooting

### Common Issues

**Virtual Environment Problems**
```bash
# Recreate environment
rm -rf venv
make venv-create
```

**Connection Issues**
```bash
# Check inventory
cat inventory.yml

# Test SSH manually
ssh -p 22 ansible@ha-server.gbweb.fr

# Check vault variables
make vault-view
```

**Vault Problems**
```bash
# Test password
make check-vault-password

# Re-encrypt vault
make vault-decrypt
make vault-encrypt
```

### Getting Help

```bash
make help              # Show all available commands
make venv-check        # Environment diagnostics
```

## 🎯 Next Steps

1. **Create Playbooks**: Add `setup.yml`, `deploy.yml`, etc.
2. **Expand Inventory**: Add more hosts as infrastructure grows
3. **Role Organization**: Create `roles/` directory for reusable components
4. **Environment Separation**: Create separate vault files per environment
5. **CI/CD Integration**: Use Makefile targets in automated pipelines

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [SSH Key Management](https://docs.ansible.com/ansible/latest/user_guide/connection_details.html#ssh-key-setup)
- [Inventory Best Practices](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)

---

**Happy Automating! 🚀**