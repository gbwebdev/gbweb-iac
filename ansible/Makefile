# Ansible Operations Makefile
# Simplifies common Ansible tasks with inventory management
.PHONY: help ping setup facts playbook venv-create venv-check shell uptime disk-usage services up status test clean
.DEFAULT_GOAL := help

# Configuration
INVENTORY := inventory.yml
VENV_DIR := venv
PYTHON := python3

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Help target
help:
	@echo "$(GREEN)🚀 Ansible Operations for Hetzner VPS$(NC)"
	@echo ""
	@echo "$(YELLOW)🐍 Python Environment:$(NC)"
	@echo "  venv-create            - Create Python virtual environment"
	@echo "  venv-check             - Check virtual environment status"
	@echo ""
	@echo "$(YELLOW)📋 Common Operations:$(NC)"
	@echo "  ping                   - Test connection to all hosts"
	@echo "  facts                  - Gather facts from all hosts"
	@echo "  setup                  - Run setup tasks (if setup.yml exists)"
	@echo "  playbook PLAY=<name>   - Run specific playbook"
	@echo ""
	@echo "$(YELLOW)🔧 Advanced Operations:$(NC)"
	@echo "  shell HOST=<hostname>  - Open shell on specific host"
	@echo "  uptime                 - Check uptime of all hosts"
	@echo "  disk-usage             - Check disk usage"
	@echo "  services               - Check systemd services status"
	@echo ""
	@echo "$(YELLOW)📁 Files:$(NC)"
	@echo "  Inventory: $(INVENTORY)"
	@echo "  Virtual Env: $(VENV_DIR) $(if $(shell test -d $(VENV_DIR) && echo "exists"),$(GREEN)[EXISTS]$(NC),$(RED)[MISSING]$(NC))"
	@echo ""
	@echo "$(YELLOW)💡 SOPS Usage (use directly):$(NC)"
	@echo "  sops group_vars/all/secrets.yml    # Edit secrets"
	@echo "  sops -d secrets.yml                # View secrets"

# Check if required files exist - this also checks for venv
check-files: venv-check
	@if [ ! -f "$(INVENTORY)" ]; then \
		echo "$(RED)❌ Inventory file $(INVENTORY) not found$(NC)"; \
		exit 1; \
	fi

# Virtual environment management
venv-check:
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "$(RED)❌ Virtual environment required but not found$(NC)"; \
		echo "$(YELLOW)💡 Create it with: make venv-create$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)✅ Virtual environment found: $(VENV_DIR)$(NC)"; \
	fi

venv-create:
	@if [ -d "$(VENV_DIR)" ]; then \
		echo "$(YELLOW)⚠️  Virtual environment already exists$(NC)"; \
	else \
		echo "$(GREEN)🐍 Creating Python virtual environment...$(NC)"; \
		$(PYTHON) -m venv $(VENV_DIR); \
		echo "$(GREEN)📦 Installing Ansible and SOPS...$(NC)"; \
		$(VENV_DIR)/bin/pip install --upgrade pip; \
		$(VENV_DIR)/bin/pip install ansible; \
		. $(VENV_DIR)/bin/activate && ansible-galaxy collection install community.sops; \
		echo "$(GREEN)✅ Virtual environment created with Ansible and SOPS support$(NC)"; \
		echo "$(YELLOW)💡 To activate manually: . $(VENV_DIR)/bin/activate$(NC)"; \
	fi

# Test connection to all hosts
ping: check-files
	@echo "$(GREEN)🏓 Testing connection to all hosts...$(NC)"
	. $(VENV_DIR)/bin/activate && ansible all -i $(INVENTORY) -m ping

# Gather facts from all hosts
facts: check-files
	@echo "$(GREEN)📊 Gathering facts from all hosts...$(NC)"
	. $(VENV_DIR)/bin/activate && ansible all -i $(INVENTORY) -m setup

# Run setup playbook (if it exists)
setup: check-files
	@if [ -f "setup.yml" ]; then \
		echo "$(GREEN)⚙️  Running setup playbook...$(NC)"; \
		. $(VENV_DIR)/bin/activate && ansible-playbook -i $(INVENTORY) setup.yml; \
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
		. $(VENV_DIR)/bin/activate && ansible-playbook -i $(INVENTORY) $(PLAY).yml; \
	else \
		. $(VENV_DIR)/bin/activate && ansible-playbook -i $(INVENTORY) $(PLAY); \
	fi

# Advanced operations
shell: check-files
	@if [ -z "$(HOST)" ]; then \
		echo "$(RED)❌ Please specify host: make shell HOST=<hostname>$(NC)"; \
		echo "$(YELLOW)💡 Available hosts: ha-server$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)🖥️  Opening shell on $(HOST)...$(NC)"
	. $(VENV_DIR)/bin/activate && ansible $(HOST) -i $(INVENTORY) -a "/bin/bash" -i

uptime: check-files
	@echo "$(GREEN)⏰ Checking uptime of all hosts...$(NC)"
	. $(VENV_DIR)/bin/activate && ansible all -i $(INVENTORY) -a "uptime"

disk-usage: check-files
	@echo "$(GREEN)💾 Checking disk usage...$(NC)"
	. $(VENV_DIR)/bin/activate && ansible all -i $(INVENTORY) -a "df -h"

services: check-files
	@echo "$(GREEN)🔧 Checking systemd services status...$(NC)"
	. $(VENV_DIR)/bin/activate && ansible all -i $(INVENTORY) -a "systemctl --failed"

# Quick commands
up: ping
status: facts
test: ping

# Cleanup and maintenance
clean:
	@echo "$(GREEN)🧹 Cleaning up temporary files...$(NC)"
	find . -name "*.retry" -delete
	find . -name ".ansible_async_*" -delete

# Handle positional arguments (prevent make from treating them as targets)
%:
	@:
	find . -name ".ansible_async_*" -delete

# Handle positional arguments (prevent make from treating them as targets)
%:
	@:
	@echo "$(GREEN)🧹 Cleaning up temporary files...$(NC)"
	find . -name "*.retry" -delete
	find . -name ".ansible_async_*" -delete

# Handle positional arguments (prevent make from treating them as targets)
%:
	@:
