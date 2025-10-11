import tekton_pipelines.v1 as tekton
import .vars
import datetime
import crypto

_timestamp = str(datetime.now())
_suffix = crypto.md5(_timestamp)[:8]

tekton.PipelineRun {
    metadata = {
        name = "${vars._pipeline_name_prefix}-${_suffix}"
        }
    spec = {
        pipelineRef = {
            resolver = "git"
            params = [
                {name = k, value = v} for k, v in vars._git_config
            ]
        }
        params = [
            {name = k, value = v} for k, v in vars._pipeline_params
        ]
        taskRunTemplate = vars._task_run_template
        timeouts = vars._timeouts
        workspaces = [vars._workspace_config]

    }
}
