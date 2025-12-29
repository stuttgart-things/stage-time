import .schema

# Environment-specific overrides with defaults
_ansibleWorkingImage = option("ansibleWorkingImage") or "ghcr.io/stuttgart-things/sthings-ansible:11.11.0"
_gitRepoUrl = option("gitRepoUrl") or "https://github.com/stuttgart-things/stage-time.git"
_gitRevision = option("gitRevision") or "main"
_inventory = option("inventory") or ""
_ansibleExtraRoles = option("ansibleExtraRoles") or [
    "https://github.com/stuttgart-things/install-requirements.git,2024.05.11"
]

_ansibleExtraCollections = option("ansibleExtraCollections") or [
    "community.general:10.1.0",
    "https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz"
]

_ansiblePlaybooks = option("ansiblePlaybooks") or [
    "sthings.baseos.setup"
]

# New parameters with defaults
_ansibleVarsInventory = option("ansibleVarsInventory") or [
    'all+["10.31.102.107"]'
]
_ansibleVarsFile = option("ansibleVarsFile") or [
    "manage_filesystem+-true",
    "update_packages+-true",
    "ansible_become+-true",
    "ansible_become_method+-sudo"
]
_userHome = option("userHome") or "/home/nonroot"
_vaultSecretName = option("vaultSecretName") or "vault"
_ansibleCredentialsSecretName = option("ansibleCredentialsSecretName") or "ansible-credentials"
_ansibleCredentialsUserKey = option("ansibleCredentialsUserKey") or "ANSIBLE_USER"
_ansibleCredentialsPasswordKey = option("ansibleCredentialsPasswordKey") or "ANSIBLE_PASSWORD"
_varsFile = option("varsFile") or ""
_createInventory = option("createInventory") or "true"

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
    # Add new parameters
    ansibleVarsInventory = _ansibleVarsInventory
    ansibleVarsFile = _ansibleVarsFile
    userHome = _userHome
    vaultSecretName = _vaultSecretName
    ansibleCredentialsSecretName = _ansibleCredentialsSecretName
    ansibleCredentialsUserKey = _ansibleCredentialsUserKey
    ansibleCredentialsPasswordKey = _ansibleCredentialsPasswordKey
    varsFile = _varsFile
    createInventory = _createInventory
}

# Still validate against schema for completeness
#_validated = schema.PipelineOverrides _override_params
