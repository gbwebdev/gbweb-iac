#!/usr/bin/env python3

import yaml
import sys
import json
import argparse
from pathlib import Path

def add_labels_to_compose(compose_data, labels):
    """Add labels to all services, networks, and volumes in compose data"""
    
    # Add labels to services
    if 'services' in compose_data:
        for service_name, service_config in compose_data['services'].items():
            if 'labels' not in service_config:
                service_config['labels'] = {}
            elif isinstance(service_config['labels'], list):
                # Convert list format to dict format
                label_dict = {}
                for label in service_config['labels']:
                    if '=' in label:
                        key, value = label.split('=', 1)
                        label_dict[key] = value
                service_config['labels'] = label_dict
            
            service_config['labels'].update(labels)
            
            if service_config['labels'].get('traefik.enable', 'false') == 'true':
                service_config['labels'][f'traefik.http.routers.${instance_short_id}.rule'] = f'Host(`{fqdn}`)'
                service_config['labels'][f'traefik.http.routers.${instance_short_id}.entrypoints'] = 'websecure'
                service_config['labels'][f'traefik.http.routers.${instance_short_id}.tls'] = 'true'
                service_config['labels'][f'traefik.http.services.${instance_short_id}.loadbalancer.server.port'] = service_config['labels'].get('traefik.port', '80')
                service_config['labels']['traefik.docker.network'] = 'edge_rp'
    
    # Add labels to networks
    if 'networks' in compose_data:
        for network_name, network_config in compose_data['networks'].items():
            if network_config is None:
                network_config = {}
                compose_data['networks'][network_name] = network_config
            if 'labels' not in network_config:
                network_config['labels'] = {}
            network_config['labels'].update(labels)
    
    # Add labels to volumes
    if 'volumes' in compose_data:
        for volume_name, volume_config in compose_data['volumes'].items():
            if volume_config is None:
                volume_config = {}
                compose_data['volumes'][volume_name] = volume_config
            if 'labels' not in volume_config:
                volume_config['labels'] = {}
            volume_config['labels'].update(labels)
    
    return compose_data

def main():
    parser = argparse.ArgumentParser(description='Add labels to Docker Compose files')
    parser.add_argument('output_file', help='Output file path for the rendered compose file')
    parser.add_argument('--labels', help='JSON string containing labels to add', default='{}')
    parser.add_argument('--input', '-i', help='Input compose file (default: stdin)', type=argparse.FileType('r'), default=sys.stdin)
    parser.add_argument('--instance-id', help='Instance ID to use in labels', required=True)
    parser.add_argument('--instance-short-id', help='Instance short ID to use in labels', required=True)
    parser.add_argument('--instance-ref', help='Instance reference to use in labels', required=True)
    parser.add_argument('--fqdn', help='Fully Qualified Domain Name to use in labels', required=True)
    parser.add_argument('--app-id', help='App ID to use in labels', required=True)
    parser.add_argument('--app-short-id', help='App short ID to use in labels', required=True)

    args = parser.parse_args()
    
    # Parse labels from JSON
    labels = json.loads(args.labels)
    
    # Read compose data from input
    compose_data = yaml.safe_load(args.input)
    
    # Add labels
    labeled_compose = add_labels_to_compose(compose_data, labels)
    
    # Write to output file
    with open(args.output_file, 'w') as f:
        if args.format == 'json':
            json.dump(labeled_compose, f, indent=2)
        else:
            yaml.dump(labeled_compose, f, default_flow_style=False, sort_keys=False)

if __name__ == "__main__":
    main()




# Todo :
- Auto rename networks
   edge_rp => zz_edge_rp
   XX_name => XX_INSTANCE_SHORT_ID_name
- Replace "__INSTANCE_SHORT_ID__" in interface name
- Inject labels everywhere
- Add netpol labels in networks