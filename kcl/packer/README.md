# kcl-tekton-pr-packer

> Renders a Tekton **PipelineRun** for the `build-packer-template` pipeline
> from a `PackerBuild`-shaped input, optionally wrapped in a
> `kubernetes.m.crossplane.io/v1alpha1` **Object** (provider-kubernetes) so
> Crossplane applies it on a target cluster.
>
> This is the Packer sibling of [`kcl/ansible`](../ansible)
> (`kcl-tekton-pr`). It is the **renderer** the Crossplane Composition
> consumes; for the `PackerBuild` XR itself see the XRD and examples in
> `crossplane-configurations` (`cicd/packer-build/apis/definition.yaml`,
> `cicd/packer-build/examples/xr*.yaml`).

Published manually to `oci://ghcr.io/stuttgart-things/kcl-tekton-pr-packer`
(the OCI tag = `version` in `kcl.mod`):

```bash
kcl mod push oci://ghcr.io/stuttgart-things/kcl-tekton-pr-packer
```

## Two repos, on purpose

Unlike the ansible module, this one keeps the **pipeline definition** and the
**template source** as separate refs:

- `pipelineRepoUrl` / `pipelineRevision` / `pipelinePath` — where
  `build-packer-template.yaml` lives (this repo, `stage-time`).
- `gitRepoUrl` / `gitRevision` / `gitWorkspaceSubdirectory` — where the
  `*.pkr.hcl` templates live (`stuttgart-things/stuttgart-things`, under
  `packer/builds/<os>-<lab>-vsphere-<provisioning>/`).

`osVersion` + `lab` + `provisioning` compose `gitWorkspaceSubdirectory`
automatically (mirroring the `dispatch-packer-build` action's `BUILD_DIR`)
when it isn't set explicitly.

## Invocation contract (two modes)

`main.k` reads `option("params")` and supports both:

- **Composition mode** (`function-kcl`): `params.oxr.spec`,
  `params.ctx["apiextensions.crossplane.io/environment"]`, `params.ocds`,
  `params.dxr`. Output: `items = [...]`.
- **Flat / `-D` mode** (local runs): `-D key=value` overrides. Output: a
  single resource.

Per-field precedence: `oxr.spec.<field>` → EnvironmentConfig (`_env`) → `-D`
option → hardcoded default.

## Local render

```bash
# Flat mode (build ubuntu24 in labul, base-os provisioning):
kcl run main.k \
  -D osVersion=ubuntu24 \
  -D lab=labul \
  -D provisioning=base-os \
  -D wrapInCrossplane=true

# Explicit subdirectory + restrict to one source:
kcl run main.k \
  -D gitWorkspaceSubdirectory=packer/builds/ubuntu24-labul-vsphere-base-os \
  -D packerOnly=vsphere-iso.ubuntu24
```

## vSphere template UUID (0.7.0)

`templateLookupVaultPath` / `templateLookupInsecure` (spec → EnvironmentConfig →
`-D`) become the pipeline params of the same name, which make execute-packer
read the built template's `config.uuid` with govc into the `template-uuid`
result. The path is the Vault KV v2 path the packer template reads its vCenter
credentials from (e.g. `cloud/data/vsphere-labda`, keys
`username`/`password`/`ip`). Both are emitted **only when set**: Tekton rejects
a param the pipeline does not declare, so a caller pinned below stage-time
v0.13.8 keeps working. The lookup is best effort; a failure is a warning in the
TaskRun log and an empty result, never a failed build.

```bash
kcl run main.k -D osVersion=ubuntu26 -D lab=labda -D provisioning=base-os \
  -D templateLookupVaultPath=cloud/data/vsphere-labda -D templateLookupInsecure=true
```

## Readiness

`deriveReadiness` (default `false`): when true AND `wrapInCrossplane=true`, the
wrapped Object reports `Ready` only once the PipelineRun's `Succeeded`
condition is `True`. With a bare PipelineRun it is a silent no-op.
