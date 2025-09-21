# Cloudflare Certificate Setup for Traefik

## Overview
This setup configures Traefik to use Cloudflare Origin Certificates for HTTPS-only operation.

## Steps to Setup

### 1. Generate Cloudflare Origin Certificate

1. Go to Cloudflare Dashboard → SSL/TLS → Origin Server
2. Click "Create Certificate"
3. Choose:
   - **Private key type**: RSA (2048)
   - **Hostnames**: `*.gbweb.fr, gbweb.fr`
   - **Certificate Validity**: 15 years (maximum)
4. Download both files:
   - `origin_cert.pem` (certificate)
   - `private_key.key` (private key)

### 2. Place Certificates

Copy the downloaded files to your server:

```bash
# Create certificates directory
mkdir -p /path/to/traefik/certs

# Copy and rename certificates
cp origin_cert.pem /path/to/traefik/certs/gbweb.fr.pem
cp private_key.key /path/to/traefik/certs/gbweb.fr-key.pem

# Set proper permissions
chmod 600 /path/to/traefik/certs/*.pem
chmod 600 /path/to/traefik/certs/*.key
```

### 3. Cloudflare SSL/TLS Settings

In Cloudflare Dashboard → SSL/TLS:

- **SSL/TLS encryption mode**: `Full (strict)`
- **Always Use HTTPS**: `On`
- **HTTP Strict Transport Security (HSTS)**: `Enable`
- **Minimum TLS Version**: `1.2`

### 4. Application Labels

For any application, use these Traefik labels:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.myapp.rule=Host(`myapp.gbweb.fr`)
  - traefik.http.routers.myapp.entrypoints=websecure
  - traefik.http.routers.myapp.tls=true
  - traefik.http.services.myapp.loadbalancer.server.port=80
  - traefik.docker.network=edge_rp
```

### 5. Deploy

```bash
# Restart Traefik to load new configuration
docker-compose -f traefik.yaml down
docker-compose -f traefik.yaml up -d

# Restart your applications to pick up new labels
docker-compose -f your-app/compose.yml down
docker-compose -f your-app/compose.yml up -d
```

## How it Works

1. **HTTP → HTTPS Redirect**: All HTTP requests are automatically redirected to HTTPS
2. **Cloudflare Origin Certificates**: Traefik uses Cloudflare-issued certificates for end-to-end encryption
3. **Security**: Traffic is encrypted from Cloudflare to your server using trusted certificates

## Testing

```bash
# Test HTTPS (should work)
curl https://test-app.gbweb.fr

# Test HTTP (should redirect to HTTPS)
curl -I http://test-app.gbweb.fr
# Should return: Location: https://test-app.gbweb.fr/
```

## Benefits

- ✅ **End-to-end encryption** from Cloudflare to your server
- ✅ **Automatic HTTP→HTTPS redirects** for all apps
- ✅ **Long-lived certificates** (15 years, no renewal needed)
- ✅ **Wildcard support** for all `*.gbweb.fr` subdomains
- ✅ **Zero configuration** for new apps (just add the labels)
