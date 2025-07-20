# Ansible Operations Makefile
# Simplifies common Ansible tasks with vault and inventory management
.PHONY: help ping setup facts playbook vault-edit vault-encrypt vault-decrypt vault-view check-vault-password venv-create venv-check
.DEFAULT_GOAL := help

# Configuration
INVENTORY := inventory.yml
VAULT_PASSWORD_FILE := .vault-password-file
VAULT_FILE := $(if $(word 2,$(MAKECMDGOALS)),$(word 2,$(MAKECMDGOALS)),group_vars/all/vault.yml)
VENV_DIR := venv
PYTHON := python3

# Virtual environment activation
ifeq ($(shell test -d $(VENV_DIR) && echo "exists"), exists)
	VENV_ACTIVATE := . $(VENV_DIR)/bin/activate &&
	ANSIBLE_CMD := $(VENV_ACTIVATE) ansible
	ANSIBLE_PLAYBOOK_CMD := $(VENV_ACTIVATE) ansible-playbook
	ANSIBLE_VAULT_CMD := $(VENV_ACTIVATE) ansible-vault
else
	ANSIBLE_CMD := ansible
	ANSIBLE_PLAYBOOK_CMD := ansible-playbook
	ANSIBLE_VAULT_CMD := ansible-vault
endif

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Help target
help:
	@echo "$(GREEN)🚀 Ansible Operations for Hetzner VPS$(NC)"
	@echo ""
	@echo "$(YELLOW)� Python Environment:$(NC)"
	@echo "  venv-create            - Create Python virtual environment"
	@echo "  venv-check             - Check virtual environment status"
	@echo ""
	@echo "$(YELLOW)�📋 Common Operations:$(NC)"
	@echo "  ping                   - Test connection to all hosts"
	@echo "  facts                  - Gather facts from all hosts"
	@echo "  setup                  - Run setup tasks (if setup.yml exists)"
	@echo "  playbook PLAY=<n>   - Run specific playbook"
	@echo ""
	@echo "$(YELLOW)🔐 Vault Management:$(NC)"
	@echo "  vault-edit [file]      - Edit encrypted vault file"
	@echo "  vault-view [file]      - View encrypted vault file (read-only)"
	@echo "  vault-encrypt [file]   - Encrypt vault file"
	@echo "  vault-decrypt [file]   - Decrypt vault file (temporarily)"
	@echo "  check-vault-password   - Test if vault password file works"
	@echo ""
	@echo "$(YELLOW)🔧 Advanced Operations:$(NC)"
	@echo "  shell HOST=<hostname>  - Open shell on specific host"
	@echo "  uptime                 - Check uptime of all hosts"
	@echo "  disk-usage             - Check disk usage"
	@echo "  services               - Check systemd services status"
	@echo ""
	@echo "$(YELLOW)📁 Files:$(NC)"
	@echo "  Inventory: $(INVENTORY)"
	@echo "  Vault Password: $(VAULT_PASSWORD_FILE)"
	@echo "  Vault File: $(VAULT_FILE)"
	@echo "  Virtual Env: $(VENV_DIR) $(if $(shell test -d $(VENV_DIR) && echo "exists"),$(GREEN)[EXISTS]$(NC),$(RED)[MISSING]$(NC))"
	@echo ""
	@echo "$(YELLOW)💡 Examples:$(NC)"
	@echo "  make vault-edit                    # Edit default vault"
	@echo "  make vault-edit secrets.yml        # Edit specific vault"
	@echo "  make vault-view prod.vault         # View production vault"

# Check if required files exist and suggest venv creation if needed
check-files: venv-check
	@if [ ! -f "$(INVENTORY)" ]; then \
		echo "$(RED)❌ Inventory file $(INVENTORY) not found$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(VAULT_PASSWORD_FILE)" ]; then \
		echo "$(RED)❌ Vault password file $(VAULT_PASSWORD_FILE) not found$(NC)"; \
		echo "$(YELLOW)💡 Create it with: echo 'your_vault_password' > $(VAULT_PASSWORD_FILE)$(NC)"; \
		exit 1; \
	fi

