# Terraform Infrastructure Management with Per-Environment Secrets and Encrypted State
# This Makefile provides a streamlined way to manage Terraform infrastructure
# with per-environment secrets and encrypted state files.
.PHONY: help init plan apply destroy workspace-list workspace-new workspace-select fmt validate
.PHONY: edit-variables check-variables setup-variables edit-secrets check-secrets setup-secrets setup-encryption encrypt-states decrypt-states cleanup-states check-states export-key import-key tofu import

# Default target
help:
	@echo "🚀 Terraform Infrastructure Management"
	@echo ""
	@echo "🌐 Environment Configuration:"
	@echo "  You can specify the environment in two ways:"
	@echo "  1. Command line: make <target> ENV=production"
	@echo "  2. Environment variable: export TERRAFORM_ENV=production && make <target>"
	@echo ""
	@echo "📋 Main Commands:"
	@echo "  init ENV=production    - Initialize Terraform for environment"
	@echo "  plan ENV=production    - Plan changes for environment"
	@echo "  apply ENV=production   - Apply changes for environment"
	@echo "  destroy ENV=production - Destroy infrastructure for environment"
	@echo "  import ENV=production  - Import existing resources into state"
	@echo "  tofu <args> ENV=production - Run any tofu command with proper environment setup"
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
	@echo "  setup-encryption       - Initial setup for state encryption on new machines"
	@echo "  encrypt-states         - Manually encrypt all .tfstate files to .tfstate.gpg"
	@echo "  decrypt-states         - Manually decrypt all .tfstate.gpg files to .tfstate"
	@echo "  cleanup-states         - Remove plaintext .tfstate files (keep encrypted)"
	@echo "  check-states           - Check if all state files have encrypted versions"
	@echo "  export-key             - Export GPG key for use on other machines"
	@echo "  import-key             - Import GPG key on new machine"
	@echo ""
	@echo "  ℹ️  Note: State files are automatically decrypted before read operations"
	@echo "           and encrypted after write operations (apply, destroy, import)"
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
	@echo "🔧 Utility Commands:"
	@echo "  check-env              - Verify environment variable is set"
	@echo ""
	@echo "🔧 Shell Completion:"
	@echo "  Run './completion/install.sh' to enable tab completion for this Makefile"
	@echo "  Supports bash and zsh with smart environment and command completion"
	@echo ""
	@echo "📁 Available environments: production, staging, development"
	@echo ""
	@echo "💡 Example workflows:"
	@echo "  # First time setup on any machine:"
	@echo "  make setup-encryption          # Create/import GPG key for state encryption"
	@echo "  make setup-secrets             # Create all secrets files"
	@echo "  make export-key                # Export key for use on other machines"
	@echo ""
	@echo "  # New machine setup (after copying key files):"
	@echo "  make import-key                # Import existing GPG key"
	@echo "  make decrypt-states            # Decrypt state files after pull"
	@echo ""
	@echo "  # Daily workflow (now with automatic encryption/decryption):"
	@echo "  make init ENV=production       # Automatically decrypts state files"
	@echo "  make plan ENV=production       # Automatically decrypts state files"
	@echo "  make apply ENV=production      # Auto-decrypts before, auto-encrypts after"
	@echo "  # State files are now automatically managed!"
	@echo ""
	@echo "  # Using environment variable (now with automatic encryption):"
	@echo "  export TERRAFORM_ENV=production"
	@echo "  make setup-secrets"
	@echo "  make edit-secrets"
	@echo "  make init                      # Auto-decrypts state files"
	@echo "  make plan                      # Auto-decrypts state files" 
	@echo "  make apply                     # Auto-decrypts before, auto-encrypts after"
	@echo ""
	@echo "  # Using the flexible tofu command:"
	@echo "  make tofu show ENV=production          # Show current state"
	@echo "  make tofu output ENV=production        # Show outputs"
	@echo "  make tofu import aws_instance.example i-1234567890abcdef0 ENV=production"
	@echo "  make tofu state list ENV=production    # List resources in state"

# Check if environment is specified (command line or environment variable)
check-env:
ifndef ENV
ifdef TERRAFORM_ENV
	$(eval ENV := $(TERRAFORM_ENV))
else
	$(error ❌ ENV is undefined. Usage: make <target> ENV=<environment> or set TERRAFORM_ENV environment variable)
endif
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
init: check-env check-variables check-secrets decrypt-states-auto
	@echo "🚀 Initializing Terraform for $(ENV)..."
	tofu init
	tofu workspace select $(ENV) || tofu workspace new $(ENV)

