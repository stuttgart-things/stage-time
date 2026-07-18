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
# EnvironmentConfig(s) into the pipeline context under this well-known key.
# Precedence: explicit XR spec value -> EnvironmentConfig -> flat -D option ->
# hardcoded default. When no EnvironmentConfig is selected (or in flat/-D
# mode) `_env` is empty and behaviour is unchanged.
_env = _params?.ctx?["apiextensions.crossplane.io/environment"] or {}

# --- Storage (PipelineRun workspace PVC) ---
_storageSize = _flat_params?.storageSize or option("storageSize") or "5Gi"
_storageAccessModes = _flat_params?.storageAccessModes or option("storageAccessModes") or "ReadWriteOnce"
_storageClass = _flat_params?.storageClass or _env?.storageClass or option("storageClass") or "openebs-hostpath"

# --- PipelineRun placement ---
_namespace = _flat_params?.namespace or _env?.namespace or option("namespace") or "tekton-ci"
_pipelineRunName = _flat_params?.pipelineRunName or option("pipelineRunName") or None

# --- Pipeline DEFINITION location (where build-packer-template.yaml lives).
# This is the stage-time repo and is DISTINCT from the template source repo
# below — packer templates live elsewhere (stuttgart-things/stuttgart-things).
_pipelineRepoUrl = _flat_params?.pipelineRepoUrl or _env?.pipelineRepoUrl or option("pipelineRepoUrl") or "https://github.com/stuttgart-things/stage-time.git"
_pipelineRevision = _flat_params?.pipelineRevision or _env?.pipelineRevision or option("pipelineRevision") or "main"
_pipelinePath = _flat_params?.pipelinePath or _env?.pipelinePath or option("pipelinePath") or "pipelines/build-packer-template.yaml"

# --- Template SOURCE repo (the .pkr.hcl templates the pipeline checks out) ---
_gitRepoUrl = _flat_params?.gitRepoUrl or _env?.gitRepoUrl or option("gitRepoUrl") or "https://github.com/stuttgart-things/stuttgart-things.git"
_gitRevision = _flat_params?.gitRevision or option("gitRevision") or "main"

# Name of a secret holding .gitconfig / .git-credentials (see
# templates/git-basicauth-secret.yaml). Required to clone the default
# gitRepoUrl, which is a private repo — an https:// remote cannot be
# authenticated by the sshCredentials workspace. Empty = workspace unbound.
_gitBasicAuthSecretName = _flat_params?.gitBasicAuthSecretName or _env?.gitBasicAuthSecretName or option("gitBasicAuthSecretName") or ""

# Higher-level build selectors, mirroring the dispatch-packer-build action's
# BUILD_DIR = packer/builds/<os>-<lab>-vsphere-<provisioning>. When
# gitWorkspaceSubdirectory is not given explicitly but os/lab/provisioning are,
# the subdirectory is composed from them.
_osVersion = _flat_params?.osVersion or option("osVersion") or ""
_lab = _flat_params?.lab or _env?.lab or option("lab") or ""
_provisioning = _flat_params?.provisioning or option("provisioning") or ""
_computedSubdir = "packer/builds/${_osVersion}-${_lab}-vsphere-${_provisioning}" if (_osVersion and _lab and _provisioning) else ""
_gitWorkspaceSubdirectory = _flat_params?.gitWorkspaceSubdirectory or option("gitWorkspaceSubdirectory") or _computedSubdir or ""

# --- Packer run configuration ---
_packerAction = _flat_params?.packerAction or option("packerAction") or "build"
_packerTemplate = _flat_params?.packerTemplate or option("packerTemplate") or "."
_packerOnly = _flat_params?.packerOnly or option("packerOnly") or ""
_packerForce = _flat_params?.packerForce or option("packerForce") or "false"
_packerRunInit = _flat_params?.packerRunInit or option("packerRunInit") or "true"
_packerVars = _flat_params?.packerVars or option("packerVars") or []
_packerVarsFile = _flat_params?.packerVarsFile or option("packerVarsFile") or ""
_packerInitExtraArgs = _flat_params?.packerInitExtraArgs or option("packerInitExtraArgs") or ""
_packerBuildExtraArgs = _flat_params?.packerBuildExtraArgs or option("packerBuildExtraArgs") or ""
_packerLog = _flat_params?.packerLog or option("packerLog") or ""
_packerWorkingImage = _flat_params?.packerWorkingImage or _env?.packerWorkingImage or option("packerWorkingImage") or "ghcr.io/stuttgart-things/sthings-packer:1.15.1"
_credentialsSecretName = _flat_params?.credentialsSecretName or _env?.credentialsSecretName or option("credentialsSecretName") or "packer-credentials"
_vaultSecretName = _flat_params?.vaultSecretName or option("vaultSecretName") or "vault"
_userHome = _flat_params?.userHome or option("userHome") or "/home/nonroot"

