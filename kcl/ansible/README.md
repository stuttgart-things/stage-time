# KCL-ANSIBLE-PR

## DEV

<details><summary>PUSH MODULE</summary>

```bash
kcl mod push oci://ghcr.io/stuttgart-things/kcl-tekton-pr
```

</details>

## USAGE

<details><summary>EXAMPLE RENDERING</summary>

```bash
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr --tag 0.6.0 \
  -D storageSize="5000Mi" \
  -D storageAccessModes="ReadWriteOnce" \
  -D ansiblePlaybooks='["sthings.baseos.prepare_env", "sthings.baseos.setup", "sthings.apps.deploy"]' \
  -D ansibleExtraCollections='["community.crypto:2.22.3", "community.general:10.1.0", "community.vmware:5.2.0"]' -D ansiblePlaybooks='["sthings.baseos.prepare_env", "sthings.baseos.setup"]'
```

</details>

<details><summary>RENDER + APPLY (w/ PLAYS FROM GIT)</summary>

```bash
# RENDER + APPLY
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr --tag 0.6.0 \
-D pipelineRunName="run-ansible-test-6" \
-D namespace="tekton-ci" \
-D storageSize="20Mi" \
-D storageAccessModes="ReadWriteOnce" \
-D ansibleWorkingImage="ghcr.io/stuttgart-things/sthings-ansible:11.11.0" \
-D createInventory="true" \
-D ansibleTargetHost="all" \
-D gitRepoUrl="https://github.com/stuttgart-things/stage-time.git" \
-D gitRevision="main" \
-D gitWorkspaceSubdirectory="/ansible/workdir/" \
-D ansibleCredentialsSecretName="ansible-credentials" \
-D ansibleCredentialsUserKey="ANSIBLE_USER" \
-D ansibleCredentialsPasswordKey="ANSIBLE_PASSWORD" \
-D installExtraRoles="true" \
-D ansibleExtraRoles='["https://github.com/stuttgart-things/install-requirements.git,2024.05.11"]' \
-D ansiblePlaybooks='["sthings.baseos.setup"]' \
-D ansibleVarsFile='["manage_filesystem+-true", "update_packages+-true", "ansible_become+-true", "ansible_become_method+-sudo"]' \
-D ansibleVarsInventory='["all+[\"10.31.102.107\"]"]' \
-D ansibleExtraCollections='["community.general:10.1.0", "https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz"]' \
-D installExtraCollections="true" \
-D ansibleVerbosity="2" \
-D validateInventory="true" \
-D gitPath="pipelines/execute-ansible-playbooks.yaml" | kubectl apply -f -
```

</details>

<details><summary>RENDER + APPLY (w/ PLAYS FROM COLLECTIONS ONLY / NO GIT-CLONE IN PIPELINE)</summary>

```bash
kcl run ./main.k \
  -D pipelineRunName="run-ansible-from-collections-1" \
  -D namespace="tekton-ci" \
  -D storageSize="20Mi" \
  -D storageAccessModes="ReadWriteOnce" \
  -D ansibleWorkingImage="ghcr.io/stuttgart-things/sthings-ansible:11.11.0" \
  -D ansiblePlaybooks='["sthings.baseos.setup"]' \
  -D ansibleTargetHost="all" \
  -D ansibleExtraCollections='["community.general:10.1.0", "https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz"]' \
  -D installExtraCollections="true" \
  -D createInventory="true" \
  -D ansibleVarsInventory='["all+[\"10.31.102.107\"]"]' \
  -D ansibleVarsFile='["manage_filesystem+-true", "update_packages+-true", "ansible_become+-true", "ansible_become_method+-sudo"]' \
  -D varsFile="" \
  -D inventory="" \
  -D userHome="/home/nonroot" \
  -D vaultSecretName="vault" \
  -D ansibleCredentialsSecretName="ansible-credentials" \
  -D ansibleCredentialsUserKey="ANSIBLE_USER" \
  -D ansibleCredentialsPasswordKey="ANSIBLE_PASSWORD" \
  -D gitPath="pipelines/execute-ansible-playbooks-from-collections.yaml"
```

```bash
# MINIMAL
kcl run ./main.k \
  -D pipelineRunName="run-ansible2" \
  -D namespace="tekton-ci" \
  -D ansiblePlaybooks='["sthings.baseos.setup"]' \
  -D createInventory="true" \
  -D ansibleVarsInventory='["all+[\"10.31.102.107\"]"]' \
  -D ansibleVarsFile='["manage_filesystem+-true", "update_packages+-true", "ansible_become+-true", "ansible_become_method+-sudo"]' \
  -D ansibleExtraCollections='["community.general:10.1.0", "https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz"]' \
  -D varsFile="" \
  -D inventory="" \
  -D ansibleCredentialsSecretName="ansible-credentials" | kubectl apply -f -
```

</details>

<details><summary>RENDER CROSSPLANE OBJECT</summary>

