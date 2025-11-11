#!/usr/bin/env python3
"""
Docker Network Policy Host Endpoints Manager

This script discovers Docker networks with netpol.* labels, generates
Calico HostEndpoint manifests for them, and applies them using calicoctl.
"""

import json
import subprocess
import sys
import tempfile
import yaml
from typing import List, Dict, Any


def run_command(cmd: List[str]) -> str:
    """Run a command and return its output."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command {' '.join(cmd)}: {e}", file=sys.stderr)
        sys.exit(1)


def get_docker_networks() -> List[Dict[str, Any]]:
    """Get all Docker networks and return those with netpol labels."""
    # Get all network IDs
    network_ids = run_command(['docker', 'network', 'ls', '--format', '{{.ID}}'])
    if not network_ids:
        return []
    
    networks = []
    for net_id in network_ids.split('\n'):
        if not net_id:
            continue
            
        # Inspect each network
        inspect_output = run_command(['docker', 'network', 'inspect', net_id])
        network_data = json.loads(inspect_output)[0]
        
        # Check if network has netpol labels
        labels = network_data.get('Labels', {})
        if labels and 'netpol.app' in labels:
            networks.append(network_data)
    
    return networks


def generate_hep_manifest(network: Dict[str, Any], node_name: str) -> Dict[str, Any]:
    """Generate a Calico HostEndpoint manifest for a network."""
    labels = network.get('Labels', {})
    options = network.get('Options', {})
    
    # Extract interface name from bridge options
    bridge_name = options.get('com.docker.network.bridge.name', '')
    if not bridge_name:
        print(f"Warning: No bridge name found for network {network['Name']}", file=sys.stderr)
        return None
    
    app_name = labels.get('netpol.app', 'unknown')
    app_id = labels.get('netpol.app_id', 'unknown')
    role_name = labels.get('netpol.role', 'unknown')
    
    hep_manifest = {
        'apiVersion': 'projectcalico.org/v3',
        'kind': 'HostEndpoint',
        'metadata': {
            'name': bridge_name,
            'labels': {
                'app': app_name,
                'app-id': app_id,
                'role': role_name
            }
        },
        'spec': {
            'node': node_name,
            'interfaceName': bridge_name
        }
    }
    
    return {
        'manifest': hep_manifest,
        'filename': f"hep-{app_name}-{role_name}.yaml",
        'network_name': network['Name'],
        'bridge_name': bridge_name,
        'labels': labels
    }


def apply_hep_manifest(manifest: Dict[str, Any], dry_run: bool = False) -> bool:
    """Apply a HostEndpoint manifest using the apply_calico_manifests.sh helper."""
    try:
        # Convert manifest to YAML string
        manifest_yaml = yaml.dump(manifest, default_flow_style=False)
        
        # Use the helper script
        cmd = ['/usr/local/bin/apply_calico_manifests.sh']
        
        if dry_run:
            cmd.append('--dry-run')
        
        # Don't add '-' explicitly - let the script default to stdin when no args
        
        result = subprocess.run(
            cmd, 
            input=manifest_yaml, 
            capture_output=True, 
            text=True, 
            check=True
        )
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error applying manifest: {e.stderr}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Unexpected error applying manifest: {e}", file=sys.stderr)
        return False


def main():
    """Main function."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Manage Docker network HostEndpoints')
    parser.add_argument('node_name', help='Name of the Kubernetes node')
    parser.add_argument('--apply', action='store_true', help='Apply the HostEndpoints to Calico')
    parser.add_argument('--dry-run', action='store_true', help='Perform a dry run (with --apply)')
    parser.add_argument('--output-dir', help='Directory to write YAML files (optional)')
    
    args = parser.parse_args()
    
    # Get networks with netpol labels
    networks = get_docker_networks()
    
    if not networks:
        if args.apply:
            print("No networks with netpol labels found")
            return
        else:
            print("[]")  # Return empty JSON array for Ansible
            return
    
    # Generate HEP data for each network
    heps = []
    applied_count = 0
    failed_count = 0
    
    for network in networks:
        hep_data = generate_hep_manifest(network, args.node_name)
        if not hep_data:
            continue
            
        heps.append(hep_data)
        
        # Write to file if output directory specified
        if args.output_dir:
            import os
            os.makedirs(args.output_dir, exist_ok=True)
            output_file = os.path.join(args.output_dir, hep_data['filename'])
            with open(output_file, 'w') as f:
                yaml.dump(hep_data['manifest'], f, default_flow_style=False)
            print(f"Written: {output_file}")
        
        # Apply if requested
        if args.apply:
            print(f"Applying HostEndpoint for network {network['Name']} -> {hep_data['bridge_name']}")
            if apply_hep_manifest(hep_data['manifest'], args.dry_run):
                applied_count += 1
                if not args.dry_run:
                    print(f"✓ Applied HostEndpoint {hep_data['manifest']['metadata']['name']}")
                else:
                    print(f"✓ Dry-run successful for HostEndpoint {hep_data['manifest']['metadata']['name']}")
            else:
                failed_count += 1
                print(f"✗ Failed to apply HostEndpoint {hep_data['manifest']['metadata']['name']}")
    
    # Output results
    if args.apply:
        print(f"\nSummary: {applied_count} applied, {failed_count} failed")
        if failed_count > 0:
            sys.exit(1)
    else:
        # Output as JSON for Ansible to consume
        print(json.dumps(heps, indent=2))


if __name__ == '__main__':
    main()
