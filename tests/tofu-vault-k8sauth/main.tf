# Minimal end-to-end proof for the execute-tofu pipeline:
#   git-clone -> tofu init/apply -> Vault AppRole login -> policy allows the op.
#
# It creates one Kubernetes auth mount and reads it back — exactly the
# vault-k8sauth-bootstrap policy path (sys/auth create + read), nothing else,
# no kubeconfig/kubernetes provider. A failure is unambiguously the pipeline or
# the auth, not the surrounding module.
#
# Auth: the generic auth_login block against the approle login path (the
# established stuttgart-things pattern). role_id/secret_id arrive as
# TF_VAR_vault_role_id / TF_VAR_vault_secret_id — the execute-tofu task injects
# every key of its credentials Secret as env (envFrom), and Terraform maps
# TF_VAR_* onto variables. VAULT_ADDR comes from the vault Secret.
#
# ACTION=apply creates the mount; ACTION=destroy removes it.

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.25"
    }
  }
}

variable "vault_role_id" {
  type        = string
  description = "AppRole role_id (via TF_VAR_vault_role_id from the credentials Secret)"
}

variable "vault_secret_id" {
  type        = string
  sensitive   = true
  description = "AppRole secret_id (via TF_VAR_vault_secret_id from the credentials Secret)"
}

provider "vault" {
  # address from VAULT_ADDR (vault Secret, exported by the task)
  skip_tls_verify = true

  # The provider otherwise mints a short-lived child token via
  # auth/token/create for its operations — which the vault-k8sauth-bootstrap
  # policy deliberately forbids. Use the AppRole login token directly instead.
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"
    parameters = {
      role_id   = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}

variable "mount_path" {
  type        = string
  default     = "pipeline-test-certmanager"
  description = "Kubernetes auth mount this test creates"
}

resource "vault_auth_backend" "test" {
  type = "kubernetes"
  path = var.mount_path
}

output "mount_accessor" {
  value = vault_auth_backend.test.accessor
}
