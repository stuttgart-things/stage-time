# main.k
import tekton_pipelines.v1 as tekton
import .vars
import datetime
import crypto

# --- Read parameters (supports both Composition format and flat format) ---
_params = option("params") or {}
_spec = _params?.oxr?.spec or {}

# If no nested structure, use flat parameters directly
_flat_params = _spec if _spec else _params

# --- Crossplane EnvironmentConfig context ---
# `function-environment-configs` merges the `data` of the selected
# EnvironmentConfig(s) into the pipeline context under this well-known
# key. The values act as shared, per-environment defaults: precedence is
# explicit XR spec value -> EnvironmentConfig -> flat -D option ->
# hardcoded default. When no EnvironmentConfig is selected (or when
# running in flat/-D mode) `_env` is empty and behaviour is unchanged.
_env = _params?.ctx?["apiextensions.crossplane.io/environment"] or {}

# --- Extract fields from spec (with fallbacks to direct options for backward compatibility) ---
_storageSize = _flat_params?.storageSize or option("storageSize") or "20Mi"
_storageAccessModes = _flat_params?.storageAccessModes or option("storageAccessModes") or "ReadWriteOnce"
_storageClass = _flat_params?.storageClass or _env?.storageClass or option("storageClass") or "openebs-hostpath"
_namespace = _flat_params?.namespace or _env?.namespace or option("namespace") or "tekton-ci"
_pipelineRunName = _flat_params?.pipelineRunName or option("pipelineRunName") or None
_gitRepoUrl = _flat_params?.gitRepoUrl or _env?.gitRepoUrl or option("gitRepoUrl") or "https://github.com/stuttgart-things/stage-time.git"
_gitRevision = _flat_params?.gitRevision or _env?.gitRevision or option("gitRevision") or "main"
_gitPath = _flat_params?.gitPath or _env?.gitPath or option("gitPath") or "pipelines/execute-ansible-playbooks-from-collections.yaml"
_ansibleWorkingImage = _flat_params?.ansibleWorkingImage or _env?.ansibleWorkingImage or option("ansibleWorkingImage") or "ghcr.io/stuttgart-things/sthings-ansible:11.11.0"
_ansiblePlaybooks = _flat_params?.ansiblePlaybooks or option("ansiblePlaybooks") or ["sthings.baseos.setup"]
_ansibleExtraCollections = _flat_params?.ansibleExtraCollections or _env?.ansibleExtraCollections or option("ansibleExtraCollections") or []
_ansibleExtraRoles = _flat_params?.ansibleExtraRoles or option("ansibleExtraRoles") or []
_ansibleVarsInventory = _flat_params?.ansibleVarsInventory or option("ansibleVarsInventory") or []
_ansibleVarsFile = _flat_params?.ansibleVarsFile or option("ansibleVarsFile") or []
_ansibleCredentialsSecretName = _flat_params?.ansibleCredentialsSecretName or _env?.ansibleCredentialsSecretName or option("ansibleCredentialsSecretName") or "ansible-credentials"

# Previously these only resolved from `-D` options via values.k, so setting
# them in an XR spec (composition mode) was silently ignored. Extract them
# here so `oxr.spec.<field>` is honoured, same precedence as the fields above.
_ansibleCredentialsUserKey = _flat_params?.ansibleCredentialsUserKey or option("ansibleCredentialsUserKey") or "ANSIBLE_USER"
_ansibleCredentialsPasswordKey = _flat_params?.ansibleCredentialsPasswordKey or option("ansibleCredentialsPasswordKey") or "ANSIBLE_PASSWORD"
_createInventory = _flat_params?.createInventory or option("createInventory") or "true"
_ansibleTargetHost = _flat_params?.ansibleTargetHost or option("ansibleTargetHost") or "all"
_gitWorkspaceSubdirectory = _flat_params?.gitWorkspaceSubdirectory or option("gitWorkspaceSubdirectory") or "/ansible/workdir/"
_installExtraRoles = _flat_params?.installExtraRoles or option("installExtraRoles") or "true"
_installExtraCollections = _flat_params?.installExtraCollections or option("installExtraCollections") or "true"
_userHome = _flat_params?.userHome or option("userHome") or "/home/nonroot"
_vaultSecretName = _flat_params?.vaultSecretName or option("vaultSecretName") or "vault"
_inventory = _flat_params?.inventory or option("inventory") or ""
_varsFile = _flat_params?.varsFile or option("varsFile") or ""
_ansibleVerbosity = _flat_params?.ansibleVerbosity or option("ansibleVerbosity") or "2"
_validateInventory = _flat_params?.validateInventory or option("validateInventory") or "true"

