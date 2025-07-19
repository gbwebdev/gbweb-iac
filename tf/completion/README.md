# Makefile Autocompletion

This directory contains autocompletion scripts for the Terraform/OpenTofu Makefile, supporting both bash and zsh shells.

## Features

✨ **Smart Completion**:
- All Makefile targets with descriptions
- Environment names (`production`, `staging`, `development`)
- OpenTofu subcommands when using `make tofu`
- Automatic `ENV=` parameter completion

🚀 **Supported Commands**:
- `make <TAB>` - Shows all available targets
- `make init ENV=<TAB>` - Completes environment names
- `make tofu <TAB>` - Shows OpenTofu subcommands
- `make tofu show ENV=<TAB>` - Completes environment for tofu commands

## Quick Installation

### Automatic Installation (Recommended)
```bash
# Auto-detect your shell and install
cd tf/completion
./install.sh

# Or specify your shell explicitly
./install.sh bash    # For bash only
./install.sh zsh     # For zsh only
./install.sh both    # For both shells
```

### Manual Installation

#### Bash
```bash
# System-wide (requires sudo)
sudo cp make-completion.bash /etc/bash_completion.d/make-terraform

# User-specific
mkdir -p ~/.bash_completion.d
cp make-completion.bash ~/.bash_completion.d/make-terraform
echo 'for f in ~/.bash_completion.d/*; do [[ -r $f ]] && source $f; done' >> ~/.bashrc
```

#### Zsh
```bash
# Oh My Zsh
cp _make-terraform ~/.oh-my-zsh/completions/

# System-wide (requires sudo)
sudo cp _make-terraform /usr/local/share/zsh/site-functions/

# User-specific
mkdir -p ~/.zsh/completions
cp _make-terraform ~/.zsh/completions/
echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
echo 'autoload -U compinit && compinit' >> ~/.zshrc
```

## Usage Examples

### Basic Target Completion
```bash
make <TAB>
# Shows: help, init, plan, apply, destroy, tofu, edit-secrets, etc.
```

### Environment Completion
```bash
make init ENV=<TAB>
# Shows: production, staging, development

make plan ENV=prod<TAB>
# Completes to: make plan ENV=production
```

### OpenTofu Command Completion
```bash
make tofu <TAB>
# Shows: show, output, import, state, plan, apply, destroy, etc.

make tofu show ENV=<TAB>
# Shows: production, staging, development
```

### Advanced Examples
```bash
# Complete tofu state subcommands
make tofu state <TAB>
# Shows: list, show, mv, rm, etc.

# Complete import command
make tofu import aws_instance.example i-1234567890abcdef0 ENV=<TAB>
# Shows: production, staging, development
```

## Shell Detection

The completion scripts automatically detect when they should be active by:
1. Checking if a `Makefile` exists in the current directory
2. Verifying the Makefile contains terraform/tofu commands

This prevents the completion from interfering with other projects.

## Troubleshooting

### Completion Not Working
1. **Restart your terminal** or source your shell config:
   ```bash
   # Bash
   source ~/.bashrc
   
   # Zsh
   exec zsh
   ```

2. **Check if completion is loaded**:
   ```bash
   # Bash
   complete -p make
   
   # Zsh
   which _make-terraform
   ```

3. **Verify file permissions**:
   ```bash
   ls -la completion/
   # install.sh should be executable
   ```

### Environment Variables
If you're using the `TERRAFORM_ENV` environment variable, the completion will work with that too:
```bash
export TERRAFORM_ENV=production
make plan  # Will use production environment
make tofu show  # Will use production environment
```

## File Structure
```
completion/
├── README.md                 # This file
├── install.sh               # Automatic installer
├── make-completion.bash     # Bash completion script
└── _make-terraform          # Zsh completion script
```

## Contributing

Feel free to enhance the completion scripts with:
- Additional OpenTofu subcommands
- More intelligent context awareness
- Support for other shells (fish, etc.)

The completion scripts are designed to be maintainable and easy to extend.
