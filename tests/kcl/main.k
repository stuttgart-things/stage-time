import pipeline

# grab all vars injected from values.yaml
vals = {k: v for k, v in __main__.items() if not k.startswith("__")}

pr = pipeline.PipelineRun {
    metadata = pipeline.Metadata {
        generateName = "pr-echo-"
    }

    spec = pipeline.Spec {
        params = [pipeline.Param { name = k, value = v } for k, v in vals.items]
    }
}
