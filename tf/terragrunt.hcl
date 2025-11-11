terraform_binary = "tofu"

locals {
  ws     = get_env("TF_WORKSPACE", "dev")
  envdir = "environments/${local.ws}"
  clear  = jsondecode(file("${local.envdir}/${local.ws}.tfvars.json"))
  secret = jsondecode(sops_decrypt_file("${local.envdir}/${local.ws}.secrets.sops.tfvars.json"))
}

terraform {
  after_hook "assert_no_plaintext_state" {
    commands = ["plan", "apply"]
    execute  = [
      "bash",
      "-lc",
      <<-EOT
        set -e
        for f in terraform.tfstate terraform.tfstate.d/*/terraform.tfstate; do
          [ -e "$f" ] || continue
          if jq -e . "$f" >/dev/null 2>&1; then
            if jq -e 'has("encrypted_data") and has("encryption_version")' "$f" >/dev/null; then
              echo "✓ encrypted state: $f"
            else
              echo "❌ plaintext tfstate: $f"
              exit 1
            fi
          else
            echo "❌ unreadable/non-JSON state: $f"
            exit 1
          fi
        done
      EOT
    ]
  }
}



inputs = merge(local.clear, local.secret)
