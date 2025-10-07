import .schema

# Environment-specific overrides with defaults
_ansibleWorkingImage = option("ansibleWorkingImage") or "ghcr.io/stuttgart-things/sthings-ansible:12.0.0"
_gitRepoUrl = option("gitRepoUrl") or "https://github.com/stuttgart-things/stage-time.git"
_gitRevision = option("gitRevision") or "main"
_inventory = option("inventory") or "MTAuMzEuMTAzLjI3Cg=="
_ansibleExtraRoles = option("ansibleExtraRoles") or [
    "https://github.com/stuttgart-things/install-requirements.git,2024.05.11"
    "https://github.com/stuttgart-things/manage-filesystem.git,2024.06.07"
    "https://github.com/stuttgart-things/install-configure-vault.git"
    "https://github.com/stuttgart-things/create-send-webhook.git,2024-06-06"
]

# Inline validation for immediate feedback
assert _ansibleWorkingImage.startswith("ghcr.io/") or \
       _ansibleWorkingImage.startswith("docker.io/") or \
       _ansibleWorkingImage.startswith("quay.io/"), \
       "ansibleWorkingImage must be from ghcr.io, docker.io, or quay.io"

assert _gitRepoUrl.startswith("https://github.com/"), \
       "gitRepoUrl must be a valid GitHub HTTPS URL"

_override_params = {
    ansibleWorkingImage = _ansibleWorkingImage
    gitRepoUrl = _gitRepoUrl
    gitRevision = _gitRevision
    inventory = _inventory
    ansibleExtraRoles = _ansibleExtraRoles
}

# Still validate against schema for completeness
_validated: schema.PipelineOverrides = _override_params
