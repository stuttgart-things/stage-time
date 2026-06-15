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

<details><summary>EXECUTE OPENTOFU</summary>

Runs `tofu init` followed by a `plan`, `apply` or `destroy` against the
configuration in the `source` workspace. Per-key variables (`TF_VARS`) and a
base64 tfvars file (`TF_VARS_FILE`) are written as `*.auto.tfvars`. Provider
credentials are injected from an optional secret (`credentials-secret-name`)
whose keys become environment variables (e.g. `AWS_ACCESS_KEY_ID`,
`ARM_CLIENT_ID`, `GOOGLE_CREDENTIALS`, `TF_VAR_*`).

Private CA certificates can be trusted per run (not baked into the image) by
binding the optional `ca-certs` workspace; any `*.crt` / `*.pem` files there
are appended to the system trust store via `SSL_CERT_FILE`.

Optionally create a credentials secret and a CA cert secret:

```bash
kubectl create secret generic terraform-credentials \
--from-literal=AWS_ACCESS_KEY_ID=<KEY> \
--from-literal=AWS_SECRET_ACCESS_KEY=<SECRET> \
-n tekton-ci

kubectl create secret generic private-ca \
--from-file=ca.crt=./my-private-ca.crt \
-n tekton-ci
```

```bash
kubectl apply -f - <<EOF
---
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: execute-tofu-test
  namespace: tekton-ci
spec:
  taskRef:
    name: execute-tofu
  params:
    - name: ACTION
      value: "apply"
    - name: AUTO_APPROVE
      value: "true"
    - name: SUB_DIRECTORY
      value: "terraform"
    - name: TF_VARS
      value:
        - "region+-'eu-central-1'"
        - "instance_count+-2"
    - name: BACKEND_CONFIG
      value:
        - "bucket+-my-tf-state"
        - "key+-stage-time/terraform.tfstate"
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: terraform-source-pvc
    - name: ca-certs       # optional - private CA trust, per run
      secret:
        secretName: private-ca
EOF
```

</details>
