#!/bin/bash
# Terraform State Encryption/Decryption Management
# This script handles encryption and decryption of Terraform state files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if GPG is available and configured
check_gpg() {
    if ! command -v gpg &> /dev/null; then
        log_error "GPG is not installed. Please install gnupg."
        exit 1
    fi
    
    # Start GPG agent if not running
    if ! gpg-agent --daemon &>/dev/null; then
        log_info "Starting GPG agent..."
        eval $(gpg-agent --daemon)
    fi
}

# Get or create passphrase file
get_or_create_passphrase() {
    local passphrase_file="$PROJECT_ROOT/.terraform-state-passphrase"
    
    if [[ ! -f "$passphrase_file" ]]; then
        log_info "No passphrase file found. Creating new secure passphrase..."
        
        # Generate a strong random passphrase
        if command -v openssl &> /dev/null; then
            openssl rand -base64 32 > "$passphrase_file"
        elif command -v head &> /dev/null && [[ -c /dev/urandom ]]; then
            head -c 24 /dev/urandom | base64 > "$passphrase_file"
        else
            log_error "Cannot generate secure passphrase. Please install openssl or ensure /dev/urandom is available."
            exit 1
        fi
        
        chmod 600 "$passphrase_file"
        log_success "Generated secure passphrase and saved to $passphrase_file"
        log_warning "⚠️  IMPORTANT: This file contains your encryption passphrase!"
        log_warning "⚠️  Make sure it's added to .gitignore and backup it securely!"
        
        # Check if .gitignore exists and add the passphrase file
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
    fi
    
    if [[ ! -r "$passphrase_file" ]]; then
        log_error "Cannot read passphrase file: $passphrase_file"
        exit 1
    fi
    
    TERRAFORM_PASSPHRASE=$(cat "$passphrase_file")
    if [[ -z "$TERRAFORM_PASSPHRASE" ]]; then
        log_error "Passphrase file is empty: $passphrase_file"
        exit 1
    fi
}

# Get or create GPG key for terraform state encryption
get_gpg_key() {
    local key_id="terraform-state@$(hostname)"
    local existing_key=$(gpg --list-secret-keys --with-colons | grep "uid" | grep "$key_id" | head -1)
    
    if [[ -z "$existing_key" ]]; then
        log_info "No GPG key found for Terraform state encryption."
        log_info "Creating new GPG key: $key_id"
        
        # Get the passphrase
        get_or_create_passphrase
        
        # Create GPG key configuration with the passphrase
        cat > /tmp/gpg-key-config <<EOF
%echo Generating Terraform state encryption key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Terraform State
Name-Email: $key_id
Expire-Date: 0
Passphrase: $TERRAFORM_PASSPHRASE
%commit
%echo Done
EOF
        
        if gpg --batch --generate-key /tmp/gpg-key-config; then
            # Securely remove the temporary file
            shred -vfz -n 3 /tmp/gpg-key-config 2>/dev/null || rm -f /tmp/gpg-key-config
            log_success "Created new GPG key for Terraform state encryption"
        else
            # Securely remove the temporary file
            shred -vfz -n 3 /tmp/gpg-key-config 2>/dev/null || rm -f /tmp/gpg-key-config
            log_error "Failed to create GPG key"
            exit 1
        fi
    else
        # Key exists, just get the passphrase for later use
        get_or_create_passphrase
    fi
    
    # Get the key ID - search for our terraform-state key
    GPG_KEY_ID=$(gpg --list-secret-keys --with-colons | awk -F: -v email="terraform-state@$(hostname)" '
        /^sec/ { key_id = $5 }
        /^uid/ && $10 ~ email { print key_id; exit }
    ')
    
    if [[ -z "$GPG_KEY_ID" ]]; then
        log_error "Could not find or create GPG key for Terraform state encryption"
        log_info "Debug: Searching for key with email: terraform-state@$(hostname)"
        log_info "Available keys:"
        gpg --list-secret-keys --with-colons | grep -E "^(sec|uid)" | head -10
        exit 1
    fi
    
    log_info "Using GPG key: $GPG_KEY_ID"
}

# Find all terraform state files
find_state_files() {
    find "$PROJECT_ROOT" -type f -name "*.tfstate*" | grep -v "/.terraform/" | grep -v ".gpg"
}

# Encrypt a single state file
encrypt_state_file() {
    local state_file="$1"
    local encrypted_file="${state_file}.gpg"
    
    if [[ ! -f "$state_file" ]]; then
        log_warning "State file $state_file not found, skipping..."
        return 0
    fi
    
    # Check if file has any content
    if [[ ! -s "$state_file" ]]; then
        log_warning "State file $state_file is empty, skipping encryption..."
        return 0
    fi
    
    # Check if encrypted file exists and is newer than plaintext file
    if [[ -f "$encrypted_file" ]]; then
        if [[ "$encrypted_file" -nt "$state_file" ]]; then
            log_warning "Encrypted file $(basename "$encrypted_file") is newer than plaintext version!"
            log_warning "This might indicate that the plaintext file is outdated."
            log_info "Plaintext file: $(basename "$state_file") ($(stat -c %y "$state_file"))"
            log_info "Encrypted file: $(basename "$encrypted_file") ($(stat -c %y "$encrypted_file"))"
            
            echo -n "Do you want to overwrite the newer encrypted file? [y/N]: "
            read -r response
            case "$response" in
                [yY]|[yY][eE][sS])
                    log_info "User confirmed overwriting newer encrypted file."
                    ;;
                *)
                    log_info "Skipping encryption of $(basename "$state_file")"
                    return 0
                    ;;
            esac
        fi
    fi
    
    log_info "Encrypting $(basename "$state_file")..."
    
    # Encrypt the file using asymmetric encryption
    if gpg --trust-model always --encrypt --armor --recipient "$GPG_KEY_ID" --output "$encrypted_file" "$state_file"; then
        log_success "Encrypted $(basename "$state_file") → $(basename "$encrypted_file")"
        return 0
    else
        log_error "Failed to encrypt $state_file"
        return 1
    fi
}

