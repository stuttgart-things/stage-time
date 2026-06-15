# STAGE-TIME/TASKS

<details><summary>SET GITEA STATUS</summary>

Go to http://${GITEA_SERVER}$/user/settings/applications

```bash
kubectl create secret generic gitea \
--from-literal=token=<TOKEN> \
-n tekton-ci
```

```bash
kubectl apply -f - <<EOF
---
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: gitea-set-status-test3
  namespace: tekton-ci
spec:
  taskRef:
    name: gitea-set-status
  params:
    - name: GITEA_PROTOCOL
      value: "http"
    - name: GITEA_HOST
      value: "10.100.136.150:30083"
    - name: REPO_FULL_NAME
      value: "gitea_admin/source"
    - name: COMMIT_SHA
      value: "80b8528fcea3c0ca416732c455b6dd30f9da49d4" #pragma: allowlist secret
    - name: STATE
      value: "success" # or failure, pending, warning, error
    - name: DESCRIPTION
      value: "Test commit status from Tekton"
    #- name: TARGET_URL
    #  value: "http://tekton-dashboard.example.com" # optional
    - name: GITEA_TOKEN_SECRET_NAME
      value: "gitea"
    - name: GITEA_TOKEN_SECRET_KEY
      value: "token"
EOF
```

</details>

<details><summary>DECRYPT SOPS</summary>

Decrypts SOPS-encrypted files from the `input` workspace and writes the
plaintext to the `output` workspace. Decryption keys are provided through the
optional `sops-keys` workspace (an age key file and/or a PGP private key).

Create a secret holding your age key:

```bash
kubectl create secret generic sops-age \
--from-file=keys.txt=$HOME/.config/sops/age/keys.txt \
-n tekton-ci
```

```bash
kubectl apply -f - <<EOF
---
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: decrypt-sops-test
  namespace: tekton-ci
spec:
  taskRef:
    name: decrypt-sops
  params:
    - name: filePattern
      value: "*.sops.yaml"
    # - name: files
    #   value: "secrets/app.sops.yaml secrets/db.sops.yaml"
  workspaces:
    - name: input
      persistentVolumeClaim:
        claimName: encrypted-files-pvc
    - name: output
      emptyDir: {}
    - name: sops-keys
      secret:
        secretName: sops-age
EOF
```

</details>
