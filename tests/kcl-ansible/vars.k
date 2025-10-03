import .defaults
import .values

# Merge defaults with overrides (overrides take precedence)
pipeline_params = defaults.default_params | values.override_params

# Pipeline reference config
git_config = {
    url = "https://github.com/stuttgart-things/stage-time.git"
    revision = "main"
    pathInRepo = "pipelines/execute-ansible-playbooks.yaml"
}

pipeline_name_prefix = "pr-ansible"
