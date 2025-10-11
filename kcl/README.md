# stage-time/kcl

## OVERWRITE AT RUNTIME

```bash
kcl run \
  -D storageSize="5000Mi" \
  -D storageAccessModes="ReadWriteMany" \
  -D ansiblePlaybooks='["sthings.baseos.prepare_env", "sthings.baseos.setup", "sthings.apps.deploy"]' \
  -D ansibleExtraCollections='["community.crypto:2.22.3", "community.general:10.1.0", "community.vmware:5.2.0"]' -D ansiblePlaybooks='["sthings.baseos.prepare_env", "sthings.baseos.setup"]'
```

kcl run -D gitUrl=https://github.com/stuttgart-things/stage-time -D branchName=main -D context=tests/test-app -D verifySsl='"true"' | kubectl -n tekton-ci apply -f -


## DEV

```bash
kcl mod push oci://ghcr.io/stuttgart-things/kcl-tekton-pr
```



kcl run --quiet oci://ghcr.io/stuttgart-things/kcl-tekton-buildah



| kubectl -n tekton-ci apply -f -