# Input validation (asserts on resolved values, so it covers both composition
# oxr.spec inputs and flat -D options).
assert _packerWorkingImage.startswith("ghcr.io/") or _packerWorkingImage.startswith("docker.io/") or _packerWorkingImage.startswith("quay.io/"), "packerWorkingImage must be from ghcr.io, docker.io, or quay.io"
assert _gitRepoUrl.startswith("https://github.com/"), "gitRepoUrl must be a valid GitHub HTTPS URL"
assert _pipelineRepoUrl.startswith("https://github.com/"), "pipelineRepoUrl must be a valid GitHub HTTPS URL"
assert len(_gitRevision) > 0, "gitRevision cannot be empty"
assert _packerAction in ["init", "validate", "build"], "packerAction must be init, validate or build"
assert _storageSize.endswith("Mi") or _storageSize.endswith("Gi"), "storageSize must end with 'Mi' or 'Gi'"
assert _storageAccessModes in ["ReadWriteOnce", "ReadWriteMany", "ReadOnlyMany"], "storageAccessModes must be ReadWriteOnce, ReadWriteMany, or ReadOnlyMany"

# --- Crossplane wrapper settings ---
_wrapInCrossplane = _flat_params?.wrapInCrossplane or option("wrapInCrossplane") or False
_crossplaneObjectName = _flat_params?.crossplaneObjectName or option("crossplaneObjectName") or "packer-build-run"
_crossplaneNamespace = _flat_params?.crossplaneNamespace or option("crossplaneNamespace") or "default"
_crossplaneProviderConfig = _flat_params?.crossplaneProviderConfig or option("crossplaneProviderConfig") or "kubernetes-provider"
_crossplaneTimeout = _flat_params?.crossplaneTimeout or option("crossplaneTimeout") or "120"

# Opt-in: when true the wrapped Object only reports Ready once the
# PipelineRun's "Succeeded" condition is True (via provider-kubernetes
# DeriveFromCelQuery). Off by default so other consumers keep "ready on create".
_deriveReadiness = _flat_params?.deriveReadiness or option("deriveReadiness") or False

# --- Generate timestamp and suffix (for the default PipelineRun name) ---
_timestamp = str(datetime.now())
_suffix = crypto.md5(_timestamp)[:8:]

# --- pipelineRef git resolver (pipeline DEFINITION location) ---
_pipeline_ref_override = {
    url = _pipelineRepoUrl
    revision = _pipelineRevision
    pathInRepo = _pipelinePath
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

# Optional basic-auth workspace for cloning a private template repo over
# HTTPS. Only emitted when a secret name is given, so the pipeline's
# `basicAuth` workspace stays unbound (and optional) by default.
_basicAuthWorkspaces = [
    {
        name = "basicAuth"
        secret = {secretName = _gitBasicAuthSecretName}
    }
] if _gitBasicAuthSecretName else []

# Pipeline params — keys must match build-packer-template.yaml's param names.
_pipeline_params_override = {
    packerAction = _packerAction
    packerTemplate = _packerTemplate
    packerOnly = _packerOnly
    packerForce = _packerForce
    packerRunInit = _packerRunInit
    packerVars = _packerVars
    packerVarsFile = _packerVarsFile
    packerInitExtraArgs = _packerInitExtraArgs
    packerBuildExtraArgs = _packerBuildExtraArgs
    packerLog = _packerLog
    packerWorkingImage = _packerWorkingImage
    credentialsSecretName = _credentialsSecretName
    vaultSecretName = _vaultSecretName
    userHome = _userHome
    gitRepoUrl = _gitRepoUrl
    gitRevision = _gitRevision
    gitWorkspaceSubdirectory = _gitWorkspaceSubdirectory
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
            params = [{name = k, value = v} for k, v in _pipeline_ref_override]
        }
        params = [{name = k, value = v} for k, v in _pipeline_params_override]
        taskRunTemplate = vars._task_run_template
        timeouts = vars._timeouts
        workspaces = [_workspace_config_override] + _basicAuthWorkspaces
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
# Nested Composition format -> items array. Otherwise single resource.
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
