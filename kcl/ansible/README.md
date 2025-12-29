# KCL-ANSIBLE-PR

## DEV

<details><summary>PUSH MODULE</summary>

```bash
kcl mod push oci://ghcr.io/stuttgart-things/kcl-tekton-pr
```

</details>

## USAGE

<details><summary>EXAMPLE RENDERING</summary>

```bash
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr --tag 0.3.0 \
  -D storageSize="5000Mi" \
  -D storageAccessModes="ReadWriteMany" \
  -D ansiblePlaybooks='["sthings.baseos.prepare_env", "sthings.baseos.setup", "sthings.apps.deploy"]' \
  -D ansibleExtraCollections='["community.crypto:2.22.3", "community.general:10.1.0", "community.vmware:5.2.0"]' -D ansiblePlaybooks='["sthings.baseos.prepare_env", "sthings.baseos.setup"]'
```

</details>

<details><summary>RENDER + APPLY (w/ PLAYS FROM GIT)</summary>

```bash
# RENDER + APPLY
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr --tag 0.3.0 \
-D pipelineRunName="run-ansible-test-6" \
-D namespace="tekton-ci" \
-D storageSize="20Mi" \
-D storageAccessModes="ReadWriteOnce" \
-D ansibleWorkingImage="ghcr.io/stuttgart-things/sthings-ansible:11.11.0" \
-D createInventory="true" \
-D ansibleTargetHost="all" \
-D gitRepoUrl="https://github.com/stuttgart-things/stage-time.git" \
-D gitRevision="main" \
-D gitWorkspaceSubdirectory="/ansible/workdir/" \
-D ansibleCredentialsSecretName="ansible-credentials" \ # pragma: allowlist secret
-D ansibleCredentialsUserKey="ANSIBLE_USER" \
-D ansibleCredentialsPasswordKey="ANSIBLE_PASSWORD" \ # pragma: allowlist secret
-D installExtraRoles="true" \
-D ansibleExtraRoles='["https://github.com/stuttgart-things/install-requirements.git,2024.05.11"]' \
-D ansiblePlaybooks='["sthings.baseos.setup"]' \
-D ansibleVarsFile='["manage_filesystem+-true", "update_packages+-true", "ansible_become+-true", "ansible_become_method+-sudo"]' \
-D ansibleVarsInventory='["all+[\"10.31.102.107\"]"]' \
-D ansibleExtraCollections='["community.general:10.1.0", "https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz"]' \
-D installExtraCollections="true" \
-D ansibleVerbosity="2" \
-D validateInventory="true" \
-D gitPath="pipelines/execute-ansible-playbooks.yaml" | kubectl apply -f -
```

</details>

<details><summary>RENDER + APPLY (w/ PLAYS FROM COLLECTIONS ONLY / NO GIT-CLONE IN PIPELINE)</summary>

```bash
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-pr --tag 0.3.0 \
  -D pipelineRunName="run-ansible-from-collections-1" \
  -D namespace="tekton-ci" \
  -D storageSize="20Mi" \
  -D storageAccessModes="ReadWriteOnce" \
  -D ansibleWorkingImage="ghcr.io/stuttgart-things/sthings-ansible:11.11.0" \
  -D ansiblePlaybooks='["sthings.baseos.setup"]' \
  -D ansibleTargetHost="all" \
  -D ansibleExtraCollections='["community.general:10.1.0", "https://github.com/stuttgart-things/ansible/releases/download/sthings-baseos-25.4.118.tar.gz/sthings-baseos-25.4.118.tar.gz"]' \
  -D installExtraCollections="true" \
  -D createInventory="true" \
  -D ansibleVarsInventory='["all+[\"10.31.102.107\"]"]' \
  -D ansibleVarsFile='["manage_filesystem+-true", "update_packages+-true", "ansible_become+-true", "ansible_become_method+-sudo"]' \
  -D varsFile="" \
  -D inventory="" \
  -D userHome="/home/nonroot" \
  -D vaultSecretName="vault" \ # pragma: allowlist secret
  -D ansibleCredentialsSecretName="ansible-credentials" \ # pragma: allowlist secret
  -D ansibleCredentialsUserKey="ANSIBLE_USER" \
  -D ansibleCredentialsPasswordKey="ANSIBLE_PASSWORD" \ # pragma: allowlist secret
  -D gitPath="pipelines/execute-ansible-playbooks-from-collections.yaml"
```

</details>
