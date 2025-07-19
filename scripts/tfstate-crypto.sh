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

# Check if GPG is available
check_gpg() {
    if ! command -v gpg &> /dev/null; then
        log_error "GPG is not installed. Please install gnupg."
        exit 1
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
    
    # Encrypt the file
    if gpg --symmetric --cipher-algo AES256 --compress-algo 1 --quiet --batch --yes --output "$encrypted_file" "$state_file"; then
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
            if gpg --quiet --batch --yes --decrypt "$encrypted_file" > "$conflict_file"; then
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
    if gpg --quiet --batch --yes --decrypt "$encrypted_file" > "$state_file"; then
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
    
    # Encrypt the file
    if gpg --symmetric --cipher-algo AES256 --compress-algo 1 --quiet --batch --yes --output "$encrypted_file" "$state_file"; then
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
    echo "           - Asks for confirmation if encrypted file is newer"
    echo "  decrypt  - Decrypt all .tfstate.gpg files to .tfstate"
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
    echo "Conflict Resolution:"
    echo "  - When encrypting: if encrypted file is newer, asks for confirmation"
    echo "  - When decrypting: if plaintext file is newer, creates .conflict file"
    echo "  Use 'diff' to compare and manually resolve conflicts."
}

# Main script logic
main() {
    check_gpg
    
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
