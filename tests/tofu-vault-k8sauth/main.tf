# Minimal end-to-end proof for the execute-tofu pipeline:
#   git-clone -> tofu init/apply -> Vault AppRole login -> policy allows the op.
#
# It creates a single Kubernetes auth mount and reads it back. That exercises
# exactly the vault-k8sauth-bootstrap policy path (sys/auth create + read) with
# nothing else, and no kubeconfig/kubernetes provider — so a failure is
# unambiguously the pipeline or the auth, not the surrounding module.
#
# ACTION=apply creates the mount; ACTION=destroy removes it.

terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      # Pinned to 3.x: auth_login_approle reads role_id/secret_id from the
      # VAULT_ROLE_ID / VAULT_SECRET_ID env vars the execute-tofu task exports.
      # v4/v5 reworked the auth blocks and reject auth_login_approle as written.
      version = "~> 3.25"
    }
  }
}

provider "vault" {
  # address from VAULT_ADDR (set by the execute-tofu task from the vault Secret)
  skip_tls_verify = true

  # role_id / secret_id are read from VAULT_ROLE_ID / VAULT_SECRET_ID env,
  # which the task exports from the same Secret. Nothing sensitive in tfvars.
  # role_id / secret_id come from VAULT_ROLE_ID / VAULT_SECRET_ID (env),
  # exported by the execute-tofu task from the vault Secret.
  auth_login_approle {}
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
