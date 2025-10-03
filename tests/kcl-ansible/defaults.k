# Default pipeline parameters
default_params = {
    ansibleWorkingImage = "ghcr.io/stuttgart-things/sthings-ansible:11.0.0"
    createInventory = "false"
    ansibleTargetHost = "all"
    gitWorkspaceSubdirectory = "/ansible/workdir/"
    vaultSecretName = "vault" # pragma: allowlist secret
    installExtraRoles = "true"
}
