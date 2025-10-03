schema Param:
    name: str
    value: str

schema Metadata:
    generateName: str

schema Spec:
    params: [Param]

schema PipelineRun:
    apiVersion: str = "tekton.dev/v1"
    kind: str = "PipelineRun"
    metadata: Metadata
    spec: Spec
