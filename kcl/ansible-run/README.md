# ANSIBLE-RUN

> **What this is:** a **client-side generator for the `AnsibleRun` XR**
> (`resources.stuttgart-things.com/v1alpha1`) — it renders the *request* object
> you `kubectl apply`. It is **not** the Composition renderer; that is
> [`kcl/ansible`](../ansible) (`kcl-tekton-pr`), which turns an `AnsibleRun`
> spec into a Tekton `PipelineRun`.
>
> The **canonical schema** is the XRD in
> [`stuttgart-things/crossplane-configurations`](https://github.com/stuttgart-things/crossplane-configurations)
> (`cicd/ansible-run/apis/definition.yaml`). The fields this generator exposes
> are a **subset** of it — for the full spec and authoritative examples, see
> that XRD and `cicd/ansible-run/examples/xr*.yaml`. Restructure options are
> tracked in [#45](https://github.com/stuttgart-things/stage-time/issues/45).

## RENDER CLAIM (KIND XPLANE SETUP)

```bash
kcl run main.k \
  -D name=vre2-kind-xplane-cluster \
  -D metadataNamespace=default \
  -D wrapInCrossplane=true \
  -D crossplaneNamespace=default \
  -D crossplaneProviderConfig=dev \
  -D namespace=tekton-ci \
  -D ansibleCredentialsSecretName=ansible-credentials \
  -D ansiblePlaybooks='["sthings.container.kind_xplane"]' \
  -D ansibleVarsInventory='["all+[\"10.31.103.27\"]"]' \
  -D ansibleExtraCollections='["https://github.com/stuttgart-things/ansible/releases/download/sthings-container-26.1.713.tar.gz/sthings-container-26.1.713.tar.gz"]' | kubectl apply -f -
```



```bash
kcl run main.k \
  -D name=vre2-base-os \
  -D metadataNamespace=default \
  -D wrapInCrossplane=true \
  -D crossplaneObjectName=vre2-base-os \
  -D crossplaneNamespace=default \
  -D crossplaneProviderConfig=dev \
  -D pipelineRunName=vre2-base-os \
  -D namespace=tekton-ci \
  -D ansibleCredentialsSecretName=ansible-credentials \
  -D ansiblePlaybooks='["sthings.baseos.setup"]' \
  -D ansibleVarsFile='["manage_filesystem+-true","update_packages+-true","ansible_become+-true","ansible_become_method+-sudo"]' \
  -D ansibleVarsInventory='["all+[\"10.31.103.27\"]"]'
```

```bash
kcl run main.k \
  -D ansiblePlaybooks='["sthings.baseos.setup"]' \
  -D ansibleVarsInventory='["all+[\"10.31.103.27\"]"]'
```
