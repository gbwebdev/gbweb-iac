#!/bin/bash
# Terraform State Passphrase Management
# This script helps manage the passphrase file for Terraform state encryption

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PASSPHRASE_FILE="$PROJECT_ROOT/.terraform-state-passphrase"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Show passphrase file status
show_status() {
    echo ""
    log_info "Terraform State Passphrase Status:"
    echo ""
    
    if [[ -f "$PASSPHRASE_FILE" ]]; then
        log_success "Passphrase file exists: $PASSPHRASE_FILE"
        echo "  • File permissions: $(stat -c %a "$PASSPHRASE_FILE")"
        echo "  • File size: $(stat -c %s "$PASSPHRASE_FILE") bytes"
        echo "  • Last modified: $(stat -c %y "$PASSPHRASE_FILE")"
        
        # Check if it's in .gitignore
        local gitignore_file="$PROJECT_ROOT/.gitignore"
        if [[ -f "$gitignore_file" ]] && grep -q ".terraform-state-passphrase" "$gitignore_file"; then
            log_success "Passphrase file is properly ignored by git"
        else
            log_warning "Passphrase file is NOT in .gitignore!"
        fi
    else
        log_warning "Passphrase file not found: $PASSPHRASE_FILE"
        log_info "Run './tfstate-crypto.sh encrypt' to create it automatically"
    fi
    echo ""
}

# Generate new passphrase
generate_passphrase() {
    if [[ -f "$PASSPHRASE_FILE" ]]; then
        log_warning "Passphrase file already exists!"
        echo -n "Do you want to replace it? This will make existing encrypted files unreadable! [y/N]: "
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS])
                log_info "Creating backup and generating new passphrase..."
                cp "$PASSPHRASE_FILE" "$PASSPHRASE_FILE.backup.$(date +%Y%m%d_%H%M%S)"
                ;;
            *)
                log_info "Cancelled passphrase generation."
                return 0
                ;;
        esac
    fi
    
    log_info "Generating new secure passphrase..."
    
    # Generate a strong random passphrase
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 > "$PASSPHRASE_FILE"
    elif command -v head &> /dev/null && [[ -c /dev/urandom ]]; then
        head -c 24 /dev/urandom | base64 > "$PASSPHRASE_FILE"
    else
        log_error "Cannot generate secure passphrase. Please install openssl or ensure /dev/urandom is available."
        exit 1
    fi
    
    chmod 600 "$PASSPHRASE_FILE"
    log_success "Generated new passphrase and saved to $PASSPHRASE_FILE"
    
    # Add to .gitignore if needed
    local gitignore_file="$PROJECT_ROOT/.gitignore"
    if [[ -f "$gitignore_file" ]]; then
        if ! grep -q ".terraform-state-passphrase" "$gitignore_file"; then
            echo "" >> "$gitignore_file"
            echo "# Terraform state encryption passphrase" >> "$gitignore_file"
            echo ".terraform-state-passphrase" >> "$gitignore_file"
            log_info "Added .terraform-state-passphrase to .gitignore"
        fi
    else
        log_warning "No .gitignore found. Please manually add .terraform-state-passphrase to your .gitignore!"
    fi
}

# Show passphrase (be careful!)
show_passphrase() {
    if [[ ! -f "$PASSPHRASE_FILE" ]]; then
        log_error "Passphrase file not found: $PASSPHRASE_FILE"
        exit 1
    fi
    
    log_warning "⚠️  WARNING: This will display the passphrase in plain text!"
    echo -n "Are you sure you want to continue? [y/N]: "
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS])
            echo ""
            log_info "Passphrase content:"
            echo "----------------------------------------"
            cat "$PASSPHRASE_FILE"
            echo "----------------------------------------"
            echo ""
            log_warning "Remember to clear your terminal history if needed!"
            ;;
        *)
            log_info "Cancelled."
            ;;
    esac
}

# Export passphrase as environment variable
export_passphrase() {
    if [[ ! -f "$PASSPHRASE_FILE" ]]; then
        log_error "Passphrase file not found: $PASSPHRASE_FILE"
        exit 1
    fi
    
    local passphrase=$(cat "$PASSPHRASE_FILE")
    export TERRAFORM_STATE_PASSPHRASE="$passphrase"
    
    log_success "Passphrase exported as TERRAFORM_STATE_PASSPHRASE environment variable"
    log_info "You can now use it in scripts with: \$TERRAFORM_STATE_PASSPHRASE"
    log_warning "Remember: this is only available in the current shell session"
}

# Backup passphrase file
backup_passphrase() {
    if [[ ! -f "$PASSPHRASE_FILE" ]]; then
        log_error "Passphrase file not found: $PASSPHRASE_FILE"
        exit 1
    fi
    
    local backup_file="$PASSPHRASE_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$PASSPHRASE_FILE" "$backup_file"
    chmod 600 "$backup_file"
    
    log_success "Passphrase backed up to: $backup_file"
    log_info "Store this backup in a secure location outside of this repository"
}

# Show usage
usage() {
    echo "Usage: $0 {status|generate|show|export|backup}"
    echo ""
    echo "Commands:"
    echo "  status   - Show passphrase file status and git ignore status"
    echo "  generate - Generate a new secure passphrase (WARNING: invalidates existing encrypted files)"
    echo "  show     - Display the current passphrase (WARNING: plain text)"
    echo "  export   - Export passphrase as TERRAFORM_STATE_PASSPHRASE environment variable"
    echo "  backup   - Create a timestamped backup of the passphrase file"
    echo ""
    echo "Examples:"
    echo "  $0 status    # Check if passphrase file exists and is properly configured"
    echo "  $0 generate  # Generate new passphrase (first time setup)"
    echo "  $0 backup    # Create backup before making changes"
    echo ""
    echo "Security Notes:"
    echo "  - Keep the passphrase file secure and backed up outside of git"
    echo "  - If you lose the passphrase, encrypted state files cannot be recovered"
    echo "  - Generating a new passphrase will make existing encrypted files unreadable"
}

# Main script logic
main() {
    local command="${1:-status}"
    
    case "$command" in
        status)
            show_status
            ;;
        generate)
            generate_passphrase
            ;;
        show)
            show_passphrase
            ;;
        export)
            export_passphrase
            ;;
        backup)
            backup_passphrase
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
