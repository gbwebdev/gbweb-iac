terraform_binary = "tofu"

locals {
  ws     = get_env("TF_WORKSPACE", "dev")
  envdir = "environments/${local.ws}"
  clear  = jsondecode(read_file("${local.envdir}/${local.ws}.tfvars.json"))
  secret = jsondecode(sops_decrypt_file("${local.envdir}/${local.ws}.secrets.sops.tfvars.json"))
}

terraform {
  before_hook "ensure_workspace" {
    commands = ["init", "plan", "apply", "destroy"]
    execute  = ["bash", "-lc", "tofu workspace select ${TF_WORKSPACE:-dev} || tofu workspace new ${TF_WORKSPACE:-dev}"]
  }

  after_hook "assert_no_plaintext_state" {
    commands = ["plan", "apply"]
    execute  = [
      "bash", "-lc",
      "set -e; for f in terraform.tfstate terraform.tfstate.d/*/terraform.tfstate; do [ -e \"$f\" ] || continue; if jq -e . \"$f\" >/dev/null 2>&1; then echo '❌ Plaintext tfstate detected: ' \"$f\"; exit 1; fi; done"
    ]
  }
}

generate "encryption" {
  path      = "terraform/encryption.auto.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<HCL
terraform {
  encryption {
    key_provider "external" "sops_age" {
      command = ["./scripts/tofu-sops-key.sh"]
    }
    method "aes_gcm" "state_enc" {
      keys = key_provider.external.sops_age
    }
    state {
      method   = method.aes_gcm.state_enc
      enforced = true
    }
    plan {
      method   = method.aes_gcm.state_enc
      enforced = true
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}
HCL
}

inputs = merge(local.clear, local.secret)
