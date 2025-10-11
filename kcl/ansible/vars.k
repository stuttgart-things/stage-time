import .defaults
import .values
import .schema

# Merge defaults with overrides (overrides take precedence)
_pipeline_params = defaults._default_params | values._override_params

# Re-export from defaults so main.k can access them
_task_run_template = defaults._task_run_template
_timeouts = defaults._timeouts

# Pipeline reference config with validation
_git_config: schema.GitConfig = {
    url = option("gitUrl") or "https://github.com/stuttgart-things/stage-time.git"
    revision = option("gitRevision") or "main"
    pathInRepo = option("gitPath") or "pipelines/execute-ansible-playbooks.yaml"
}

_pipeline_name_prefix = option("pipelinePrefix") or "pr-ansible"

# Storage settings with validation
_storage_config: schema.StorageConfig = {
    storageClass = option("storageClass") or "openebs-hostpath"
    storageSize = option("storageSize") or "20Mi"
    storageAccessModes = option("storageAccessModes") or "ReadWriteOnce"
}

_storageClass = _storage_config.storageClass
_storageSize = _storage_config.storageSize
_storageAccessModes = _storage_config.storageAccessModes

_workspace_config = {
    name = "shared-workspace"
    volumeClaimTemplate = {
        metadata = {
            creationTimestamp = None
        }
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
