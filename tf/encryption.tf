terraform {
  encryption {
    key_provider "external" "sops_age" { command = ["./scripts/tofu-sops-key.sh"] }
    method "aes_gcm" "state_enc" { keys = key_provider.external.sops_age }
    state {
      method = method.aes_gcm.state_enc
      enforced = true
    }
    plan {
      method = method.aes_gcm.state_enc
      enforced = true
    }
  }
  backend "local" { path = "terraform.tfstate" }
}