# Plan changes
plan: check-env check-variables check-secrets decrypt-states-auto
	@echo "📋 Planning changes for $(ENV)..."
	tofu workspace select $(ENV)
	$(eval TOFU_ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	tofu plan -var-file="tfvars/$(ENV).tfvars" -var-file="tfvars/$(ENV).secrets.tfvars" $(TOFU_ARGS)
# Prevent make from interpreting additional arguments as targets
%:
	@:

# Apply changes
apply: check-env check-variables check-secrets decrypt-states-auto
	@echo "🚀 Applying changes for $(ENV)..."
	tofu workspace select $(ENV)
	$(eval TOFU_ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	tofu apply -var-file="tfvars/$(ENV).tfvars" -var-file="tfvars/$(ENV).secrets.tfvars" $(TOFU_ARGS)
	$(MAKE) encrypt-states-auto
# Prevent make from interpreting additional arguments as targets
%:
	@:

# Destroy infrastructure
destroy: check-env check-variables check-secrets decrypt-states-auto
	@echo "💥 Destroying infrastructure for $(ENV)..."
	tofu workspace select $(ENV)
	$(eval TOFU_ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	tofu destroy -var-file="tfvars/$(ENV).tfvars" -var-file="tfvars/$(ENV).secrets.tfvars" $(TOFU_ARGS)
	$(MAKE) encrypt-states-auto
# Prevent make from interpreting additional arguments as targets
%:
	@:

# Import infrastructure
import: check-env check-variables check-secrets decrypt-states-auto
	@echo "📦 Importing resources for $(ENV)..."
	tofu workspace select $(ENV)
	$(eval TOFU_ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	tofu import -var-file="tfvars/$(ENV).tfvars" -var-file="tfvars/$(ENV).secrets.tfvars" $(TOFU_ARGS)
	$(MAKE) encrypt-states-auto
# Prevent make from interpreting additional arguments as targets
%:
	@:

# Run any tofu command with proper environment setup
tofu: check-env check-variables check-secrets decrypt-states-auto
	@echo "🔧 Running tofu command for $(ENV)..."
	tofu workspace select $(ENV)
	$(eval TOFU_ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval TOFU_CMD := $(word 1,$(TOFU_ARGS)))
	$(eval TOFU_REST := $(wordlist 2,$(words $(TOFU_ARGS)),$(TOFU_ARGS)))
	@# Check if command accepts -var-file parameters
	@if echo "$(TOFU_CMD)" | grep -qE "^(plan|apply|destroy|refresh)$$"; then \
		tofu $(TOFU_CMD) -var-file="tfvars/$(ENV).tfvars" -var-file="tfvars/$(ENV).secrets.tfvars" $(TOFU_REST); \
	else \
		tofu $(TOFU_CMD) $(TOFU_REST); \
	fi
	@# Auto-encrypt after state-modifying commands
	@if echo "$(TOFU_CMD)" | grep -qE "^(apply|destroy|import)$$"; then \
		$(MAKE) encrypt-states-auto; \
	fi

# Prevent make from interpreting additional arguments as targets
%:
	@:

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
setup-encryption:
	@echo "🔧 Setting up state file encryption..."
	@./../scripts/tfstate-crypto.sh setup

encrypt-states:
	@echo "🔐 Encrypting Terraform state files..."
	@./../scripts/tfstate-crypto.sh encrypt

decrypt-states:
	@echo "🔓 Decrypting Terraform state files..."
	@./../scripts/tfstate-crypto.sh decrypt

# Silent auto-encrypt for use in workflows (no output unless error)
encrypt-states-auto:
	@./../scripts/tfstate-crypto.sh encrypt --force >/dev/null 2>&1 || { \
		echo "❌ Failed to auto-encrypt state files"; \
		./../scripts/tfstate-crypto.sh encrypt; \
	}

# Silent auto-decrypt for use in workflows (no output unless error)
decrypt-states-auto:
	@./../scripts/tfstate-crypto.sh decrypt >/dev/null 2>&1 || { \
		echo "❌ Failed to auto-decrypt state files"; \
		./../scripts/tfstate-crypto.sh decrypt; \
	}

cleanup-states:
	@echo "🧹 Cleaning up plaintext state files..."
	@./../scripts/tfstate-crypto.sh cleanup

check-states:
	@echo "🔍 Checking state file encryption status..."
	@./../scripts/tfstate-crypto.sh check

export-key:
	@echo "📤 Exporting GPG key for use on other machines..."
	@./../scripts/tfstate-crypto.sh export-key
	@echo "📋 Next steps:"
	@echo "  1. Securely copy .terraform-state-passphrase and .terraform-state-key.asc to other machines"
	@echo "  2. Run 'make import-key' on the new machine"

import-key:
	@echo "📥 Importing GPG key on new machine..."
	@./../scripts/tfstate-crypto.sh import-key
