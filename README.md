# stuttgart-things/stage-time

collection of tekton pipelines building blocks

## PIPELINERUN EXAMPLES

<details><summary>PipelineRun</summary>

```bash
kubectl apply -f - <<EOF
---
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  annotations:
  labels:
    tekton.dev/pipeline: execute-ansible-playbooks
  name: monday5-9
  namespace: tekton-pipelines
spec:
  params:
  - name: ansibleWorkingImage
    value: ghcr.io/stuttgart-things/sthings-ansible:11.0.0
  - name: createInventory
    value: "false"
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
  - name: inventory
    value: W2luaXRpYWxfbWFzdGVyX25vZGVdCjEwLjMxLjEwMy40MwoKW2FkZGl0aW9uYWxfbWFzdGVyX25vZGVzXQo=
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
    - all+["10.31.103.43"]
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
EOT
```

</details>
