"""
PackerBuild Main Configuration
Supports both Composition format and flat format with -D overrides
"""

# kcl/packer-run — CLIENT-SIDE GENERATOR for the PackerBuild XR
# (resources.stuttgart-things.com/v1alpha1).
#
# This renders the *request* object you `kubectl apply`. It is NOT the
# Composition renderer — that is kcl/packer (kcl-tekton-pr-packer), which turns
# a PackerBuild spec into a Tekton PipelineRun.
#
# The canonical schema is the XRD in stuttgart-things/crossplane-configurations
# (cicd/packer-build/apis/definition.yaml). The fields below are a SUBSET; for
# the full spec and authoritative examples see that XRD and
# cicd/packer-build/examples/xr*.yaml.
import .schema

# --- Read parameters (supports both Composition format and flat format) ---
_params = option("params") or {}
_spec = _params?.oxr?.spec or {}

# If no nested structure, use flat parameters directly
_flat_params = _spec if _spec else _params

# --- Extract fields from spec (with fallbacks to direct options) ---

# Metadata
_name = _flat_params?.name or option("name") or "packer-build"
_metadataNamespace = _flat_params?.metadataNamespace or option("metadataNamespace") or "default"

# Crossplane Configuration
_wrapInCrossplane = _flat_params?.wrapInCrossplane or option("wrapInCrossplane") or True
_crossplaneObjectName = _flat_params?.crossplaneObjectName or option("crossplaneObjectName") or _name
_crossplaneNamespace = _flat_params?.crossplaneNamespace or option("crossplaneNamespace") or "default"
_crossplaneProviderConfig = _flat_params?.crossplaneProviderConfig or option("crossplaneProviderConfig") or "default"

# PipelineRun Configuration
_pipelineRunName = _flat_params?.pipelineRunName or option("pipelineRunName") or _name
_namespace = _flat_params?.namespace or option("namespace") or "tekton-ci"

# Template source / build selectors
_gitRepoUrl = _flat_params?.gitRepoUrl or option("gitRepoUrl") or "https://github.com/stuttgart-things/stuttgart-things.git"
_gitRevision = _flat_params?.gitRevision or option("gitRevision") or "main"
_gitWorkspaceSubdirectory = _flat_params?.gitWorkspaceSubdirectory or option("gitWorkspaceSubdirectory") or ""
_osVersion = _flat_params?.osVersion or option("osVersion") or ""
_lab = _flat_params?.lab or option("lab") or ""
_provisioning = _flat_params?.provisioning or option("provisioning") or ""

# Packer Configuration
_packerAction = _flat_params?.packerAction or option("packerAction") or "build"
_packerTemplate = _flat_params?.packerTemplate or option("packerTemplate") or "."
_packerOnly = _flat_params?.packerOnly or option("packerOnly") or ""
_packerForce = _flat_params?.packerForce or option("packerForce") or "false"
_packerVars = _flat_params?.packerVars or option("packerVars") or []
_packerVarsFile = _flat_params?.packerVarsFile or option("packerVarsFile") or ""
_credentialsSecretName = _flat_params?.credentialsSecretName or option("credentialsSecretName") or "packer-credentials"
_vaultSecretName = _flat_params?.vaultSecretName or option("vaultSecretName") or "vault"

# --- Generate PackerBuild Resource ---
_packerBuild = schema.PackerBuild {
    metadata = schema.Metadata {
        name = _name
        namespace = _metadataNamespace
    }
    spec = schema.PackerBuildSpec {
        wrapInCrossplane = _wrapInCrossplane
        crossplaneObjectName = _crossplaneObjectName
        crossplaneNamespace = _crossplaneNamespace
        crossplaneProviderConfig = _crossplaneProviderConfig
        pipelineRunName = _pipelineRunName
        namespace = _namespace
        gitRepoUrl = _gitRepoUrl
        gitRevision = _gitRevision
        gitWorkspaceSubdirectory = _gitWorkspaceSubdirectory
        osVersion = _osVersion
        lab = _lab
        provisioning = _provisioning
        packerAction = _packerAction
        packerTemplate = _packerTemplate
        packerOnly = _packerOnly
        packerForce = _packerForce
        packerVars = _packerVars
        packerVarsFile = _packerVarsFile
        credentialsSecretName = _credentialsSecretName
        vaultSecretName = _vaultSecretName
    }
}

_packerBuild
