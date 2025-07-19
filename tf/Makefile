# Terraform Infrastructure Management with Per-Environment Secrets and Encrypted State
# This Makefile provides a streamlined way to manage Terraform infrastructure
# with per-environment secrets and encrypted state files.
.PHONY: help init plan apply destroy workspace-list workspace-new workspace-select fmt validate
.PHONY: edit-variables check-variables setup-variables edit-secrets check-secrets setup-secrets encrypt-states decrypt-states cleanup-states check-states

# Default target
help:
	@echo "🚀 Terraform Infrastructure Management"
	@echo ""
	@echo "📋 Main Commands:"
	@echo "  init ENV=production    - Initialize Terraform for environment"
	@echo "  plan ENV=production    - Plan changes for environment"
	@echo "  apply ENV=production   - Apply changes for environment"
	@echo "  destroy ENV=production - Destroy infrastructure for environment"
	@echo ""
	@echo "🔐 Secrets Management:"
	@echo "  edit-secrets ENV=production    - Edit secrets for specific environment"
	@echo "  setup-secrets                  - Create all missing secrets files from templates"
	@echo "  check-secrets ENV=production   - Check if secrets exist for environment"
	@echo ""
	@echo "🔤 Variables Management:"
	@echo "  edit-variables ENV=production - Edit variables for specific environment"
	@echo "  setup-variables                - Create all missing variables files from templates"
	@echo "  check-variables ENV=production - Check if variables exist for environment"
	@echo ""
	@echo "🔒 State File Management:"
	@echo "  encrypt-states         - Encrypt all .tfstate files to .tfstate.gpg"
	@echo "  decrypt-states         - Decrypt all .tfstate.gpg files to .tfstate"
	@echo "  cleanup-states         - Remove plaintext .tfstate files (keep encrypted)"
	@echo "  check-states           - Check if all state files have encrypted versions"
	@echo ""
	@echo "🏢 Workspace Management:"
	@echo "  workspace-list         - List all workspaces"
	@echo "  workspace-new ENV=staging - Create new workspace"
	@echo "  workspace-select ENV=production - Select workspace"
	@echo "  workspace-current      - Show current workspace"
	@echo ""
	@echo "🛠️  Code Quality:"
	@echo "  fmt                    - Format Terraform files"
	@echo "  validate               - Validate Terraform configuration"
	@echo ""
	@echo "📁 Available environments: production, staging, development"
	@echo ""
	@echo "💡 Example workflow:"
	@echo "  make setup-secrets             # Create all secrets files"
	@echo "  make edit-secrets ENV=production # Edit production secrets"
	@echo "  make decrypt-states            # Decrypt state files after pull"
	@echo "  make init ENV=production"
	@echo "  make plan ENV=production"
	@echo "  make apply ENV=production"
	@echo "  make encrypt-states            # Encrypt before commit"

# Check if environment is specified
check-env:
ifndef ENV
	$(error ❌ ENV is undefined. Usage: make <target> ENV=<environment>)
endif

# Check if secrets file exists for environment
check-secrets: check-env
	@if [ ! -f "tfvars/$(ENV).secrets.tfvars" ]; then \
		echo "❌ Secrets file tfvars/$(ENV).secrets.tfvars not found."; \
		echo "   Run 'make setup-secrets' or 'make edit-secrets ENV=$(ENV)' to create it."; \
		exit 1; \
	fi
	@echo "✅ Secrets file found for $(ENV)"

# Setup all secrets files from templates
setup-secrets:
	@echo "🔧 Setting up secrets files for all environments..."
	@for env in production staging development; do \
		if [ ! -f "tfvars/$$env.secrets.tfvars" ]; then \
			echo "� Creating tfvars/$$env.secrets.tfvars..."; \
			cp "tfvars/_secrets.tfvars.example" "tfvars/$$env.secrets.tfvars" 2>/dev/null || \
			echo "# $$env environment secrets - Fill with your actual values" > "tfvars/$$env.secrets.tfvars"; \
		else \
			echo "✅ tfvars/$$env.secrets.tfvars already exists"; \
		fi \
	done
	@echo "� Remember: Secrets files are in .gitignore and won't be committed"

