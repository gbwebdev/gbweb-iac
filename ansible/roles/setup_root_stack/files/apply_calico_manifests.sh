#!/bin/bash

set -euo pipefail

CALICO_COMPOSE_DIR="/etc/manifests/docker-compose/system/calico"
DRY_RUN=false
VERBOSE=false

usage() {
    cat << EOF
Usage: $0 [OPTIONS] [FILE|DIR|-]

Apply Calico manifests using calicoctl via docker compose.

Arguments:
  FILE    Apply a single YAML file
  DIR     Apply all .yaml/.yml files in directory (recursively)
  -       Read from stdin (default if no argument provided)

Options:
  --dry-run           Perform a dry run without applying changes
  --verbose, -v       Enable verbose output
  --compose-dir DIR   Override Calico compose directory (default: $CALICO_COMPOSE_DIR)
  --help, -h          Show this help message

Examples:
  $0 manifest.yaml              # Apply single file
  $0 /etc/calico/rendered       # Apply directory
  $0 < manifest.yaml            # Apply from stdin
  cat manifest.yaml | $0       # Apply from pipe
  $0 --dry-run manifest.yaml   # Test without applying
EOF
}

log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[INFO] $*" >&2
    fi
}

error() {
    echo "[ERROR] $*" >&2
}

apply_manifest() {
    local input_source="$1"
    
    # Prepare calicoctl command
    local cmd=(docker compose run --rm -T calicoctl apply -f -)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        cmd+=(--dry-run)
        log "Performing dry run"
    fi
    
    # Add allow-version-mismatch to avoid version warnings
    cmd+=(--allow-version-mismatch)
    
    log "Executing: ${cmd[*]} (from $input_source)"
    
    # Run the command from the Calico compose directory
    cd "$CALICO_COMPOSE_DIR" || {
        error "Failed to change to Calico compose directory: $CALICO_COMPOSE_DIR"
        return 1
    }
    
    # Capture both stdout and stderr, but still show them
    local output
    local exit_code
    
    output=$("${cmd[@]}" 2>&1)
    exit_code=$?
    
    # Always show the output
    echo "$output"
    
    if [[ $exit_code -eq 0 ]]; then
        log "Successfully applied manifest from $input_source"
        return 0
    else
        error "Failed to apply manifest from $input_source (exit code: $exit_code)"
        return 1
    fi
}

apply_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        error "File not found: $file"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        error "File not readable: $file"
        return 1
    fi
    
    log "Applying file: $file"
    apply_manifest "$file" < "$file"
}

apply_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        error "Directory not found: $dir"
        return 1
    fi
    
    log "Applying directory: $dir"
    
    # Find all YAML files and concatenate them
    local yaml_files
    yaml_files=$(find "$dir" -type f \( -name "*.yaml" -o -name "*.yml" \))
    
    if [[ -z "$yaml_files" ]]; then
        log "No YAML files found in directory: $dir"
        return 0
    fi
    
    log "Found YAML files:"
    while IFS= read -r file; do
        log "  - $file"
    done <<< "$yaml_files"
    
    # Concatenate all YAML files and apply them as one batch
    # This is more efficient and reliable than applying individually
    if cat $yaml_files | apply_manifest "$dir"; then
        log "✓ Successfully applied all manifests from directory: $dir"
        return 0
    else
        error "✗ Failed to apply manifests from directory: $dir"
        return 1
    fi
}

apply_stdin() {
    log "Applying from stdin"
    apply_manifest "stdin"
}

main() {
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --compose-dir)
                CALICO_COMPOSE_DIR="$2"
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -)
                # Handle stdin explicitly before other option parsing
                break
                ;;
            -*)
                error "Unknown option: $1"
                usage >&2
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check if Calico compose directory exists
    if [[ ! -d "$CALICO_COMPOSE_DIR" ]]; then
        error "Calico compose directory not found: $CALICO_COMPOSE_DIR"
        exit 1
    fi
    
    # Determine input source
    if [[ $# -eq 0 ]]; then
        # No arguments, read from stdin
        apply_stdin
    elif [[ "$1" == "-" ]]; then
        # Explicit stdin
        apply_stdin
    elif [[ -f "$1" ]]; then
        # Single file
        apply_file "$1"
    elif [[ -d "$1" ]]; then
        # Directory
        apply_directory "$1"
    else
        error "Input not found or not accessible: $1"
        exit 1
    fi
}

main "$@"
