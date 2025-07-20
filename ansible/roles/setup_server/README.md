# Setup Server Role

This Ansible role enforces the server configuration that matches what is set up during cloud-init in the Terraform Hetzner module. It ensures that the server configuration is consistent and can be re-applied as needed.

## Features

This role configures:

- **System settings**: Timezone (Europe/Paris), package updates
- **Essential packages**: curl, wget, git, htop, ufw, fail2ban, unzip, vim
- **Disk management**: Sets up /dev/sdb partition and mounts it as /data
- **User accounts**: Creates ansible and admin users with sudo privileges
- **SSH hardening**: Custom port, key-only authentication, restricted users
- **Firewall**: UFW with default deny incoming, allow outgoing
- **Security**: Fail2Ban for SSH protection
- **Services**: Ensures SSH and Fail2Ban are running and enabled

## Required Variables

Define these variables in your inventory, group_vars, or vault:

```yaml
# SSH configuration
ssh_port: 2222  # Custom SSH port

# Admin user
admin_username: "your-admin-user"
admin_ssh_public_keys:
  - "ssh-rsa AAAAB3NzaC1yc2EAAAA... your-admin-key"

# Ansible user SSH keys
ansible_ssh_public_keys:
  - "ssh-rsa AAAAB3NzaC1yc2EAAAA... ansible-key"
```

## Optional Variables

The following variables can be customized (see `defaults/main.yaml`):

```yaml
# Timezone
timezone: "Europe/Paris"

# Essential packages list
essential_packages:
  - curl
  - wget
  # ... add more packages

# Fail2Ban settings
fail2ban_ssh_maxretry: 3
fail2ban_ssh_bantime: 7200
fail2ban_ssh_findtime: 1200
```

## Usage

Include this role in your playbook:

```yaml
- hosts: hetzner
  roles:
    - setup_server
```

Or use it with specific tags:

```bash
ansible-playbook -i inventory.yml playbook.yml --tags "users,security"
```

## Dependencies

This role requires the following Ansible collections:
- `ansible.posix`
- `community.general`

Install them with:
```bash
ansible-galaxy collection install ansible.posix community.general
```

## Handlers

The role includes handlers for:
- `restart ssh`: Restarts SSH service when configuration changes
- `restart fail2ban`: Restarts Fail2Ban when configuration changes

## Templates

- `sshd_config.j2`: SSH daemon configuration
- `fail2ban_ssh.j2`: Fail2Ban SSH jail configuration

## Notes

- The role checks for the existence of `/dev/sdb` before attempting disk operations
- SSH keys for users are only configured when the respective variables are defined
- The role is idempotent and can be run multiple times safely
- UFW is reset and reconfigured to ensure a clean firewall state
