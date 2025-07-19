#!/bin/bash
# Bash completion for Terraform/OpenTofu Makefile
# Usage: source this file or place it in /etc/bash_completion.d/

_make_terraform_completion() {
    local cur prev opts environments
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Available make targets
    opts="help init plan apply destroy tofu
          edit-secrets setup-secrets check-secrets
          edit-variables setup-variables check-variables
          encrypt-states decrypt-states cleanup-states check-states
          workspace-list workspace-new workspace-select workspace-current
          fmt validate"
    
    # Available environments
    environments="production staging development"
    
    # If previous word was ENV=, complete with environments
    if [[ ${prev} == "ENV=" ]]; then
        COMPREPLY=( $(compgen -W "${environments}" -- ${cur}) )
        return 0
    fi
    
    # If current word starts with ENV=, complete with environments
    if [[ ${cur} == ENV=* ]]; then
        local env_part="${cur#ENV=}"
        COMPREPLY=( $(compgen -W "${environments}" -P "ENV=" -- ${env_part}) )
        return 0
    fi
    
    # Special handling for tofu command - allow any tofu subcommands
    if [[ ${COMP_WORDS[1]} == "tofu" && ${COMP_CWORD} -gt 1 ]]; then
        # Common tofu commands
        local tofu_cmds="show output import state plan apply destroy init validate fmt
                        providers lock refresh console graph get taint untaint
                        force-unlock"
        
        # If we're not completing ENV=, suggest tofu commands
        if [[ ${cur} != ENV=* && ${prev} != "ENV=" ]]; then
            COMPREPLY=( $(compgen -W "${tofu_cmds} ENV=" -- ${cur}) )
            return 0
        fi
    fi
    
    # Default completion for make targets
    if [[ ${cur} == -* ]]; then
        # Make options
        COMPREPLY=( $(compgen -W "-f -C -j -k -n -q -s -t -v" -- ${cur}) )
    else
        # Combine targets with ENV= option
        local all_opts="${opts} ENV="
        COMPREPLY=( $(compgen -W "${all_opts}" -- ${cur}) )
    fi
    
    return 0
}

# Register completion for make when in terraform directory or when Makefile contains terraform/tofu
_make_terraform_check() {
    if [[ -f "Makefile" ]] && grep -q "tofu\|terraform" Makefile 2>/dev/null; then
        complete -F _make_terraform_completion make
    fi
}

# Auto-enable when sourced
_make_terraform_check