# Decrypt a single state file
decrypt_state_file() {
    local encrypted_file="$1"
    local state_file="${encrypted_file%.gpg}"
    
    if [[ ! -f "$encrypted_file" ]]; then
        log_warning "Encrypted file $encrypted_file not found, skipping..."
        return 0
    fi
    
    # Check if plaintext file exists and is newer than encrypted file
    if [[ -f "$state_file" ]]; then
        if [[ "$state_file" -nt "$encrypted_file" ]]; then
            local conflict_file="${state_file}.conflict.$(date +%Y%m%d_%H%M%S)"
            log_warning "Plaintext file $(basename "$state_file") is newer than encrypted version!"
            log_info "Decrypting to conflict file: $(basename "$conflict_file")"
            
            # Decrypt to conflict file
            if gpg --trust-model always --decrypt "$encrypted_file" > "$conflict_file"; then
                log_warning "⚠️  CONFLICT DETECTED!"
                log_warning "Original file: $(basename "$state_file")"
                log_warning "Decrypted file: $(basename "$conflict_file")"
                log_warning "Please review and resolve the conflict manually."
                log_info "You may need to:"
                log_info "  1. Compare the files: diff \"$state_file\" \"$conflict_file\""
                log_info "  2. Choose which version to keep"
                log_info "  3. Remove the conflict file after resolution"
                return 0
            else
                log_error "Failed to decrypt $encrypted_file to conflict file"
                return 1
            fi
        else
            log_info "Plaintext file exists but is older, overwriting..."
        fi
    fi
    
    log_info "Decrypting $(basename "$encrypted_file")..."
    
    # Decrypt the file
    if gpg --trust-model always --decrypt "$encrypted_file" > "$state_file"; then
        log_success "Decrypted $(basename "$encrypted_file") → $(basename "$state_file")"
        return 0
    else
        log_error "Failed to decrypt $encrypted_file"
        return 1
    fi
}

# Encrypt all state files
encrypt_all() {
    local force_mode="$1"
    log_info "🔐 Encrypting all Terraform state files..."
    
    local files_found=false
    while IFS= read -r state_file; do
        if [[ -n "$state_file" ]]; then
            files_found=true
            if [[ "$force_mode" == "--force" ]]; then
                # In force mode, temporarily modify the encrypt function behavior
                encrypt_state_file_force "$state_file"
            else
                encrypt_state_file "$state_file"
            fi
        fi
    done < <(find_state_files)
    
    if [[ "$files_found" == false ]]; then
        log_info "No state files found to encrypt."
    fi
    
    log_success "State file encryption complete!"
}

# Encrypt a single state file with force (no confirmation)
encrypt_state_file_force() {
    local state_file="$1"
    local encrypted_file="${state_file}.gpg"
    
    if [[ ! -f "$state_file" ]]; then
        log_warning "State file $state_file not found, skipping..."
        return 0
    fi
    
    # Check if file has any content
    if [[ ! -s "$state_file" ]]; then
        log_warning "State file $state_file is empty, skipping encryption..."
        return 0
    fi
    
    # Check if encrypted file exists and is newer than plaintext file
    if [[ -f "$encrypted_file" && "$encrypted_file" -nt "$state_file" ]]; then
        log_warning "Encrypted file $(basename "$encrypted_file") is newer than plaintext version! (forced)"
    fi
    
    log_info "Encrypting $(basename "$state_file")..."
    
    # Encrypt the file using asymmetric encryption
    if gpg --trust-model always --encrypt --armor --recipient "$GPG_KEY_ID" --output "$encrypted_file" "$state_file"; then
        log_success "Encrypted $(basename "$state_file") → $(basename "$encrypted_file")"
        return 0
    else
        log_error "Failed to encrypt $state_file"
        return 1
    fi
}

