# main.k

import tekton_pipelines.v1 as tekton
import .vars
import datetime
import crypto

# --- Read parameters (Composition format) ---
_params = option("params") or {}
_spec = _params?.oxr?.spec or {}

# --- Extract fields from spec (with fallbacks to direct options for backward compatibility) ---
_storageSize = _spec?.storageSize or option("storageSize") or "5000Mi"
_storageAccessModes = _spec?.storageAccessModes or option("storageAccessModes") or "ReadWriteMany"
_storageClass = _spec?.storageClass or option("storageClass") or "openebs-hostpath"
_namespace = _spec?.namespace or option("namespace") or "tekton-ci"
_pipelineRunName = _spec?.pipelineRunName or option("pipelineRunName") or None
_gitRepoUrl = _spec?.gitRepoUrl or option("gitRepoUrl") or "https://github.com/stuttgart-things/stage-time.git"
_gitRevision = _spec?.gitRevision or option("gitRevision") or "main"
_gitPath = _spec?.gitPath or option("gitPath") or "pipelines/execute-ansible-playbooks-from-collections.yaml"
_ansibleWorkingImage = _spec?.ansibleWorkingImage or option("ansibleWorkingImage") or "ghcr.io/stuttgart-things/sthings-ansible:11.11.0"
_ansiblePlaybooks = _spec?.ansiblePlaybooks or option("ansiblePlaybooks") or ["sthings.baseos.setup"]
_ansibleExtraCollections = _spec?.ansibleExtraCollections or option("ansibleExtraCollections") or []
_ansibleExtraRoles = _spec?.ansibleExtraRoles or option("ansibleExtraRoles") or []
_ansibleVarsInventory = _spec?.ansibleVarsInventory or option("ansibleVarsInventory") or []
_ansibleVarsFile = _spec?.ansibleVarsFile or option("ansibleVarsFile") or []

# --- Crossplane wrapper settings ---
_wrapInCrossplane = _spec?.wrapInCrossplane or option("wrapInCrossplane") or False
_crossplaneObjectName = _spec?.crossplaneObjectName or option("crossplaneObjectName") or "tekton-pipeline-run"
_crossplaneNamespace = _spec?.crossplaneNamespace or option("crossplaneNamespace") or "default"
_crossplaneProviderConfig = _spec?.crossplaneProviderConfig or option("crossplaneProviderConfig") or "kubernetes-provider"
_crossplaneTimeout = _spec?.crossplaneTimeout or option("crossplaneTimeout") or "60"

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
# If params is provided (Composition mode), return items array
# Otherwise return single resource (direct mode)
if _params != {}:
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
