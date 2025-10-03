import .defaults
import .values

# Merge defaults with overrides (overrides take precedence)
pipeline_params = defaults.default_params | values.override_params

# Re-export from defaults so main.k can access them
task_run_template = defaults.task_run_template
timeouts = defaults.timeouts

# Pipeline reference config
git_config = {
    url = "https://github.com/stuttgart-things/stage-time.git"
    revision = "main"
    pathInRepo = "pipelines/execute-ansible-playbooks.yaml"
}

pipeline_name_prefix = "pr-ansible"

storageClass = "openebs-hostpath"
storageSize = "20Mi"
storageAccessModes = "ReadWriteOnce"

workspace_config = {
    name = "shared-workspace"
    volumeClaimTemplate = {
        metadata = {
            creationTimestamp = None
        }
        spec = {
            accessModes = [storageAccessModes]
            resources = {
                requests = {
                    storage = storageSize
                }
            }
            storageClassName = storageClass
        }
    }
}