# Input validation (consolidated from the former values.k). Asserts on the
# resolved values, so it now also covers composition-mode oxr.spec inputs,
# not just flat -D options.
assert _ansibleWorkingImage.startswith("ghcr.io/") or _ansibleWorkingImage.startswith("docker.io/") or _ansibleWorkingImage.startswith("quay.io/"), "ansibleWorkingImage must be from ghcr.io, docker.io, or quay.io"
assert _gitRepoUrl.startswith("https://github.com/"), "gitRepoUrl must be a valid GitHub HTTPS URL"
assert len(_gitRevision) > 0, "gitRevision cannot be empty"
# Storage validation (moved from the former vars.k schema.StorageConfig).
assert _storageSize.endswith("Mi") or _storageSize.endswith("Gi"), "storageSize must end with 'Mi' or 'Gi'"
assert _storageAccessModes in ["ReadWriteOnce", "ReadWriteMany", "ReadOnlyMany"], "storageAccessModes must be ReadWriteOnce, ReadWriteMany, or ReadOnlyMany"

# --- Crossplane wrapper settings ---
_wrapInCrossplane = _flat_params?.wrapInCrossplane or option("wrapInCrossplane") or False
_crossplaneObjectName = _flat_params?.crossplaneObjectName or option("crossplaneObjectName") or "tekton-pipeline-run"
_crossplaneNamespace = _flat_params?.crossplaneNamespace or option("crossplaneNamespace") or "default"
_crossplaneProviderConfig = _flat_params?.crossplaneProviderConfig or option("crossplaneProviderConfig") or "kubernetes-provider"
_crossplaneTimeout = _flat_params?.crossplaneTimeout or option("crossplaneTimeout") or "60"

# Opt-in: when true the wrapped Object only reports Ready once the
# PipelineRun's "Succeeded" condition is True (via provider-kubernetes
# DeriveFromCelQuery). Off by default so other consumers of this module
# keep the "ready on create" behaviour.
_deriveReadiness = _flat_params?.deriveReadiness or option("deriveReadiness") or False

# --- Generate timestamp and suffix ---
_timestamp = str(datetime.now())
_suffix = crypto.md5(_timestamp)[:8:]

# --- Override configurations with extracted params ---
_git_config_override = {
    url = _gitRepoUrl
    revision = _gitRevision
    pathInRepo = _gitPath
}

_workspace_config_override = {
    name = "shared-workspace"
    volumeClaimTemplate = {
        spec = {
            accessModes = [_storageAccessModes]
            resources = {
                requests = {
                    storage = _storageSize
                }
            }
            storageClassName = _storageClass
        }
    }
}

_pipeline_params_override = {
    storageSize = _storageSize
    storageAccessModes = _storageAccessModes
    ansiblePlaybooks = _ansiblePlaybooks
    ansibleExtraCollections = _ansibleExtraCollections
    ansibleExtraRoles = _ansibleExtraRoles
    ansibleVarsInventory = _ansibleVarsInventory
    ansibleVarsFile = _ansibleVarsFile
    ansibleWorkingImage = _ansibleWorkingImage
    ansibleCredentialsSecretName = _ansibleCredentialsSecretName
    ansibleCredentialsUserKey = _ansibleCredentialsUserKey
    ansibleCredentialsPasswordKey = _ansibleCredentialsPasswordKey
    createInventory = _createInventory
    ansibleTargetHost = _ansibleTargetHost
    gitWorkspaceSubdirectory = _gitWorkspaceSubdirectory
    installExtraRoles = _installExtraRoles
    installExtraCollections = _installExtraCollections
    userHome = _userHome
    vaultSecretName = _vaultSecretName
    inventory = _inventory
    varsFile = _varsFile
    ansibleVerbosity = _ansibleVerbosity
    validateInventory = _validateInventory
    gitRepoUrl = _gitRepoUrl
    gitRevision = _gitRevision
}

# --- Generate the PipelineRun ---
_pipelineRun = tekton.PipelineRun {
    metadata = {
        name = _pipelineRunName or "${vars._pipeline_name_prefix}-${_suffix}"
        namespace = _namespace
    }
    spec = {
        pipelineRef = {
            resolver = "git"
            params = [{name = k, value = v} for k, v in _git_config_override]
        }
        params = [{name = k, value = v} for k, v in _pipeline_params_override]
        taskRunTemplate = vars._task_run_template
        timeouts = vars._timeouts
        workspaces = [_workspace_config_override]
    }
}

# --- Crossplane Object wrapper ---
_crossplaneObject = {
    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
    kind = "Object"
    metadata = {
        name = _crossplaneObjectName
        namespace = _crossplaneNamespace
        annotations = {
            "uptest.upbound.io/timeout" = _crossplaneTimeout
        }
    }
    spec = {
        forProvider = {
            manifest = _pipelineRun
        }
        providerConfigRef = {
            kind = "ClusterProviderConfig"
            name = _crossplaneProviderConfig
        }
        if _deriveReadiness:
            readiness = {
                policy = "DeriveFromCelQuery"
                celQuery = "has(object.status) && has(object.status.conditions) && object.status.conditions.exists(c, c.type == \"Succeeded\" && c.status == \"True\")"
            }
    }
}

# --- Output based on mode ---
# If params is provided as nested Composition format, return items array
# Otherwise return single resource (direct/flat mode)
if _spec:
    items = [
        if _wrapInCrossplane:
            _crossplaneObject
        else:
            _pipelineRun
    ]
elif _wrapInCrossplane:
    _crossplaneObject
else:
    _pipelineRun
