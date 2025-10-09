import .schema

# Environment-specific overrides with defaults
_ansibleWorkingImage = option("ansibleWorkingImage") or "ghcr.io/stuttgart-things/sthings-ansible:11.0.0"
_gitRepoUrl = option("gitRepoUrl") or "https://github.com/stuttgart-things/stage-time.git"
_gitRevision = option("gitRevision") or "main"
_inventory = option("inventory") or "MTAuMzEuMTAzLjI3Cg=="
_ansibleExtraRoles = option("ansibleExtraRoles") or [
    "https://github.com/stuttgart-things/install-requirements.git,2024.05.11"
]

_ansibleExtraCollections = option("ansibleExtraCollections") or [
    "community.crypto:2.22.3"
    "community.general:10.1.0"
    "ansible.posix:2.0.0"
    "kubernetes.core:5.0.0"
]

_ansiblePlaybooks = option("ansiblePlaybooks") or [
    "sthings.baseos.prepare_env"
    "sthings.baseos.setup"
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
    ansiblePlaybooks = _ansiblePlaybooks
    ansibleExtraCollections = _ansibleExtraCollections
}

# Still validate against schema for completeness
_validated: schema.PipelineOverrides = _override_params
