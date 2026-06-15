"""
AnsibleRun Schema Definition
"""

schema Metadata:
    """
    Kubernetes metadata
    """
    name: str
    namespace?: str

schema AnsibleRunSpec:
    """
    Specification for AnsibleRun custom resource
    """
    # Crossplane Configuration
    wrapInCrossplane?: bool
    crossplaneObjectName?: str
    crossplaneNamespace?: str
    crossplaneProviderConfig?: str
    # PipelineRun Configuration
    pipelineRunName?: str
    namespace?: str
    # Ansible Configuration
    ansibleCredentialsSecretName?: str
    ansiblePlaybooks?: [str]
    ansibleVarsFile?: [str]
    ansibleVarsInventory?: [str]
    ansibleExtraCollections?: [str]

schema AnsibleRun:
    """
    AnsibleRun custom resource definition
    """
    apiVersion: str = "resources.stuttgart-things.com/v1alpha1"
    kind: str = "AnsibleRun"
    metadata: Metadata
    spec: AnsibleRunSpec

