# CLAUDE.md — KCL module `kcl-tekton-pr-packer`

Context for working on this KCL module with Claude Code.

## What & where
- This directory is the KCL module **`kcl-tekton-pr-packer`** (`kcl.mod`:
  package `kcl-tekton-pr-packer`, edition `v0.11.2`, entry `main.k`, dependency
  `tekton-pipelines = "1.0.0"`).
- Purpose: render a Tekton **PipelineRun** for the `build-packer-template`
  pipeline from a `PackerBuild`-shaped input, optionally wrapped in a
  `kubernetes.m.crossplane.io/v1alpha1` **Object** (provider-kubernetes).
- The Packer sibling of [`kcl/ansible`](../ansible) (`kcl-tekton-pr`). The
  client-side XR generator is [`kcl/packer-run`](../packer-run).
- Published manually to `oci://ghcr.io/stuttgart-things/kcl-tekton-pr-packer`
  (OCI tag = `version` in `kcl.mod`). No CI publishes it — `kcl mod push`.
- Files: `main.k` (field resolution + validation + render), `defaults.k`
  (static run settings), `vars.k` (re-exports + name prefix).

## Two-repo split (the key difference vs the ansible module)
`kcl-tekton-pr` conflates pipeline-definition and source repo into one
`gitRepoUrl`. This module keeps them separate because packer templates live in
a DIFFERENT repo than the pipeline:
- `pipelineRepoUrl`/`pipelineRevision`/`pipelinePath` → the PipelineRun's
  `pipelineRef` git resolver (this repo, `pipelines/build-packer-template.yaml`).
- `gitRepoUrl`/`gitRevision`/`gitWorkspaceSubdirectory` → pipeline PARAMS that
  tell the git-clone task which `*.pkr.hcl` to check out
  (`stuttgart-things/stuttgart-things`, `packer/builds/<os>-<lab>-vsphere-<prov>/`).
- `osVersion`+`lab`+`hypervisor`+`provisioning` compose
  `gitWorkspaceSubdirectory` when it isn't set explicitly (mirrors the
  `dispatch-packer-build` action's BUILD_DIR). `hypervisor` defaults to
  `vsphere`; before 0.3.0 it was hardcoded, leaving the `*-proxmox-*` build
  dirs reachable only via an explicit `gitWorkspaceSubdirectory`.

## Optional workspaces
Two workspaces are emitted only when their name field is non-empty, so the
pipeline's optional workspaces stay unbound by default:
- `gitBasicAuthSecretName` → `basicAuth` (required to clone the private
  template repo over https).
- `caCertsConfigMapName` → `caCerts` (required when Vault is behind a private
  CA, else `x509: certificate signed by unknown authority`). Added in 0.4.0 —
  before that the module emitted no `caCerts` workspace at all, so the
  Crossplane XR path could not build against the LabUL Vault even though the
  pipeline supported it.

`pipelineRevision` defaults to a PINNED tag, not `main`: the git resolver
fetches the pipeline definition at render time, so an unpinned default
silently changes what runs whenever stage-time's main moves.

## Invocation contract (two modes)
Same as `kcl-tekton-pr`: Composition mode (`params.oxr.spec` + `ctx` env +
`ocds` + `dxr`, output `items=[...]`) or flat `-D` mode (single resource).
Precedence: `oxr.spec.<field>` → EnvironmentConfig → `-D` option → default.

## Opt-in readiness
`deriveReadiness` (default `false`): only takes effect with
`wrapInCrossplane=true` — it adds `spec.readiness.policy: DeriveFromCelQuery`
to the Object so it is Ready only once the PipelineRun's `Succeeded` condition
is True. Bare PipelineRun → silent no-op.

## Local render / test
```bash
kcl run main.k -D osVersion=ubuntu24 -D lab=labul -D provisioning=base-os -D wrapInCrossplane=true
```
Always render before bumping the version — `kcl` is the source of truth for
whether the module is valid.

## Consumer
`stuttgart-things/crossplane-configurations` → `cicd/packer-build`:
the Composition's `render-pipelinerun` step pins a specific tag of this module.
The pinned version MUST be published or the Configuration's verify CI fails
with `failed to resolve <v>: ...kcl-tekton-pr-packer:<v>: not found`. Order:
bump `kcl.mod` → `kcl mod push` → bump the pin in the consumer.

**The ghcr package must stay PUBLIC.** function-kcl pulls anonymously, so any
Composition pinning this module fails to render with `401 unauthorized` the
moment the package is private. A new package defaults to private, and the fix
is UI-only — `PATCH /orgs/{org}/packages/container/{pkg}` returns 404. Check
after every first push of a new package:

```bash
T=$(curl -s "https://ghcr.io/token?scope=repository:stuttgart-things/kcl-tekton-pr-packer:pull" | jq -r .token)
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $T" \
  https://ghcr.io/v2/stuttgart-things/kcl-tekton-pr-packer/manifests/<version>
```

200 = public, 401 = private.