# Virtual environment management
venv-check:
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "$(YELLOW)⚠️  Virtual environment not found$(NC)"; \
		echo "$(YELLOW)💡 Create it with: make venv-create$(NC)"; \
		echo "$(YELLOW)   Or manually: python3 -m venv $(VENV_DIR) && . $(VENV_DIR)/bin/activate && pip install ansible$(NC)"; \
		read -p "Create virtual environment now? [y/N]: " confirm && [ "$$confirm" = "y" ] && make venv-create || exit 1; \
	else \
		echo "$(GREEN)✅ Virtual environment found: $(VENV_DIR)$(NC)"; \
	fi

venv-create:
	@if [ -d "$(VENV_DIR)" ]; then \
		echo "$(YELLOW)⚠️  Virtual environment already exists$(NC)"; \
	else \
		echo "$(GREEN)🐍 Creating Python virtual environment...$(NC)"; \
		$(PYTHON) -m venv $(VENV_DIR); \
		echo "$(GREEN)📦 Installing Ansible...$(NC)"; \
		$(VENV_DIR)/bin/pip install --upgrade pip; \
		$(VENV_DIR)/bin/pip install ansible; \
		echo "$(GREEN)✅ Virtual environment created and Ansible installed$(NC)"; \
		echo "$(YELLOW)💡 To activate manually: . $(VENV_DIR)/bin/activate$(NC)"; \
	fi

# Test connection to all hosts
ping: check-files
	@echo "$(GREEN)🏓 Testing connection to all hosts...$(NC)"
	$(ANSIBLE_CMD) all -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) -m ping

# Gather facts from all hosts
facts: check-files
	@echo "$(GREEN)📊 Gathering facts from all hosts...$(NC)"
	$(ANSIBLE_CMD) all -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) -m setup

# Run setup playbook (if it exists)
setup: check-files
	@if [ -f "setup.yml" ]; then \
		echo "$(GREEN)⚙️  Running setup playbook...$(NC)"; \
		$(ANSIBLE_PLAYBOOK_CMD) -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) setup.yml; \
	else \
		echo "$(YELLOW)⚠️  No setup.yml playbook found$(NC)"; \
	fi

# Run specific playbook
playbook: check-files
	@if [ -z "$(PLAY)" ]; then \
		echo "$(RED)❌ Please specify playbook: make playbook PLAY=<playbook-name>$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(PLAY).yml" ] && [ ! -f "$(PLAY)" ]; then \
		echo "$(RED)❌ Playbook $(PLAY).yml or $(PLAY) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)🎭 Running playbook: $(PLAY)$(NC)"
	@if [ -f "$(PLAY).yml" ]; then \
		$(ANSIBLE_PLAYBOOK_CMD) -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) $(PLAY).yml; \
	else \
		$(ANSIBLE_PLAYBOOK_CMD) -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) $(PLAY); \
	fi

# Vault management
vault-edit: check-files
	@if [ ! -f "$(VAULT_FILE)" ]; then \
		echo "$(YELLOW)📝 Vault file '$(VAULT_FILE)' doesn't exist, creating...$(NC)"; \
		mkdir -p $$(dirname "$(VAULT_FILE)"); \
		echo "# Ansible Vault - Encrypted Variables" > $(VAULT_FILE); \
		echo "# Add your secrets here" >> $(VAULT_FILE); \
		echo "" >> $(VAULT_FILE); \
		echo "# SSH configuration" >> $(VAULT_FILE); \
		echo "ssh_port: 22" >> $(VAULT_FILE); \
		echo "" >> $(VAULT_FILE); \
		echo "# Add other secrets as needed" >> $(VAULT_FILE); \
		echo "$(GREEN)✅ Created vault file template: $(VAULT_FILE)$(NC)"; \
	fi
	@echo "$(GREEN)🔓 Editing vault file: $(VAULT_FILE)$(NC)"
	$(ANSIBLE_VAULT_CMD) edit $(VAULT_FILE) --vault-password-file $(VAULT_PASSWORD_FILE)

