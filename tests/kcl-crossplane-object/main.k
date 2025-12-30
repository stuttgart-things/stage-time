# main.k
import tekton_pipelines.v1 as tekton
import datetime
import crypto

# Configuration
storageSize = option("storageSize") or "5000Mi"
storageAccessModes = option("storageAccessModes") or "ReadWriteMany"
ansiblePlaybooks = option("ansiblePlaybooks") or ["sthings.baseos.setup"]
ansibleExtraCollections = option("ansibleExtraCollections") or []
namespace = option("namespace") or "tekton-ci"

# Generate unique name
_timestamp = str(datetime.now())
_suffix = crypto.md5(_timestamp)[:8]
pipelineRunName = "run-ansible-from-collections-${_suffix}"

# Create PipelineRun
pipelineRun = tekton.PipelineRun {
    metadata = {
        name = pipelineRunName
        namespace = namespace
    }
    spec = {
        pipelineRef = {
            resolver = "git"
            params = [
                {name = "url", value = "https://github.com/stuttgart-things/stage-time.git"}
                {name = "revision", value = "main"}
                {name = "pathInRepo", value = "pipelines/execute-ansible-playbooks-from-collections.yaml"}
            ]
        }
        params = [
            {name = "storageSize", value = storageSize}
            {name = "storageAccessModes", value = storageAccessModes}
            {name = "ansiblePlaybooks", value = ansiblePlaybooks}
            {name = "ansibleExtraCollections", value = ansibleExtraCollections}
            # Add other default params as needed
        ]
        taskRunTemplate = {
            serviceAccountName = "default"
        }
        timeouts = {
            pipeline = "1h0m0s"
        }
        workspaces = [{
            name = "shared-workspace"
            volumeClaimTemplate = {
                spec = {
                    accessModes = [storageAccessModes]
                    resources = {
                        requests = {
                            storage = storageSize
                        }
                    }
                    storageClassName = "openebs-hostpath"
                }
            }
        }]
    }
}

# Wrap in Crossplane Object
result = {
    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
    kind = "Object"
    metadata = {
        name = "ansible-pipeline-run"
        namespace = "default"
        annotations = {
            "uptest.upbound.io/timeout" = "60"
        }
    }
    spec = {
        forProvider = {
            manifest = pipelineRun
        }
        providerConfigRef = {
            kind = "ClusterProviderConfig"
            name = "kubernetes-provider"
        }
    }
}