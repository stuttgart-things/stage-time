# values.k
import .schema

# Environment-specific overrides with defaults
_ansibleWorkingImage = option("ansibleWorkingImage") or "ghcr.io/stuttgart-things/sthings-ansible:11.11.0"
_gitRepoUrl = option("gitRepoUrl") or "https://github.com/stuttgart-things/stage-time.git"
_gitRevision = option("gitRevision") or "main"
_inventory = option("inventory") or ""
_ansibleExtraRoles = option("ansibleExtraRoles") or []

_ansibleExtraCollections = option("ansibleExtraCollections") or []

_ansiblePlaybooks = option("ansiblePlaybooks") or [
    "sthings.baseos.setup"
]

# New parameters with defaults
_ansibleVarsInventory = option("ansibleVarsInventory") or []
_ansibleVarsFile = option("ansibleVarsFile") or []
_userHome = option("userHome") or "/home/nonroot"
_vaultSecretName = option("vaultSecretName") or "vault"
_ansibleCredentialsSecretName = option("ansibleCredentialsSecretName") or "ansible-credentials"
_ansibleCredentialsUserKey = option("ansibleCredentialsUserKey") or "ANSIBLE_USER"
_ansibleCredentialsPasswordKey = option("ansibleCredentialsPasswordKey") or "ANSIBLE_PASSWORD"
_varsFile = option("varsFile") or ""
_createInventory = option("createInventory") or "true"

# Inline validation for immediate feedback
assert _ansibleWorkingImage.startswith("ghcr.io/") or _ansibleWorkingImage.startswith("docker.io/") or _ansibleWorkingImage.startswith("quay.io/"), "ansibleWorkingImage must be from ghcr.io, docker.io, or quay.io"

assert _gitRepoUrl.startswith("https://github.com/"), "gitRepoUrl must be a valid GitHub HTTPS URL"

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