vault-view: check-files
	@echo "$(GREEN)👀 Viewing vault file...$(NC)"
	$(ANSIBLE_VAULT_CMD) view $(VAULT_FILE) --vault-password-file $(VAULT_PASSWORD_FILE)

vault-encrypt:
	@if [ ! -f "$(VAULT_PASSWORD_FILE)" ]; then \
		echo "$(RED)❌ Vault password file $(VAULT_PASSWORD_FILE) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)🔒 Encrypting vault file...$(NC)"
	$(ANSIBLE_VAULT_CMD) encrypt $(VAULT_FILE) --vault-password-file $(VAULT_PASSWORD_FILE)

vault-decrypt:
	@if [ ! -f "$(VAULT_PASSWORD_FILE)" ]; then \
		echo "$(RED)❌ Vault password file $(VAULT_PASSWORD_FILE) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🔓 Temporarily decrypting vault file...$(NC)"
	@echo "$(YELLOW)⚠️  Remember to re-encrypt with: make vault-encrypt$(NC)"
	$(ANSIBLE_VAULT_CMD) decrypt $(VAULT_FILE) --vault-password-file $(VAULT_PASSWORD_FILE)

check-vault-password:
	@if [ ! -f "$(VAULT_PASSWORD_FILE)" ]; then \
		echo "$(RED)❌ Vault password file $(VAULT_PASSWORD_FILE) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)🔑 Testing vault password...$(NC)"
	@if $(ANSIBLE_VAULT_CMD) view $(VAULT_FILE) --vault-password-file $(VAULT_PASSWORD_FILE) > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Vault password is correct$(NC)"; \
	else \
		echo "$(RED)❌ Vault password is incorrect$(NC)"; \
		exit 1; \
	fi

# Advanced operations
shell: check-files
	@if [ -z "$(HOST)" ]; then \
		echo "$(RED)❌ Please specify host: make shell HOST=<hostname>$(NC)"; \
		echo "$(YELLOW)💡 Available hosts: ha-server$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)🖥️  Opening shell on $(HOST)...$(NC)"
	$(ANSIBLE_CMD) $(HOST) -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) -a "/bin/bash" -i

uptime: check-files
	@echo "$(GREEN)⏰ Checking uptime of all hosts...$(NC)"
	$(ANSIBLE_CMD) all -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) -a "uptime"

disk-usage: check-files
	@echo "$(GREEN)💾 Checking disk usage...$(NC)"
	$(ANSIBLE_CMD) all -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) -a "df -h"

services: check-files
	@echo "$(GREEN)🔧 Checking systemd services status...$(NC)"
	$(ANSIBLE_CMD) all -i $(INVENTORY) --vault-password-file $(VAULT_PASSWORD_FILE) -a "systemctl --failed"

# Quick commands
up: ping
status: facts
test: check-vault-password ping

# Cleanup and maintenance
clean:
	@echo "$(GREEN)🧹 Cleaning up temporary files...$(NC)"
	find . -name "*.retry" -delete
	find . -name ".ansible_async_*" -delete

# Create vault password file template
init-vault-password:
	@if [ -f "$(VAULT_PASSWORD_FILE)" ]; then \
		echo "$(YELLOW)⚠️  Vault password file already exists$(NC)"; \
	else \
		echo "$(GREEN)🔑 Creating vault password file template...$(NC)"; \
		echo "# Replace with your actual vault password" > $(VAULT_PASSWORD_FILE); \
		echo "your_vault_password_here" >> $(VAULT_PASSWORD_FILE); \
		chmod 600 $(VAULT_PASSWORD_FILE); \
		echo "$(YELLOW)⚠️  Edit $(VAULT_PASSWORD_FILE) with your actual password$(NC)"; \
	fi

# Handle positional arguments for vault operations (prevent make from treating them as targets)
%:
	@:
