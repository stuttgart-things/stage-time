# Static, non-field pipeline-run settings.
# Per-field default values live in main.k (single source of truth).
_task_run_template = {
    serviceAccountName = "default"
}

# Packer builds (golden images) take a while; give the pipeline a generous
# ceiling. Override via spec/-D if a builder is slower.
_timeouts = {
    pipeline = "2h0m0s"
}
