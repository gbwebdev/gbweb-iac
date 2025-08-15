# Production environment variables
project_name = "gbweb"
environment  = "production"
domain       = "gbweb.fr" 

# Hetzner configuration for production
hetzner_server_name      = "ha-server" 
hetzner_server_type      = "cx32"      # 4 vCPU, 8GB RAM
hetzner_data_volume_size = 10 
hetzner_server_location  = "fsn1"      # nbg1 (Nuremberg), fsn1 (Falkenstein), hel1 (Helsinki), ash (Ashburn), hil (Hillsboro)

# Enable secondary IPs for production
hetzner_enable_secondary_ipv4 = false
hetzner_enable_secondary_ipv6 = false


ionos_gateway_name      = "gw"