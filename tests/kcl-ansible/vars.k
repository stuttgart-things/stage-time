import .defaults
import .values

# Merge defaults with overrides (overrides take precedence)
_pipeline_params = defaults._default_params | values._override_params

# Re-export from defaults so main.k can access them
_task_run_template = defaults._task_run_template
_timeouts = defaults._timeouts

# Pipeline reference config
_git_config = {
    url = "https://github.com/stuttgart-things/stage-time.git"
    revision = "main"
    pathInRepo = "pipelines/execute-ansible-playbooks.yaml"
}

_pipeline_name_prefix = "pr-ansible"
_storageClass = "openebs-hostpath"
_storageSize = "20Mi"
_storageAccessModes = "ReadWriteOnce"

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
