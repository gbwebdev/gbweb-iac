#!/usr/bin/env bash
set -euo pipefail

# Protocole attendu par OpenTofu (key provider externe)
echo '{"magic":"OpenTofu-External-Key-Provider","version":1}'

# Workspace courant (OpenTofu/Terraform expose TF_WORKSPACE)
WS="${TF_WORKSPACE:-default}"
FILE="keys/tofu-${WS}.sops.yaml"
[ -f "$FILE" ] || FILE="keys/tofu-default.sops.yaml"

# On extrait via sops la valeur base64 (32 octets)
KEY_B64="$(sops -d --extract '["tofu_state_key_base64"]' "$FILE")"

cat <<JSON
{
  "keys": {
    "encryption_key": "${KEY_B64}",
    "decryption_key": "${KEY_B64}"
  },
  "meta": {}
}
JSON