```bash
# RENDER (# or use main.k (or leave out reference) instead of the oci module)
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr --tag 0.6.0 -D params='{
  "oxr": {
    "spec": {
      "pipelineRunName": "run-ansible-test-6",
      "namespace": "tekton-ci",
      "storageSize": "20Mi",
      "storageAccessModes": "ReadWriteOnce",
      "ansibleWorkingImage": "ghcr.io/stuttgart-things/sthings-ansible:11.11.0",
      "createInventory": "true",
      "ansibleTargetHost": "all",
      "gitRepoUrl": "https://github.com/stuttgart-things/stage-time.git",
      "gitRevision": "main",
      "gitPath": "pipelines/execute-ansible-playbooks.yaml",
      "gitWorkspaceSubdirectory": "/ansible/workdir/",
      "ansibleCredentialsSecretName": "ansible-credentials",
      "ansibleCredentialsUserKey": "ANSIBLE_USER",
      "ansibleCredentialsPasswordKey": "ANSIBLE_PASSWORD",
      "installExtraRoles": "true",
      "ansibleExtraRoles": [
        "https://github.com/stuttgart-things/install-requirements.git,2024.05.11"
      ],
      "ansiblePlaybooks": [
        "sthings.baseos.setup"
      ],
      "ansibleVarsFile": [
        "manage_filesystem+-true",
        "update_packages+-true",
        "ansible_become+-true",
        "ansible_become_method+-sudo"
      ],
      "ansibleVarsInventory": [
        "all+[\"10.31.102.155\"]"
      ],
      "ansibleExtraCollections": [
        "community.general:10.1.0",
        "https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz"
      ],
      "installExtraCollections": "true",
      "ansibleVerbosity": "2",
      "validateInventory": "true",
      "wrapInCrossplane": true,
      "crossplaneObjectName": "ansible-pipeline-test-6",
      "crossplaneNamespace": "default",
      "crossplaneProviderConfig": "kubernetes-provider",
      "crossplaneTimeout": "60"
    }
  }
}'
```

```bash
# MINIMAL
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr --tag 0.6.0 -D params='{
  "oxr": {
    "spec": {
      "pipelineRunName": "run-ansible-test1",
      "namespace": "tekton-ci",
      "ansibleCredentialsSecretName": "ansible-credentials",
      "ansiblePlaybooks": [
        "sthings.baseos.setup"
      ],
      "ansibleVarsFile": [
        "manage_filesystem+-true",
        "update_packages+-true",
        "ansible_become+-true",
        "ansible_become_method+-sudo"
      ],
      "ansibleVarsInventory": [
        "all+[\"10.31.102.107\"]"
      ],
      "wrapInCrossplane": true,
      "crossplaneObjectName": "run-ansible-test",
      "crossplaneNamespace": "default",
      "crossplaneProviderConfig": "dev"
    }
  }
}' --format yaml | yq eval -P '.items[]' - | awk 'BEGIN{doc=""} /^apiVersion: /{if(doc!=""){print "---";} doc=1} {print}' | kubectl apply -f -
```

</details>

## CROSSPLANE ENVIRONMENTCONFIG (SHARED DEFAULTS)

When this module is rendered by `function-kcl` inside a Crossplane
Composition, it reads shared per-environment defaults from the pipeline
**context** key `apiextensions.crossplane.io/environment`. That key is
populated by [`function-environment-configs`](https://github.com/crossplane-contrib/function-environment-configs),
which must run as an earlier pipeline step and select one or more
`EnvironmentConfig` resources.

The following `data` keys are consumed (all optional):

| EnvironmentConfig `data` key | Purpose |
|------------------------------|---------|
| `gitRepoUrl`                 | Default Git repo for the pipeline definition |
| `gitRevision`                | Default Git branch/revision |
| `gitPath`                    | Default path to the pipeline file in the repo |
| `storageClass`               | Default workspace PVC StorageClass |
| `ansibleWorkingImage`        | Default Ansible working container image |
| `namespace`                  | Default Tekton namespace for the PipelineRun |
| `ansibleExtraCollections`    | Default Ansible collections (JSON list) |
| `ansibleCredentialsSecretName` | Default credentials Secret name |
| `extraEnvSecretName`         | Default Secret injected as env vars into the playbook step |

Precedence per field: explicit `oxr.spec` value → `EnvironmentConfig`
value → flat `-D` option → hardcoded default. When no EnvironmentConfig
is selected (or in flat `-D` mode) the context is empty and behaviour is
unchanged. See the `ansible-run` Configuration in
[`crossplane-configurations`](https://github.com/stuttgart-things/crossplane-configurations)
for the wired-up Composition and example `EnvironmentConfig`.

## READINESS (OPT-IN)

Set `deriveReadiness=true` (XR `spec.deriveReadiness` or `-D`) to make the
wrapped `Object` report `Ready` only once the PipelineRun's `Succeeded`
condition is `True`. This is implemented via provider-kubernetes
`spec.readiness.policy: DeriveFromCelQuery`, so `function-auto-ready` can
bubble real pipeline success up to the XR. Default is `false` — the
Object is ready on create, unchanged for existing consumers.
