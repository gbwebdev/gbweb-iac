# 🏗️ OpenTofu (Terraform) Infra

This directory contains the **OpenTofu** + **Terragrunt** configuration for my infrastructure.  
It manages Cloudflare DNS, Hetzner cloud resources, and other components in a secure, fully reproducible way.

## 🧩 Requirements

These tools must be installed locally or in your CI environment:

| Component | Purpose | Minimum version | Install hint |
|------------|----------|-----------------|---------------|
| **[OpenTofu](https://opentofu.org/)** | Terraform-compatible IaC engine | ≥ 1.6 | `sudo apt install opentofu` or download binary |
| **[Terragrunt](https://terragrunt.gruntwork.io/)** | Wrapper for orchestration, hooks & envs | ≥ 0.58 | `go install github.com/gruntwork-io/terragrunt@latest` |
| **[SOPS](https://github.com/getsops/sops)** | Encrypt/decrypt secrets | ≥ 3.8 | `sudo apt install sops` |
| **[Age](https://github.com/FiloSottile/age)** | Encryption backend for SOPS | ≥ 1.1 | `sudo apt install age` |
| **jq** | Lightweight JSON processor (for hooks/tests) | ≥ 1.6 | `sudo apt install jq` |
| **bash** | Required for Terragrunt hooks | any | built-in on Linux |


## 🔐 Security Principles

- **State & plan encryption** — every `terraform.tfstate` and `plan` file is AES-GCM encrypted using OpenTofu’s native encryption mechanism.  
  Keys are managed via **SOPS** and stored in `./keys/*.sops.yaml`.
- **Secrets encryption** — all sensitive variables (API tokens, passwords, etc.) are kept in SOPS-encrypted files using **Age** recipients.
- **Zero plaintext state guarantee** — a Terragrunt hook verifies that no unencrypted state file is ever produced.
- **Ephemeral decryption** — secrets are decrypted in-memory during `plan` / `apply`, never written to disk.


## 🗂️ Directory Structure

```

tf/
├── encryption.tf                  # OpenTofu encryption configuration
├── environments/
│   ├── dev/
│   │   ├── dev.tfvars.json        # non-sensitive variables
│   │   └── dev.secrets.sops.tfvars.json  # encrypted secrets
│   └── prod/
│       ├── prod.tfvars.json
│       └── prod.secrets.sops.tfvars.json
├── keys/
│   └── tofu-default.sops.yaml     # encrypted state-encryption key
├── modules/
│   ├── cloudflare/                # DNS & domain management
│   └── hetzner/                   # VM provisioning, cloud-init templates
├── scripts/
│   └── tofu-sops-key.sh           # external key provider for OpenTofu
├── terragrunt.hcl                 # orchestration, inputs, and hooks
├── main.tf                        # root OpenTofu configuration
├── variables.tf                   # variable declarations
├── outputs.tf                     # useful outputs
└── terraform.tfstate.d/           # encrypted states per workspace

```

## 🚀 Workflow

### 1️⃣ Setup

Install dependencies:

```bash
sudo apt install opentofu terragrunt jq
# and ensure SOPS + AGE are installed:
sudo apt install sops age
```

Create an Age key (once per user):

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

### 2️⃣ Initialize

```bash
export TF_WORKSPACE=prod     # or dev, staging, etc.
terragrunt init
```

### 3️⃣ Plan & Apply

```bash
terragrunt plan
terragrunt apply
```

Terragrunt automatically:

* merges clear vars (`environments/<ws>/<ws>.tfvars.json`) and secrets (`.sops.tfvars.json`),
* decrypts secrets in memory using SOPS,
* enforces encrypted state and plan outputs.

### 4️⃣ Import existing resources

```bash
terragrunt import <RESOURCE_ADDRESS> <RESOURCE_ID>
# Example:
terragrunt import module.cloudflare.cloudflare_zone.gbweb_fr ZONE_ID
```

## 🔁 Rotating Encryption Keys

When rotating Age keys:

```bash
sops updatekeys -r .
```

## 🛡️ Safety Hooks

* `assert_no_plaintext_state` — checks every run for any unencrypted state.
* Fails the pipeline immediately if plaintext is detected.


## 🧰 Useful Commands

| Task                        | Command                                                                    |
| --------------------------- | -------------------------------------------------------------------------- |
| Initialize                  | `terragrunt init`                                                          |
| Plan changes                | `terragrunt plan`                                                          |
| Apply changes               | `terragrunt apply`                                                         |
| List resources              | `terragrunt state list`                                                    |
| Show resource               | `terragrunt state show <address>`                                          |
| Re-encrypt all secrets      | `sops updatekeys -r .`                                                     |
| Check if state is encrypted | `jq -e 'has("encrypted_data")' terraform.tfstate.d/prod/terraform.tfstate` |


## 🧩 Design Notes

* **Terragrunt** provides environment isolation, variable merging, and hooks for security checks.
* **OpenTofu** ensures encrypted state and compatibility with Terraform HCL.
* **SOPS + Age** handle all secret management simply and transparently.
* **No Makefile required** — one consistent workflow via Terragrunt.


## 📜 License

This project is licensed under the [MIT License](./LICENSE).
