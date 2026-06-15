# vars.k
import .defaults

# Re-export from defaults so main.k can access them
_task_run_template = defaults._task_run_template
_timeouts = defaults._timeouts

_pipeline_name_prefix = option("pipelinePrefix") or "run-ansible-from-collections"
