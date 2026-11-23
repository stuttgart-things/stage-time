# stuttgart-things/stage-time

[![Pre-commit](https://github.com/stuttgart-things/stage-time/actions/workflows/pre-commit.yaml/badge.svg)](https://github.com/stuttgart-things/stage-time/actions/workflows/pre-commit.yaml)
[![KCL Validate](https://github.com/stuttgart-things/stage-time/actions/workflows/kcl-validate.yaml/badge.svg)](https://github.com/stuttgart-things/stage-time/actions/workflows/kcl-validate.yaml)

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
    - name: ansibleVerbosity
      value: "2"
    - name: validateInventory
      value: "true"
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

<details><summary>EXECUTE AI-PERSONA RUN (stuttgart-things/ai-personas)</summary>

One persona × scenario × lab: `claude -p` in the ai-personas runner image with only the persona's short-lived ZITADEL token. Three pods (`tasks/persona-credentials.yaml`, `tasks/persona-run.yaml`, `tasks/persona-publish.yaml`), so the claude pod never holds Vault or git credentials and can get a narrow egress policy. Only `merge: auto` scenarios by default (`allowHumanMerge: "true"` overrides).

| Pipeline task | Task file | Image | Secrets | Egress | Does |
| --- | --- | --- | --- | --- | --- |
| `credentials` | `tasks/persona-credentials.yaml` | runner | `vault-ai-personas-runner` (AppRole) | Vault, ZITADEL | checks persona and scenario (`merge: auto`, ssh or not), sets the run id; AppRole login → the persona's client credentials → short-lived ZITADEL token; for ssh scenarios a throwaway key signed by the Vault SSH CA; writes both to `credentials/`, revokes the Vault token |
| `run` | `tasks/persona-run.yaml` | runner | `anthropic` (API key or Claude Code OAuth token) | claim-machinery-api, order service, ZITADEL, Anthropic API (+ VMs on 22 for ssh) | moves token and key into memory and wipes them from the volume; `egress-check`: the Vault from `credentials` and `egressDenied` (GitHub) must be unreachable, else no run; then runs the image's unchanged `persona-run`: `claude -p` with only the persona's token; afterwards the runner tears down what the persona ordered (`cleanup: delete-claim`, ai-personas ADR 0007); leak check at the end (exit 3, nothing published) |
| `publish` | `tasks/persona-publish.yaml` | sthings-packer (git, jq) | `persona-runs-token` | github.com | `publish-run` from ai-personas at `aiPersonasRevision`: report to `runs/<scenario>/<time>-<persona>/` in the private runs repo, indexes regenerated; skipped when `runsRepo` is empty |
| `verdict` | inline | runner | – | – | only with `verifyStrict: "true"`, after `publish`: prints the runner's `verdict.json` (ai-personas `persona-verdict`) and fails the pipeline unless it passed -- a gate, e.g. Kargo's verification on machinery-dev (stuttgart-things#4828); pipeline result `verdict` |
| `wipe-credentials` (finally) | inline | runner | – | – | deletes `credentials/` in any case and fails if anything is left |

## SECRETS

The commands below show what the pipeline expects, for a first try by hand. For a lab you keep running, put all of it in Git instead, next to the cluster's other state:
- the Vault AppRole and its policy as Terraform;
- the Secrets SOPS-encrypted, applied by an operator (e.g. sops-secrets-operator);
- the CA ConfigMap and the egress policy as plain manifests in the cluster's Flux/Argo path.

No step of the pipeline needs anything created by hand. The Claude credential is the one personal piece: `claude setup-token` is bound to one person's subscription. Regular runs need an API key with a spend limit.

```bash
# Vault AppRole: read on ai-personas/data/<lab>/*, update on <sshCaMount>/sign/persona-*
kubectl -n tekton-ci create secret generic vault-ai-personas-runner \
  --from-literal=VAULT_ADDR=https://vault.example.com \
  --from-literal=VAULT_ROLE_ID=<role-id> \
  --from-literal=VAULT_SECRET_ID=<secret-id>

# Claude credential, ONE of the two keys; persona-run takes the Secret as env:
#   ANTHROPIC_API_KEY        API key, for regular CI
#   CLAUDE_CODE_OAUTH_TOKEN  `claude setup-token` (one person's subscription), test phase only
kubectl -n tekton-ci create secret generic anthropic --from-literal=CLAUDE_CODE_OAUTH_TOKEN=<token>

# token with contents:write on the private runs repo
kubectl -n tekton-ci create secret generic persona-runs-token --from-literal=token=<token>

# the lab's root CA, key must be ca.pem
kubectl -n tekton-ci create configmap lab-ca --from-file=ca.pem=<root-ca.pem>
```

## PIPELINERUN

```bash
kubectl create -f - <<EOF
---
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: persona-developer-
  namespace: tekton-ci
spec:
  pipelineRef:
    resolver: git
    params:
      - name: url
        value: https://github.com/stuttgart-things/stage-time.git
      - name: revision
        value: v0.13.13
      - name: pathInRepo
        value: pipelines/execute-persona-run.yaml
  timeouts:
    pipeline: 2h30m   # order + build + ssh check, then the runner's teardown (up to 45 min)
  taskRunTemplate:
    podTemplate:
      securityContext:
        fsGroup: 10001   # the runner image's persona uid writes the volume
  workspaces:
    - name: shared-workspace
      volumeClaimTemplate:
        spec:
          accessModes: [ReadWriteOnce]
          resources:
            requests:
              storage: 50Mi
          storageClassName: openebs-hostpath
    - name: caCerts
      configMap:
        name: lab-ca
  params:
    - name: persona
      value: developer
    - name: scenario
      value: verify-vm-ssh-auto
    - name: lab
      value: labul
    - name: claimApiUrl
      value: https://claim-api.example.com
    - name: orderApiUrl
      value: https://orders.example.com
    - name: managementCluster   # where the lab has several (v0.13.13+)
      value: machinery-dev
    - name: verifyStrict        # fail the pipeline unless the runner's verdict passed (v0.13.13+)
      value: "true"
    - name: runsRepo
      value: <owner>/<private-runs-repo>
    - name: runnerImage   # tag = ai-personas commit
      value: ghcr.io/stuttgart-things/ai-personas-runner:ba325bce3ac6337cb070c1a863ed3d7b40c7b5f6
    - name: aiPersonasRevision   # same commit, for publish-run
      value: ba325bce3ac6337cb070c1a863ed3d7b40c7b5f6
EOF
```

## NETWORKPOLICY FOR THE CLAUDE POD

The `run` pod carries the label `tekton.dev/pipelineTask: run`. NetworkPolicies match IPs, not hostnames: fill in the CIDRs of the lab services and the Anthropic API's published ranges.

**If a lab service is served by the Gateway/Ingress of the same cluster, and the CNI is Cilium:** use a `CiliumNetworkPolicy` with `toFQDNs` (plus a DNS rule on kube-dns with `dns: [{matchPattern: "*"}]`) instead of IP blocks. The policy also needs two more rules:
- `toEntities: [ingress]` for the Gateway itself;
- egress `toEndpoints` to the **backend pods** behind the route, on their container port.

Cilium's Gateway Envoy checks the client's egress policy a second time, against the backend it routes to. Without the backend rule the connection to the Gateway goes through, but every request gets `403 Access denied` from Envoy, even `/health`. It looks like an authorization problem of the service, which it is not.

```yaml
# Cilium variant, the part that differs (claim-machinery-api behind the cluster's own Gateway)
  egress:
    - toEntities: [ingress]
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: claim-machinery
            app.kubernetes.io/name: claim-machinery-api
      toPorts:
        - ports: [{port: "8080", protocol: TCP}]
```

Before the persona starts, the `run` task's `egress-check` step checks that Vault and `egressDenied` are not reachable. That covers the negative side. Whether the allowed services work only shows in a run: check its report for 403s on `claims templates` / `claims clusters`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: persona-run-egress
  namespace: tekton-ci
spec:
  podSelector:
    matchLabels:
      tekton.dev/pipeline: execute-persona-run
      tekton.dev/pipelineTask: run
  policyTypes: [Egress]
  egress:
    - ports: [{port: 53, protocol: UDP}, {port: 53, protocol: TCP}]
    - to:   # claim-machinery-api, machinery-order-service, ZITADEL
        - ipBlock: {cidr: <lab-ingress-cidr>}
      ports: [{port: 443, protocol: TCP}]
    - to:   # Anthropic API
        - ipBlock: {cidr: <anthropic-api-cidr>}
      ports: [{port: 443, protocol: TCP}]
    - to:   # only for ssh scenarios: the lab's VM network
        - ipBlock: {cidr: <lab-vm-cidr>}
      ports: [{port: 22, protocol: TCP}]
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
