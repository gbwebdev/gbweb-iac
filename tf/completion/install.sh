#!/bin/bash
# Installation script for make completion

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_TYPE="${1:-auto}"

echo "🚀 Installing make completion for Terraform/OpenTofu Makefile..."

install_bash_completion() {
    local completion_file="$SCRIPT_DIR/make-completion.bash"
    
    if [[ -d "/etc/bash_completion.d" && -w "/etc/bash_completion.d" ]]; then
        echo "📝 Installing system-wide bash completion..."
        sudo cp "$completion_file" "/etc/bash_completion.d/make-terraform"
        echo "✅ System-wide installation complete"
        echo "💡 Restart your terminal or run: source /etc/bash_completion.d/make-terraform"
    elif [[ -d "$HOME/.bash_completion.d" ]]; then
        echo "📝 Installing user bash completion to ~/.bash_completion.d/..."
        cp "$completion_file" "$HOME/.bash_completion.d/make-terraform"
        echo "✅ User installation complete"
        echo "💡 Add this to your ~/.bashrc if not already present:"
        echo "   for f in ~/.bash_completion.d/*; do source \$f; done"
    else
        echo "📝 Installing user bash completion to ~/.bashrc..."
        mkdir -p "$HOME/.bash_completion.d"
        cp "$completion_file" "$HOME/.bash_completion.d/make-terraform"
        
        if ! grep -q "bash_completion.d" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# Load bash completions" >> "$HOME/.bashrc"
            echo "for f in ~/.bash_completion.d/*; do [[ -r \$f ]] && source \$f; done" >> "$HOME/.bashrc"
            echo "✅ Added completion loading to ~/.bashrc"
        fi
        echo "💡 Restart your terminal or run: source ~/.bashrc"
    fi
}

install_zsh_completion() {
    local completion_file="$SCRIPT_DIR/_make-terraform"
    
    # Try to find zsh completions directory
    if [[ -n "$ZSH" && -d "$ZSH/completions" ]]; then
        # Oh My Zsh
        echo "📝 Installing Oh My Zsh completion..."
        cp "$completion_file" "$ZSH/completions/_make-terraform"
        echo "✅ Oh My Zsh installation complete"
    elif [[ -d "$HOME/.oh-my-zsh/completions" ]]; then
        # Oh My Zsh (alternative path)
        echo "📝 Installing Oh My Zsh completion..."
        cp "$completion_file" "$HOME/.oh-my-zsh/completions/_make-terraform"
        echo "✅ Oh My Zsh installation complete"
    elif [[ -d "/usr/local/share/zsh/site-functions" && -w "/usr/local/share/zsh/site-functions" ]]; then
        # System-wide zsh
        echo "📝 Installing system-wide zsh completion..."
        sudo cp "$completion_file" "/usr/local/share/zsh/site-functions/_make-terraform"
        echo "✅ System-wide installation complete"
    else
        # User directory
        echo "📝 Installing user zsh completion..."
        mkdir -p "$HOME/.zsh/completions"
        cp "$completion_file" "$HOME/.zsh/completions/_make-terraform"
        
        # Add to fpath if not already there
        local zshrc="$HOME/.zshrc"
        if [[ -f "$zshrc" ]] && ! grep -q ".zsh/completions" "$zshrc"; then
            echo "" >> "$zshrc"
            echo "# Add custom completions to fpath" >> "$zshrc"
            echo "fpath=(~/.zsh/completions \$fpath)" >> "$zshrc"
            echo "autoload -U compinit && compinit" >> "$zshrc"
            echo "✅ Added completion directory to ~/.zshrc"
        fi
        echo "✅ User installation complete"
    fi
    echo "💡 Restart your terminal or run: exec zsh"
}

# Detect shell or use provided argument
if [[ "$SHELL_TYPE" == "auto" ]]; then
    if [[ -n "$ZSH_VERSION" ]]; then
        SHELL_TYPE="zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        SHELL_TYPE="bash"
    else
        echo "❓ Could not detect shell. Please specify: $0 [bash|zsh|both]"
        exit 1
    fi
fi

case "$SHELL_TYPE" in
    bash)
        install_bash_completion
        ;;
    zsh)
        install_zsh_completion
        ;;
    both)
        install_bash_completion
        echo ""
        install_zsh_completion
        ;;
    *)
        echo "❌ Unknown shell type: $SHELL_TYPE"
        echo "Usage: $0 [bash|zsh|both|auto]"
        exit 1
        ;;
esac

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📚 Usage examples:"
echo "  make <TAB>                    # Show all available targets"
echo "  make init ENV=<TAB>           # Complete environment names"
echo "  make tofu <TAB>               # Show tofu subcommands"
echo "  make tofu show ENV=<TAB>      # Complete environment for tofu command"
