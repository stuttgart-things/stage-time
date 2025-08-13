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
