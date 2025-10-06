# Default pipeline parameters
_default_params = {
    ansibleWorkingImage = "ghcr.io/stuttgart-things/sthings-ansible:11.0.0"
    createInventory = "false"
    ansibleTargetHost = "all"
    gitWorkspaceSubdirectory = "/ansible/workdir/"
    vaultSecretName = "vault" # pragma: allowlist secret
    installExtraRoles = "true"
}

_task_run_template = {
    serviceAccountName = "default"
}

_timeouts = {
  pipeline = "1h0m0s"
}
