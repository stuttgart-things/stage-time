# CLAUDE.md — KCL module `kcl-tekton-pr`

Context for working on this KCL module with Claude Code.

## What & where
- This directory is the KCL module **`kcl-tekton-pr`** (`kcl.mod`: package
  name `kcl-tekton-pr`, edition `v0.11.2`, entry `main.k`, dependency
  `tekton-pipelines = "1.0.0"`).
- Purpose: render a Tekton **PipelineRun** (for running Ansible playbooks)
  from an `AnsibleRun`-shaped input, optionally wrapped in a
  `kubernetes.m.crossplane.io/v1alpha1` **Object** (provider-kubernetes) so
  Crossplane applies it on a target cluster.
- Published manually to `oci://ghcr.io/stuttgart-things/kcl-tekton-pr`
  (the OCI tag = `version` in `kcl.mod`). There is **no** CI that publishes
  it — see "Publish" below.
- Files: `main.k` (field resolution + validation + render), `defaults.k`
  (static run settings), `vars.k` (re-exports + name prefix), `README.md`.

## Invocation contract (two modes)
`main.k` reads `option("params")` and supports both:

- **Composition mode** (driven by `function-kcl`): inputs are
  `params.oxr.spec` (the XR spec), `params.ctx["apiextensions.crossplane.io/environment"]`
  (EnvironmentConfig data merged by `function-environment-configs`),
  `params.ocds` (observed composed resources), `params.dxr` (desired XR).
  Output: `items = [...]`.
- **Flat / `-D` mode** (local runs): `-D key=value` overrides, no `oxr`.
  Output: a single resource.

Per-field resolution precedence (see the `_x = _flat_params?.x or _env?.x
or option("x") or <default>` chains in `main.k`):

```
oxr.spec.<field>  →  EnvironmentConfig (_env)  →  -D option  →  hardcoded default
```

EnvironmentConfig provides shared *defaults* only (XR spec always wins) for:
`gitRepoUrl`, `gitRevision`, `gitPath`, `storageClass`, `ansibleWorkingImage`,
`namespace`, `ansibleExtraCollections`, `ansibleCredentialsSecretName`,
`extraEnvSecretName`.

## Env injection (`extraEnvSecretName`)
Names a Secret whose keys are injected verbatim as environment variables into
the playbook step (`envFrom.secretRef`, `optional: true`) — for playbooks that
read credentials via `lookup('env', ...)`, e.g. `SOPS_AGE_KEY` /
`SOPS_GIT_TOKEN` in the machinery bootstrap.

Deliberately one Secret *name*, not a list of `{envVar, secretName, key}`:
**Tekton cannot render a variable number of `env` entries from an array
param**, so a list would need a task param per variable. `envFrom` is applied
by Kubernetes *before* `env`, so the explicitly named vars in the task
(`ANSIBLE_PASSWORD`, `VAULT_*`) still win on a key collision.

Empty by default and emitted into `_pipeline_params_override` **only when
set** — Tekton rejects params a pipeline does not declare, so an unset value
keeps XRs pinned to a pre-`v0.11.0` `pipelineRevision` renderable.

## Opt-in readiness
`deriveReadiness` (default `false`): when true, the wrapped Object gets
`spec.readiness.policy: DeriveFromCelQuery` so it reports `Ready` only once
the PipelineRun's `Succeeded` condition is `True`. Keep it opt-in — other
consumers of this module rely on the default "ready on create".

**`deriveReadiness` only takes effect together with `wrapInCrossplane=true`.**
The readiness policy lives in the Crossplane `Object` wrapper (`main.k`,
`if _deriveReadiness:` block), which is only emitted when `wrapInCrossplane`
is true. With `wrapInCrossplane` false (a bare `PipelineRun`), setting
`deriveReadiness:true` is a silent no-op.

## Local render / test
```bash
# Flat mode (fast iteration):
kcl run main.k \
  -D ansiblePlaybooks='["sthings.baseos.setup"]' \
  -D ansibleVarsInventory='["all+[\"10.0.0.1\"]"]' \
  -D wrapInCrossplane=true

# Simulate composition mode (oxr + ctx + ocds):
kcl run main.k -D params='{
  "oxr": {"spec": {"pipelineRunName":"t","namespace":"tekton-ci",
                   "ansiblePlaybooks":["sthings.baseos.setup"],
                   "wrapInCrossplane":true,
                   "deriveReadiness":true}},
  "ctx": {"apiextensions.crossplane.io/environment": {"gitRevision":"dev"}},
  "ocds": {}
}'
```
Always run a render before bumping the version — `kcl` is the source of
truth for whether the module is valid.

## Publish (manual)
```bash
# kcl.mod must already carry the target version.
kcl mod push oci://ghcr.io/stuttgart-things/kcl-tekton-pr
```

## Consumer
`stuttgart-things/crossplane-configurations` → `cicd/ansible-run`:
- The Composition step `render-pipelinerun` pins a specific tag of this
  module (`oci://...kcl-tekton-pr:<version>`).
- A separate inline `function-kcl` step (`derive-status`) reads `ocds` and
  patches the `AnsibleRun` status from the live PipelineRun; then
  `function-auto-ready` runs.
- **The pinned version must be published** or the Configuration's `verify`
  CI fails with `failed to resolve <v>: ...kcl-tekton-pr:<v>: not found`.
  So: bump `kcl.mod` → `kcl mod push` → bump the pin in the consumer.

## Notes / limitations
- The `derive-status` logic lives in the **consumer** Composition, not in
  this module. Keep rendering concerns here; keep status-mapping there.
- Per-TaskRun status is not available from the PipelineRun's
  `childReferences` (only `name` + `pipelineTaskName`); surfacing per-TaskRun
  success would require observing the TaskRun objects too.
