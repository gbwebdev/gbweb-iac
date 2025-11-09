terraform {
  encryption {
    key_provider "external" "sops_age" {
      command = ["./scripts/tofu-sops-key.sh"]
    }

    # AES-GCM; 32o in base64
    method "aes_gcm" "state_enc" {
      keys = key_provider.external.sops_age
    }

    # Enable ciphering for state and plan files
    state {
      method   = method.aes_gcm.state_enc
      enforced = true      # Force encryption
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
