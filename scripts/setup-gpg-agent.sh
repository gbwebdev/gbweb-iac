#!/bin/bash
# GPG Agent Configuration for Terraform State Encryption
# This script sets up optimal GPG agent configuration for password caching

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Create or update GPG agent configuration
setup_gpg_agent_config() {
    local gpg_home="${GNUPGHOME:-$HOME/.gnupg}"
    local agent_config="$gpg_home/gpg-agent.conf"
    
    # Create .gnupg directory if it doesn't exist
    if [[ ! -d "$gpg_home" ]]; then
        mkdir -p "$gpg_home"
        chmod 700 "$gpg_home"
        log_info "Created GPG home directory: $gpg_home"
    fi
    
    # Backup existing config if it exists
    if [[ -f "$agent_config" ]]; then
        cp "$agent_config" "$agent_config.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing GPG agent configuration"
    fi
    
    # Create optimized GPG agent configuration
    cat > "$agent_config" <<EOF
# GPG Agent Configuration for Terraform State Encryption
# Cache passwords for 8 hours (28800 seconds)
default-cache-ttl 28800
max-cache-ttl 28800

# Cache SSH keys for 8 hours
default-cache-ttl-ssh 28800
max-cache-ttl-ssh 28800

# Enable SSH support if needed
enable-ssh-support

# Use pinentry for password prompts
# Automatically detects the best pinentry program
pinentry-program $(which pinentry 2>/dev/null || echo pinentry-curses)

# Log level (basic, advanced, expert, guru)
log-file ~/.gnupg/gpg-agent.log
EOF
    
    chmod 600 "$agent_config"
    log_success "Created optimized GPG agent configuration"
    
    # Restart GPG agent to apply new configuration
    if pgrep gpg-agent >/dev/null; then
        log_info "Restarting GPG agent to apply new configuration..."
        gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true
        sleep 1
    fi
    
    # Start GPG agent if not running
    if ! pgrep gpg-agent >/dev/null; then
        log_info "Starting GPG agent..."
        gpg-agent --daemon >/dev/null 2>&1 || true
    fi
    
    log_success "GPG agent is configured and running"
}

# Check if required tools are available
check_dependencies() {
    local missing_tools=()
    
    if ! command -v gpg &> /dev/null; then
        missing_tools+=("gnupg")
    fi
    
    if ! command -v gpg-agent &> /dev/null; then
        missing_tools+=("gpg-agent")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warning "Missing required tools: ${missing_tools[*]}"
        log_info "Please install them using your package manager:"
        log_info "  Ubuntu/Debian: sudo apt install gnupg gpg-agent"
        log_info "  CentOS/RHEL: sudo yum install gnupg2"
        log_info "  macOS: brew install gnupg"
        exit 1
    fi
}

# Display configuration information
show_info() {
    echo ""
    log_info "GPG Agent Configuration Summary:"
    echo "  • Password cache duration: 8 hours"
    echo "  • Configuration file: ${GNUPGHOME:-$HOME/.gnupg}/gpg-agent.conf"
    echo "  • Agent status: $(pgrep gpg-agent >/dev/null && echo "Running" || echo "Not running")"
    echo ""
    log_info "Usage with Terraform state encryption:"
    echo "  1. Run this setup script once: $0"
    echo "  2. Use tfstate-crypto.sh normally"
    echo "  3. Enter your GPG key password once per 8-hour session"
    echo ""
    log_info "To check agent status: gpg-connect-agent 'keyinfo --list' /bye"
    log_info "To clear cache manually: gpg-connect-agent reloadagent /bye"
}

main() {
    log_info "Setting up GPG agent for Terraform state encryption..."
    
    check_dependencies
    setup_gpg_agent_config
    show_info
    
    log_success "GPG agent setup complete!"
    log_info "You can now use tfstate-crypto.sh with password caching enabled."
}

main "$@"
