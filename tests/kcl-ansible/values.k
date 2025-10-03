# Environment-specific overrides
override_params = {
    ansibleWorkingImage = "ghcr.io/stuttgart-things/sthings-ansible:12.0.0"
    gitRepoUrl = "https://github.com/stuttgart-things/stage-time.git"
    gitRevision = "main"
    inventory = "MTAuMzEuMTAzLjI3Cg=="
    ansibleExtraRoles = [
        "https://github.com/stuttgart-things/install-requirements.git,2024.05.11"
        "https://github.com/stuttgart-things/manage-filesystem.git,2024.06.07"
        "https://github.com/stuttgart-things/install-configure-vault.git"
        "https://github.com/stuttgart-things/create-send-webhook.git,2024-06-06"
    ]
}
