# KCL-ANSIBLE-PR

```bash
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr \
  -D storageSize="5000Mi" \
  -D storageAccessModes="ReadWriteMany" \
  -D ansiblePlaybooks='["sthings.baseos.prepare_env", "sthings.baseos.setup", "sthings.apps.deploy"]'
```