# Edit secrets for specific environment
edit-secrets: check-env
	@if [ ! -f "tfvars/$(ENV).secrets.tfvars" ]; then \
		echo "📝 Creating tfvars/$(ENV).secrets.tfvars from template..."; \
		cp "tfvars/_secrets.tfvars.example" "tfvars/$(ENV).secrets.tfvars" 2>/dev/null || \
		echo "# $(ENV) environment secrets - Fill with your actual values" > "tfvars/$(ENV).secrets.tfvars"; \
	fi
	@echo "📝 Opening tfvars/$(ENV).secrets.tfvars in editor..."
	@$${EDITOR:-nano} "tfvars/$(ENV).secrets.tfvars"
	@echo "✅ Secrets file updated for $(ENV)"

check-variables: check-env
	@if [ ! -f "tfvars/$(ENV).tfvars" ]; then \
		echo "❌ Variables file tfvars/$(ENV).tfvars not found."; \
		echo "   Run 'make setup-variables' or 'make edit-variables ENV=$(ENV)' to create it."; \
		exit 1; \
	fi
	@echo "✅ Variables file found for $(ENV)"

setup-variables:
	@echo "🔧 Setting up variables files for all environments..."
	@for env in production staging development; do \
		if [ ! -f "tfvars/$$env.tfvars" ]; then \
			echo "� Creating tfvars/$$env.tfvars..."; \
			cp "tfvars/_.tfvars.example" "tfvars/$$env.tfvars" 2>/dev/null || \
			echo "# $$env environment variables - Fill with your actual values" > "tfvars/$$env.tfvars"; \
		else \
			echo "✅ tfvars/$$env.tfvars already exists"; \
		fi \
	done

edit-variables: check-env
	@if [ ! -f "tfvars/$(ENV).tfvars" ]; then \
		echo "📝 Creating tfvars/$(ENV).tfvars from template..."; \
		cp "tfvars/_.tfvars.example" "tfvars/$(ENV).tfvars" 2>/dev/null || \
		echo "# $(ENV) environment variables - Fill with your actual values" > "tfvars/$(ENV).tfvars"; \
	fi
	@echo "📝 Opening tfvars/$(ENV).tfvars in editor..."
	@$${EDITOR:-nano} "tfvars/$(ENV).tfvars"
	@echo "✅ Variables file updated for $(ENV)"

# Initialize Terraform
init: check-env check-variables check-secrets
	@echo "🚀 Initializing Terraform for $(ENV)..."
	tofu init
	tofu workspace select $(ENV) || tofu workspace new $(ENV)

# Plan changes
plan: check-env check-variables check-secrets
	@echo "📋 Planning changes for $(ENV)..."
	tofu workspace select $(ENV)
	tofu plan -var-file="tfvars/$(ENV).tfvars" -var-file="tfvars/$(ENV).secrets.tfvars"

# Apply changes
apply: check-env check-variables check-secrets
	@echo "🚀 Applying changes for $(ENV)..."
	tofu workspace select $(ENV)
	tofu apply -var-file="tfvars/$(ENV).tfvars" -var-file="tfvars/$(ENV).secrets.tfvars"
	$(MAKE) encrypt-states

# Destroy infrastructure
destroy: check-env check-variables check-secrets
	@echo "💥 Destroying infrastructure for $(ENV)..."
	tofu workspace select $(ENV)
	tofu destroy -var-file="tfvars/$(ENV).tfvars" -var-file="tfvars/$(ENV).secrets.tfvars"
	$(MAKE) encrypt-states

# Workspace management
workspace-list:
	tofu workspace list

workspace-new: check-env
	tofu workspace new $(ENV)

workspace-select: check-env
	tofu workspace select $(ENV)

# Code quality
fmt:
	tofu fmt -recursive

validate:
	tofu validate

# Show current workspace
workspace-current:
	tofu workspace show

# State file encryption/decryption
encrypt-states:
	@echo "🔐 Encrypting Terraform state files..."
	@./scripts/tfstate-crypto.sh encrypt

decrypt-states:
	@echo "🔓 Decrypting Terraform state files..."
	@./scripts/tfstate-crypto.sh decrypt

cleanup-states:
	@echo "🧹 Cleaning up plaintext state files..."
	@./scripts/tfstate-crypto.sh cleanup

check-states:
	@echo "🔍 Checking state file encryption status..."
	@./scripts/tfstate-crypto.sh check
