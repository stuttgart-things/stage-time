import .schema

# These are the actual values that will be validated
_override_values: schema.PipelineOverrides = {
    gitUrl = option("gitUrl") or "https://github.com/stuttgart-things/stage-time"
    branchName = option("branchName") or "main"
    verifySsl = option("verifySsl") or "false"
    imageName = option("imageName") or "ttl.sh/stage-time:v1"
    context = option("context") or "tests/test-app"
}

# These are the pipeline parameters with Tekton's expected names
_params = {
    "git-url" = _override_values.gitUrl
    "branch-name" = _override_values.branchName
    "verify-ssl" = _override_values.verifySsl
    "image-name" = _override_values.imageName
    "context" = _override_values.context
}

# Add your other defaults here
_task_run_template = {
    # your task run template config
}

_timeouts = {
    # your timeout config
}