# Decrypt all state files
decrypt_all() {
    log_info "🔓 Decrypting all Terraform state files..."
    
    local files_found=false
    while IFS= read -r encrypted_file; do
        if [[ -n "$encrypted_file" ]]; then
            files_found=true
            decrypt_state_file "$encrypted_file"
        fi
    done < <(find "$PROJECT_ROOT" -name "*.tfstate.gpg")
    
    if [[ "$files_found" == false ]]; then
        log_info "No encrypted state files found to decrypt."
    fi
    
    log_success "State file decryption complete!"
}

# Clean up plaintext state files (for pre-commit)
cleanup_plaintext() {
    log_info "🧹 Cleaning up plaintext state files..."
    
    while IFS= read -r state_file; do
        if [[ -n "$state_file" && -f "${state_file}.gpg" ]]; then
            log_info "Removing plaintext $(basename "$state_file")"
            rm "$state_file"
        fi
    done < <(find_state_files)
    
    log_success "Plaintext cleanup complete!"
}

# Check if encrypted versions exist for all state files
check_encrypted_versions() {
    local missing_encrypted=false
    
    while IFS= read -r state_file; do
        if [[ -n "$state_file" && ! -f "${state_file}.gpg" ]]; then
            log_warning "Missing encrypted version for $(basename "$state_file")"
            missing_encrypted=true
        fi
    done < <(find_state_files)
    
    if [[ "$missing_encrypted" == true ]]; then
        log_error "Some state files are missing encrypted versions!"
        log_info "Run 'make encrypt-states' to encrypt all state files."
        return 1
    fi
    
    log_success "All state files have encrypted versions!"
    return 0
}

# Show usage
usage() {
    echo "Usage: $0 {encrypt|decrypt|cleanup|check} [--force]"
    echo ""
    echo "Commands:"
    echo "  encrypt  - Encrypt all .tfstate files to .tfstate.gpg"
    echo "           - Uses asymmetric GPG encryption with dedicated key"
    echo "           - Asks for confirmation if encrypted file is newer"
    echo "  decrypt  - Decrypt all .tfstate.gpg files to .tfstate"
    echo "           - Uses asymmetric GPG decryption"
    echo "           - If plaintext file is newer, creates .conflict file instead"
    echo "  cleanup  - Remove plaintext .tfstate files (keep encrypted)"
    echo "  check    - Check if all state files have encrypted versions"
    echo ""
    echo "Options:"
    echo "  --force  - Skip confirmation prompts (use with encrypt)"
    echo ""
    echo "Examples:"
    echo "  $0 encrypt          # Before committing to git (with confirmation)"
    echo "  $0 encrypt --force  # Force encrypt without confirmation"
    echo "  $0 decrypt          # After pulling from git"
    echo "  $0 cleanup          # Remove plaintext versions safely"
    echo ""
    echo "GPG Configuration:"
    echo "  - First run will create a dedicated GPG key for Terraform state encryption"
    echo "  - Passphrase is stored in .terraform-state-passphrase (auto-generated)"
    echo "  - Uses asymmetric encryption with secure passphrase from file"
    echo "  - GPG agent caches your key passphrase for the session"
    echo "  - Key ID format: terraform-state@\$(hostname)"
    echo ""
    echo "Security Notes:"
    echo "  - Passphrase file (.terraform-state-passphrase) is automatically added to .gitignore"
    echo "  - Make sure to backup the passphrase file securely (outside of git)"
    echo "  - File permissions are set to 600 (owner read/write only)"
    echo ""
    echo "Conflict Resolution:"
    echo "  - When encrypting: if encrypted file is newer, asks for confirmation"
    echo "  - When decrypting: if plaintext file is newer, creates .conflict file"
    echo "  Use 'diff' to compare and manually resolve conflicts."
}

# Main script logic
main() {
    check_gpg
    get_gpg_key
    
    local command="${1:-}"
    local flag="${2:-}"
    
    case "$command" in
        encrypt)
            encrypt_all "$flag"
            ;;
        decrypt)
            decrypt_all
            ;;
        cleanup)
            cleanup_plaintext
            ;;
        check)
            check_encrypted_versions
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
