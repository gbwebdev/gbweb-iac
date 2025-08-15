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
}

# Configure GPG for non-interactive batch operations
setup_gpg_batch_mode() {
    # Set GPG_TTY to avoid tty issues
    export GPG_TTY=$(tty 2>/dev/null || echo "")
    
    # Configure GPG for batch mode
    export GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"
    
    # Create a temporary GPG config for this session
    GPG_BATCH_OPTS=(
        "--batch"
        "--yes"
        "--quiet"
        "--no-tty"
        "--pinentry-mode" "loopback"
        "--trust-model" "always"
    )
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
    
    TERRAFORM_PASSPHRASE=$(cat "$passphrase_file" | tr -d '\n\r')
    if [[ -z "$TERRAFORM_PASSPHRASE" ]]; then
        log_error "Passphrase file is empty: $passphrase_file"
        exit 1
    fi
}

# Get or create GPG key for terraform state encryption
get_gpg_key() {
    local key_id="terraform-state@gbweb-iac"  # Fixed identifier, not hostname-dependent
    local existing_key=$(gpg --list-secret-keys --with-colons 2>/dev/null | grep "uid" | grep "$key_id" | head -1)
    
    if [[ -z "$existing_key" ]]; then
        log_warning "No GPG key found for Terraform state encryption."
        log_info "Searching for existing key with ID: $key_id"
        
        # Check if we should import an existing key first
        if [[ -f "$PROJECT_ROOT/.terraform-state-key.asc" ]]; then
            log_info "Found existing key file. Attempting to import..."
            if import_gpg_key; then
                log_success "Successfully imported existing GPG key"
            else
                log_warning "Failed to import existing key, will create new one"
            fi
        fi
        
        # Re-check after potential import
        existing_key=$(gpg --list-secret-keys --with-colons 2>/dev/null | grep "uid" | grep "$key_id" | head -1)
        
        if [[ -z "$existing_key" ]]; then
            log_warning "No GPG key found for Terraform state encryption with ID: $key_id"
            log_info "This requires creating a new GPG key for state encryption."
            log_warning "⚠️  Creating a new GPG key is an exceptional operation!"
            log_info "You should only do this if:"
            log_info "  1. This is your first time setting up encryption on any machine"
            log_info "  2. You've lost your original key and need to start fresh"
            log_info "  3. You're intentionally creating a new key system"
            echo ""
            echo -n "Do you want to create a new GPG key for Terraform state encryption? [y/N]: "
            read -r response
            case "$response" in
                [yY]|[yY][eE][sS])
                    log_info "User confirmed creating new GPG key."
                    create_new_gpg_key "$key_id"
                    ;;
                *)
                    log_info "GPG key creation cancelled by user."
                    log_error "Cannot proceed without a GPG key for encryption."
                    log_info "If you have an existing key:"
                    log_info "  1. Copy .terraform-state-key.asc and .terraform-state-passphrase from another machine"
                    log_info "  2. Run '$0 import-key' to import the existing key"
                    exit 1
                    ;;
            esac
        fi
    else
        # Key exists, just get the passphrase for later use
        get_or_create_passphrase
    fi
    
    # Get the key ID - search for our terraform-state key
    GPG_KEY_ID=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: -v email="terraform-state@gbweb-iac" '
        /^sec/ { key_id = $5 }
        /^uid/ && $10 ~ email { print key_id; exit }
    ')
    
    if [[ -z "$GPG_KEY_ID" ]]; then
        log_error "Could not find or create GPG key for Terraform state encryption"
        log_info "Debug: Searching for key with email: terraform-state@gbweb-iac"
        log_info "Available keys:"
        gpg --list-secret-keys --with-colons 2>/dev/null | grep -E "^(sec|uid)" | head -10
        exit 1
    fi
    
    log_info "Using GPG key: $GPG_KEY_ID"
}

