# Default pipeline parameters
_default_params = {
    createInventory = "false"
    ansibleTargetHost = "all"
    gitWorkspaceSubdirectory = "/ansible/workdir/"
    # pragma: allowlist secret
    vaultSecretName = "vault"
    installExtraRoles = "true"
    installExtraCollections = "true"
    # Add these new default parameters:
    ansibleVarsInventory = []
    ansibleVarsFile = []
    userHome = "/home/nonroot"
    # pragma: allowlist secret
    ansibleCredentialsSecretName = "ansible-credentials"
    ansibleCredentialsUserKey = "ANSIBLE_USER"
    # pragma: allowlist secret
    ansibleCredentialsPasswordKey = "ANSIBLE_PASSWORD"
    varsFile = ""
}

_task_run_template = {
    serviceAccountName = "default"
}

_timeouts = {
    pipeline = "1h0m0s"
}
