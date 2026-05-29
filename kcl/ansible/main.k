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

# --- Crossplane wrapper settings ---
_wrapInCrossplane = _flat_params?.wrapInCrossplane or option("wrapInCrossplane") or False
_crossplaneObjectName = _flat_params?.crossplaneObjectName or option("crossplaneObjectName") or "tekton-pipeline-run"
_crossplaneNamespace = _flat_params?.crossplaneNamespace or option("crossplaneNamespace") or "default"
_crossplaneProviderConfig = _flat_params?.crossplaneProviderConfig or option("crossplaneProviderConfig") or "kubernetes-provider"
_crossplaneTimeout = _flat_params?.crossplaneTimeout or option("crossplaneTimeout") or "60"

# --- Generate timestamp and suffix ---
_timestamp = str(datetime.now())
_suffix = crypto.md5(_timestamp)[:8]

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
            params = [
                {name = k, value = v} for k, v in _git_config_override
            ]
        }
        params = [
            {name = k, value = v} for k, v in (vars._pipeline_params | _pipeline_params_override)
        ]
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
else:
    if _wrapInCrossplane:
        _crossplaneObject
    else:
        _pipelineRun