# Create a new GPG key
create_new_gpg_key() {
    local key_id="$1"
    
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
    
    if gpg "${GPG_BATCH_OPTS[@]}" --generate-key /tmp/gpg-key-config; then
        # Securely remove the temporary file
        shred -vfz -n 3 /tmp/gpg-key-config 2>/dev/null || rm -f /tmp/gpg-key-config
        log_success "Created new GPG key for Terraform state encryption"
        
        # Export the key for portability
        export_gpg_key
    else
        # Securely remove the temporary file
        shred -vfz -n 3 /tmp/gpg-key-config 2>/dev/null || rm -f /tmp/gpg-key-config
        log_error "Failed to create GPG key"
        exit 1
    fi
}

# Export GPG key for portability between environments
export_gpg_key() {
    local key_file="$PROJECT_ROOT/.terraform-state-key.asc"
    
    log_info "Exporting GPG key for portability..."
    
    # Create a temporary passphrase file for GPG
    local temp_passphrase_file=$(mktemp)
    echo "$TERRAFORM_PASSPHRASE" > "$temp_passphrase_file"
    
    # Export the key using passphrase file
    if gpg "${GPG_BATCH_OPTS[@]}" --passphrase-file "$temp_passphrase_file" --export-secret-keys --armor "$GPG_KEY_ID" > "$key_file" 2>/dev/null; then
        chmod 600 "$key_file"
        log_success "GPG key exported to $key_file"
        log_warning "⚠️  IMPORTANT: This file contains your private key!"
        log_warning "⚠️  Make sure it's added to .gitignore and backup it securely!"
        
        # Check if .gitignore exists and add the key file
        local gitignore_file="$PROJECT_ROOT/.gitignore"
        if [[ -f "$gitignore_file" ]]; then
            if ! grep -q ".terraform-state-key.asc" "$gitignore_file"; then
                echo "" >> "$gitignore_file"
                echo "# Terraform state encryption key" >> "$gitignore_file"
                echo ".terraform-state-key.asc" >> "$gitignore_file"
                log_info "Added .terraform-state-key.asc to .gitignore"
            fi
        else
            log_warning "No .gitignore found. Please manually add .terraform-state-key.asc to your .gitignore!"
        fi
        
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
        return 0
    else
        # Clean up temporary file and empty key file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
        [[ -f "$key_file" ]] && rm -f "$key_file"
        
        log_error "Failed to export GPG key"
        log_error "This might be due to:"
        log_error "  1. Wrong passphrase in .terraform-state-passphrase file"
        log_error "  2. Key creation issues"
        log_info "Try regenerating the key with: $0 setup"
        return 1
    fi
}

