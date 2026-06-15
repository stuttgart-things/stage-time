"""
AnsibleRun Main Configuration
Supports both Composition format and flat format with -D overrides
"""

# kcl/ansible-run — CLIENT-SIDE GENERATOR for the AnsibleRun XR
# (resources.stuttgart-things.com/v1alpha1).
#
# This renders the *request* object you `kubectl apply`. It is NOT the
# Composition renderer — that is kcl/ansible (kcl-tekton-pr), which turns an
# AnsibleRun spec into a Tekton PipelineRun.
#
# The canonical schema is the XRD in stuttgart-things/crossplane-configurations
# (cicd/ansible-run/apis/definition.yaml). The fields below are a SUBSET; for
# the full spec and authoritative examples see that XRD and
# cicd/ansible-run/examples/xr*.yaml.  See stage-time#45.
import .schema

# --- Read parameters (supports both Composition format and flat format) ---
_params = option("params") or {}
_spec = _params?.oxr?.spec or {}

# If no nested structure, use flat parameters directly
_flat_params = _spec if _spec else _params

# --- Extract fields from spec (with fallbacks to direct options for backward compatibility) ---

# Metadata
_name = _flat_params?.name or option("name") or "ansible-run"
_metadataNamespace = _flat_params?.metadataNamespace or option("metadataNamespace") or "default"

# Crossplane Configuration
_wrapInCrossplane = _flat_params?.wrapInCrossplane or option("wrapInCrossplane") or True
# Default crossplaneObjectName to name if not explicitly provided
_crossplaneObjectName = _flat_params?.crossplaneObjectName or option("crossplaneObjectName") or _name
_crossplaneNamespace = _flat_params?.crossplaneNamespace or option("crossplaneNamespace") or "default"
_crossplaneProviderConfig = _flat_params?.crossplaneProviderConfig or option("crossplaneProviderConfig") or "default"

# PipelineRun Configuration
# Default pipelineRunName to name if not explicitly provided
_pipelineRunName = _flat_params?.pipelineRunName or option("pipelineRunName") or _name
_namespace = _flat_params?.namespace or option("namespace") or "tekton-ci"

# Ansible Configuration
_ansibleCredentialsSecretName = _flat_params?.ansibleCredentialsSecretName or option("ansibleCredentialsSecretName") or "ansible-credentials"
_ansiblePlaybooks = _flat_params?.ansiblePlaybooks or option("ansiblePlaybooks") or []
_ansibleVarsFile = _flat_params?.ansibleVarsFile or option("ansibleVarsFile") or []
_ansibleVarsInventory = _flat_params?.ansibleVarsInventory or option("ansibleVarsInventory") or []
_ansibleExtraCollections = _flat_params?.ansibleExtraCollections or option("ansibleExtraCollections") or []

# --- Generate AnsibleRun Resource ---
_ansibleRun = schema.AnsibleRun {
    metadata = schema.Metadata {
        name = _name
        namespace = _metadataNamespace
    }
    spec = schema.AnsibleRunSpec {
        wrapInCrossplane = _wrapInCrossplane
        crossplaneObjectName = _crossplaneObjectName
        crossplaneNamespace = _crossplaneNamespace
        crossplaneProviderConfig = _crossplaneProviderConfig
        pipelineRunName = _pipelineRunName
        namespace = _namespace
        ansibleCredentialsSecretName = _ansibleCredentialsSecretName
        ansiblePlaybooks = _ansiblePlaybooks
        ansibleVarsFile = _ansibleVarsFile
        ansibleVarsInventory = _ansibleVarsInventory
        ansibleExtraCollections = _ansibleExtraCollections
    }
}

_ansibleRun
