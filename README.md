# stuttgart-things/stage-time

collection of tekton pipeline building blocks

## DEPLOY TEKTON

<details><summary>OPERATOR+PIPELINES</summary>

```bash
helm upgrade --install tekton \
-n tekton-operator \
--create-namespace \
oci://ghcr.io/stuttgart-things/tekton/tekton \
--version 0.77.0
```

</details>

## PIPELINERUN EXAMPLES

<details><summary>BUILD CONTAINER-IMAGE w/BUILDAH (w/o GIT/REG SECRETS)</summary>

```bash
kubectl apply -f - <<EOF
---
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  annotations:
  labels:
    tekton.dev/pipeline: build-image-buildah
  name: build-push-image
spec:
  pipelineRef:
    params:
    - name: url
      value: https://github.com/stuttgart-things/stage-time.git
    - name: revision
      value: main
    - name: pathInRepo
      value: pipelines/build-image-buildah.yaml
    resolver: git
  workspaces:
    - name: shared-data
      volumeClaimTemplate:
        metadata:
          creationTimestamp: null
        spec:
          accessModes:
          - ReadWriteOnce
          resources:
            requests:
              storage: 50Mi
          storageClassName: openebs-hostpath
    # - name: basic-auth
    #   secret:
    #     secretName: basic-auth
    # - name: dockerconfig
    #   secret:
    #     secretName: incluster
    # - name: registries-conf
    #   configMap:
    #     name: buildah-shortnames
  params:
    - name: git-url
      value: https://github.com/patrickloeber/python-docker-tutorial
    - name: branch-name
      value: main
    - name: verify-ssl
      value: "false"
    - name: image-name
      value: "ttl.sh/python:v1"
    - name: context
      value: example1
EOF
```

</details>

<details><summary>EXECUTE-ANSIBLE-PLAYBOOKS</summary>

## CREATE NAMESPACE

```bash
kubectl create ns tekton-ci
```

## CREATE SSH USER-CREDS AS SECRET

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: ansible-credentials
  namespace: tekton-ci
type: Opaque
stringData:
  ANSIBLE_USER: ""
  ANSIBLE_PASSWORD: ""
EOF
```

## CREATE SSH USER-CREDS AS SECRET

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: vault
  namespace: tekton-ci
type: Opaque
stringData:
  VAULT_NAMESPACE: root
  VAULT_ROLE_ID: ""
  VAULT_SECRET_ID: ""
  VAULT_ADDR: ""
EOF
```

## PIPELINERUN

<details><summary>RUN (AT LEAST 1) PLAY FROM GIT SOURCE</summary>

```bash
kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: run-ansible-test-5
  namespace: tekton-ci
spec:
  params:
  - name: ansibleVerbosity
    value: "2"
  - name: validateInventory
    value: "true"
  - name: ansibleWorkingImage
    value: ghcr.io/stuttgart-things/sthings-ansible:11.11.0
  - name: createInventory
    value: "true"
  - name: ansibleTargetHost
    value: all
  - name: gitRepoUrl
    value: https://github.com/stuttgart-things/stage-time.git
  - name: gitRevision
    value: main
  - name: gitWorkspaceSubdirectory
    value: /ansible/workdir/
  - name: ansibleCredentialsSecretName
    value: "ansible-credentials"
  - name: ansibleCredentialsUserKey
    value: "ANSIBLE_USER"
  - name: ansibleCredentialsPasswordKey
    value: "ANSIBLE_PASSWORD"
  - name: installExtraRoles
    value: "true"
  - name: ansibleExtraRoles
    value:
    - https://github.com/stuttgart-things/install-requirements.git,2024.05.11
  - name: ansiblePlaybooks
    value:
      - sthings.baseos.setup
  - name: ansibleVarsFile
    value:
    - manage_filesystem+-true
    - update_packages+-true
    - ansible_become+-true
    - ansible_become_method+-sudo
  - name: ansibleVarsInventory
    value:
    - all+["10.31.102.107"]
  - name: ansibleExtraCollections
    value:
    - community.general:10.1.0
    - https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz
  - name: installExtraCollections
    value: "true"
  pipelineRef:
    params:
    - name: url
      value: https://github.com/stuttgart-things/stage-time.git
    - name: revision
      value: main
    - name: pathInRepo
      value: pipelines/execute-ansible-playbooks.yaml
    resolver: git
  taskRunTemplate:
    serviceAccountName: default
  timeouts:
    pipeline: 1h0m0s
  workspaces:
  - name: shared-workspace
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 20Mi
        storageClassName: openebs-hostpath
EOF
```

</details>

<details><summary>RUN PLAYS FROM COLLECTIONS ONLY (NO GIT CLONE)</summary>

```bash
kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: run-ansible-from-collections-1
  namespace: tekton-ci
spec:
  pipelineRef:
    params:
    - name: url
      value: https://github.com/stuttgart-things/stage-time.git
    - name: revision
      value: main
    - name: pathInRepo
      value: pipelines/execute-ansible-playbooks-from-collections.yaml
    resolver: git
  taskRunTemplate:
    serviceAccountName: default
  timeouts:
    pipeline: 1h0m0s
  params:
    # Ansible execution
    - name: ansiblePlaybooks
      value:
        - sthings.baseos.setup
    - name: ansibleTargetHost
      value: all
    - name: ansibleWorkingImage
      value: ghcr.io/stuttgart-things/sthings-ansible:11.11.0
    # Collections
    - name: ansibleExtraCollections
      value:
        - community.general:10.1.0
        - https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz
    - name: installExtraCollections
      value: "true"
    # Inventory / vars
    - name: createInventory
      value: "true"
    - name: ansibleVarsInventory
      value:
        - all+["10.31.102.107"]
    - name: ansibleVarsFile
      value:
        - manage_filesystem+-true
        - update_packages+-true
        - ansible_become+-true
        - ansible_become_method+-sudo
    - name: varsFile
      value: ""
    - name: inventory
      value: ""
    # Runtime
    - name: userHome
      value: "/home/nonroot"
    - name: vaultSecretName
      value: vault
    # Credentials
    - name: ansibleCredentialsSecretName
      value: ansible-credentials
    - name: ansibleCredentialsUserKey
      value: ANSIBLE_USER
    - name: ansibleCredentialsPasswordKey
      value: ANSIBLE_PASSWORD
  workspaces:
    - name: shared-workspace
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 20Mi
          storageClassName: openebs-hostpath
EOF
```

</details>

## DEV

<details><summary>TEST CHART w/ VCLUSTER</summary>

```bash
helm upgrade --install tekton-vcluster \
vcluster --repo https://charts.loft.sh \
--namespace vcluster \
--repository-config='' \
--create-namespace

vcluster connect tekton-chart-release -n vcluster
```

</details>

## USUAGE SNIPPETS

<details><summary>FEATURE GATE TO BE "ALPHA" OR "BETA"</summary>

```bash
validation.webhook.pipeline.tekton.dev" denied the request: validation failed: resolver params requires "enable-api-fields" feature gate to be "alpha" or "beta" but it is "stable":
```

```bash
kubectl edit configmap feature-flags -n tekton-pipelines

# Change the enable-api-fields field to beta:
#data:
#  enable-api-fields: "beta"

kubectl rollout restart deployment tekton-pipelines-controller -n tekton-pipelines
kubectl rollout restart deployment tekton-pipelines-webhook -n tekton-pipelines
```

</details>