# Import GPG key from file
import_gpg_key() {
    local key_file="$PROJECT_ROOT/.terraform-state-key.asc"
    
    if [[ ! -f "$key_file" ]]; then
        log_warning "No key file found at $key_file"
        return 1
    fi
    
    if [[ ! -s "$key_file" ]]; then
        log_error "Key file is empty: $key_file"
        return 1
    fi
    
    log_info "Importing GPG key from $key_file..."
    
    # Get the passphrase first
    get_or_create_passphrase
    
    # Create a temporary passphrase file for GPG
    local temp_passphrase_file=$(mktemp)
    echo "$TERRAFORM_PASSPHRASE" > "$temp_passphrase_file"
    
    # Import the key with passphrase file
    if gpg "${GPG_BATCH_OPTS[@]}" --passphrase-file "$temp_passphrase_file" --import "$key_file"; then
        log_success "GPG key imported successfully"
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
        return 0
    else
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
        log_error "Failed to import GPG key"
        log_error "This might be due to:"
        log_error "  1. Wrong passphrase in .terraform-state-passphrase file"
        log_error "  2. Corrupted key file"
        log_error "  3. Key already exists in keyring"
        return 1
    fi
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
    
    # Create a temporary passphrase file for GPG
    local temp_passphrase_file=$(mktemp)
    echo "$TERRAFORM_PASSPHRASE" > "$temp_passphrase_file"
    
    # Encrypt the file using asymmetric encryption with passphrase file
    if gpg "${GPG_BATCH_OPTS[@]}" --passphrase-file "$temp_passphrase_file" --encrypt --armor --recipient "$GPG_KEY_ID" --output "$encrypted_file" "$state_file"; then
        log_success "Encrypted $(basename "$state_file") → $(basename "$encrypted_file")"
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
        return 0
    else
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
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
    
    # Check which key was used to encrypt this file
    local encrypted_key_id=$(gpg --list-packets "$encrypted_file" 2>/dev/null | grep -o "keyid [A-F0-9]*" | cut -d' ' -f2)
    if [[ -n "$encrypted_key_id" ]]; then
        log_info "File was encrypted for key: $encrypted_key_id"
        
        # Check if we have the secret key for this encrypted file
        if ! gpg --list-secret-keys "$encrypted_key_id" &>/dev/null; then
            log_error "Missing private key for $encrypted_key_id required to decrypt $(basename "$encrypted_file")"
            log_error "This file was encrypted with a different GPG key than what's currently available."
            log_info "Available keys:"
            gpg --list-secret-keys --keyid-format=long | grep -E "^sec|^uid" | head -4
            log_warning "You may need to:"
            log_warning "  1. Import the correct private key that was used for encryption"
            log_warning "  2. Or re-encrypt this file with your current key"
            return 1
        fi
    fi
    
    # Check if plaintext file exists and is newer than encrypted file
    if [[ -f "$state_file" ]]; then
        if [[ "$state_file" -nt "$encrypted_file" ]]; then
            local conflict_file="${state_file}.conflict.$(date +%Y%m%d_%H%M%S)"
            log_warning "Plaintext file $(basename "$state_file") is newer than encrypted version!"
            log_info "Decrypting to conflict file: $(basename "$conflict_file")"
            
            # Create a temporary passphrase file for GPG
            local temp_passphrase_file=$(mktemp)
            echo "$TERRAFORM_PASSPHRASE" > "$temp_passphrase_file"
            
            # Decrypt to conflict file with passphrase file
            if gpg "${GPG_BATCH_OPTS[@]}" --passphrase-file "$temp_passphrase_file" --decrypt "$encrypted_file" > "$conflict_file"; then
                log_warning "⚠️  CONFLICT DETECTED!"
                log_warning "Original file: $(basename "$state_file")"
                log_warning "Decrypted file: $(basename "$conflict_file")"
                log_warning "Please review and resolve the conflict manually."
                log_info "You may need to:"
                log_info "  1. Compare the files: diff \"$state_file\" \"$conflict_file\""
                log_info "  2. Choose which version to keep"
                log_info "  3. Remove the conflict file after resolution"
                # Clean up temporary file
                shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
                return 0
            else
                # Clean up temporary file
                shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
                log_error "Failed to decrypt $encrypted_file to conflict file"
                return 1
            fi
        else
            log_info "Plaintext file exists but is older, overwriting..."
        fi
    fi
    
    log_info "Decrypting $(basename "$encrypted_file")..."
    
    # Create a temporary passphrase file for GPG
    local temp_passphrase_file=$(mktemp)
    echo "$TERRAFORM_PASSPHRASE" > "$temp_passphrase_file"
    
    # Decrypt the file with passphrase file
    if gpg "${GPG_BATCH_OPTS[@]}" --passphrase-file "$temp_passphrase_file" --decrypt "$encrypted_file" > "$state_file"; then
        log_success "Decrypted $(basename "$encrypted_file") → $(basename "$state_file")"
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
        return 0
    else
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
        log_error "Failed to decrypt $encrypted_file"
        log_error "This might be due to:"
        log_error "  1. Wrong passphrase in .terraform-state-passphrase file"
        log_error "  2. File was encrypted with a different key/passphrase"
        log_error "  3. Corrupted encrypted file"
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
    
    # Create a temporary passphrase file for GPG
    local temp_passphrase_file=$(mktemp)
    echo "$TERRAFORM_PASSPHRASE" > "$temp_passphrase_file"
    
    # Encrypt the file using asymmetric encryption with passphrase file
    if gpg "${GPG_BATCH_OPTS[@]}" --passphrase-file "$temp_passphrase_file" --encrypt --armor --recipient "$GPG_KEY_ID" --output "$encrypted_file" "$state_file"; then
        log_success "Encrypted $(basename "$state_file") → $(basename "$encrypted_file")"
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
        return 0
    else
        # Clean up temporary file
        shred -vfz -n 3 "$temp_passphrase_file" 2>/dev/null || rm -f "$temp_passphrase_file"
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
        log_info "Run '$0 encrypt' to encrypt all state files."
        return 1
    fi
    
    log_success "All state files have encrypted versions!"
    return 0
}

