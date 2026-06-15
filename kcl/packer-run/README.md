# PACKER-RUN

> **What this is:** a **client-side generator for the `PackerBuild` XR**
> (`resources.stuttgart-things.com/v1alpha1`) — it renders the *request* object
> you `kubectl apply`. It is **not** the Composition renderer; that is
> [`kcl/packer`](../packer) (`kcl-tekton-pr-packer`), which turns a
> `PackerBuild` spec into a Tekton `PipelineRun`.
>
> The **canonical schema** is the XRD in
> [`stuttgart-things/crossplane-configurations`](https://github.com/stuttgart-things/crossplane-configurations)
> (`cicd/packer-build/apis/definition.yaml`). The fields this generator exposes
> are a **subset** of it — for the full spec and authoritative examples, see
> that XRD and `cicd/packer-build/examples/xr*.yaml`.

## RENDER XR (build a golden image)

```bash
kcl run main.k \
  -D name=ubuntu24-labul-base-os \
  -D metadataNamespace=default \
  -D wrapInCrossplane=true \
  -D crossplaneProviderConfig=dev \
  -D namespace=tekton-ci \
  -D osVersion=ubuntu24 \
  -D lab=labul \
  -D provisioning=base-os \
  -D credentialsSecretName=packer-credentials | kubectl apply -f -
```

## RENDER XR (explicit subdirectory, restrict to one source)

```bash
kcl run main.k \
  -D name=rocky9-labda \
  -D gitWorkspaceSubdirectory=packer/builds/rocky9-labda-vsphere-base-os \
  -D packerOnly=vsphere-iso.rocky9
```
