"""
PackerBuild Schema Definition
"""

schema Metadata:
    """
    Kubernetes metadata
    """
    name: str
    namespace?: str

schema PackerBuildSpec:
    """
    Specification for PackerBuild custom resource
    """
    # Crossplane Configuration
    wrapInCrossplane?: bool
    crossplaneObjectName?: str
    crossplaneNamespace?: str
    crossplaneProviderConfig?: str
    # PipelineRun Configuration
    pipelineRunName?: str
    namespace?: str
    # Template source (where the *.pkr.hcl live)
    gitRepoUrl?: str
    gitRevision?: str
    gitWorkspaceSubdirectory?: str
    # High-level build selectors (compose gitWorkspaceSubdirectory)
    osVersion?: str
    lab?: str
    provisioning?: str
    # Packer Configuration
    packerAction?: str
    packerTemplate?: str
    packerOnly?: str
    packerForce?: str
    packerVars?: [str]
    packerVarsFile?: str
    credentialsSecretName?: str
    vaultSecretName?: str

schema PackerBuild:
    """
    PackerBuild custom resource definition
    """
    apiVersion: str = "resources.stuttgart-things.com/v1alpha1"
    kind: str = "PackerBuild"
    metadata: Metadata
    spec: PackerBuildSpec
