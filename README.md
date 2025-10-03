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

```bash
kubectl apply -f - <<EOF
---
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  annotations:
  labels:
    tekton.dev/pipeline: execute-ansible-playbooks
  name: monday51
  namespace: tekton-ci
spec:
  params:
  - name: ansibleWorkingImage
    value: ghcr.io/stuttgart-things/sthings-ansible:11.0.0
  - name: createInventory
    value: "true"
  - name: ansibleTargetHost
    value: all
  - name: gitRepoUrl
    value: https://github.com/stuttgart-things/stuttgart-things.git
  - name: gitRevision
    value: main
  - name: gitWorkspaceSubdirectory
    value: /ansible/workdir/
  - name: vaultSecretName
    value: vault
  #- name: inventory
  #  value: W2luaXRpYWxfbWFzdGVyX25vZGVdCjEwLjMxLjEwMy40MwoKW2FkZGl0aW9uYWxfbWFzdGVyX25vZGVzXQo=
  - name: installExtraRoles
    value: "true"
  - name: ansibleExtraRoles
    value:
    - https://github.com/stuttgart-things/install-requirements.git,2024.05.11
    - https://github.com/stuttgart-things/manage-filesystem.git,2024.06.07
    - https://github.com/stuttgart-things/install-configure-vault.git
    - https://github.com/stuttgart-things/create-send-webhook.git,2024-06-06
  - name: ansiblePlaybooks
    value:
    - ansible/playbooks/prepare-env.yaml
    - ansible/playbooks/base-os.yaml
  - name: ansibleVarsFile
    value:
    - manage_filesystem+-true
    - update_packages+-true
    - install_requirements+-true
    - install_motd+-true
    - username+-sthings
    - lvm_home_sizing+-'15%'
    - lvm_root_sizing+-'35%'
    - lvm_var_sizing+-'50%'
    - send_to_msteams+-true
    - reboot_all+-false
  - name: ansibleVarsInventory
    value:
    - all+["10.31.103.27"]
  - name: ansibleExtraCollections
    value:
    - community.crypto:2.22.3
    - community.general:10.1.0
    - ansible.posix:2.0.0
    - kubernetes.core:5.0.0
    - community.docker:4.1.0
    - community.vmware:5.2.0
    - awx.awx:24.6.1
    - community.hashi_vault:6.2.0
    - ansible.netcommon:7.1.0
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
      metadata:
        creationTimestamp: null
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