# Show usage
usage() {
    echo "Usage: $0 {encrypt|decrypt|cleanup|check|export-key|import-key|setup} [--force]"
    echo ""
    echo "Commands:"
    echo "  encrypt     - Encrypt all .tfstate files to .tfstate.gpg"
    echo "              - Uses asymmetric GPG encryption with dedicated key"
    echo "              - Asks for confirmation if encrypted file is newer"
    echo "  decrypt     - Decrypt all .tfstate.gpg files to .tfstate"
    echo "              - Uses asymmetric GPG decryption"
    echo "              - If plaintext file is newer, creates .conflict file instead"
    echo "  cleanup     - Remove plaintext .tfstate files (keep encrypted)"
    echo "  check       - Check if all state files have encrypted versions"
    echo "  export-key  - Export GPG key to .terraform-state-key.asc for portability"
    echo "  import-key  - Import GPG key from .terraform-state-key.asc"
    echo "  setup       - Initial setup: create key and passphrase if needed"
    echo ""
    echo "Options:"
    echo "  --force     - Skip confirmation prompts (use with encrypt)"
    echo ""
    echo "Examples:"
    echo "  $0 setup               # Initial setup on new environment"
    echo "  $0 encrypt             # Before committing to git (with confirmation)"
    echo "  $0 encrypt --force     # Force encrypt without confirmation"
    echo "  $0 decrypt             # After pulling from git"
    echo "  $0 export-key          # Export key for use on other machines"
    echo "  $0 import-key          # Import key on new machine"
    echo "  $0 cleanup             # Remove plaintext versions safely"
    echo ""
    echo "Multi-Environment Workflow:"
    echo "  1. On first machine: $0 setup && $0 export-key"
    echo "  2. Copy .terraform-state-passphrase and .terraform-state-key.asc securely"
    echo "  3. On new machine: place files, then $0 import-key"
    echo "  4. Use encrypt/decrypt as normal"
    echo ""
    echo "GPG Configuration:"
    echo "  - Uses fixed key identifier: terraform-state@gbweb-iac (hostname independent)"
    echo "  - Passphrase stored in .terraform-state-passphrase (auto-generated)"
    echo "  - Private key exported to .terraform-state-key.asc for portability"
    echo "  - Uses asymmetric encryption with secure passphrase from file"
    echo "  - GPG agent caches your key passphrase for the session"
    echo ""
    echo "Security Notes:"
    echo "  - Both .terraform-state-passphrase and .terraform-state-key.asc are auto-added to .gitignore"
    echo "  - Make sure to backup both files securely (outside of git)"
    echo "  - File permissions are set to 600 (owner read/write only)"
    echo "  - Use secure file transfer (scp, encrypted email, etc.) between machines"
    echo ""
    echo "Conflict Resolution:"
    echo "  - When encrypting: if encrypted file is newer, asks for confirmation"
    echo "  - When decrypting: if plaintext file is newer, creates .conflict file"
    echo "  Use 'diff' to compare and manually resolve conflicts."
}

# Main script logic
main() {
    # Setup GPG batch mode first
    setup_gpg_batch_mode
    check_gpg
    
    local command="${1:-}"
    local flag="${2:-}"
    
    case "$command" in
        setup)
            log_info "🔧 Initial setup for Terraform state encryption..."
            get_gpg_key
            log_success "Setup complete! You can now encrypt/decrypt state files."
            log_info "To use on other machines:"
            log_info "  1. Copy .terraform-state-passphrase and .terraform-state-key.asc securely"
            log_info "  2. Run '$0 import-key' on the new machine"
            ;;
        encrypt)
            get_gpg_key
            encrypt_all "$flag"
            ;;
        decrypt)
            get_gpg_key
            decrypt_all
            ;;
        cleanup)
            cleanup_plaintext
            ;;
        check)
            check_encrypted_versions
            ;;
        export-key)
            get_gpg_key
            export_gpg_key
            ;;
        import-key)
            import_gpg_key
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
