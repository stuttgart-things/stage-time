#!/usr/bin/env bash
# Offline test for the promote path of tasks/execute-govc.yaml.
#
# Runs the task's real step script (extracted with yq) against a fake vCenter:
# a directory tree where folders are directories and VMs/templates are files,
# served by a stub `govc` that mimics the subcommands the script uses -- in
# particular that `govc ls <folder>` lists the folder's CHILDREN (so an empty
# folder prints nothing) while `govc object.collect -s <path> name` resolves
# the object itself (#102). Vault is stubbed with a fake `curl`.
#
# usage: tests/execute-govc/test-promote.sh [path/to/execute-govc.yaml]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TASK_FILE="${1:-${ROOT}/tasks/execute-govc.yaml}"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

# --- the step script, with Tekton substitutions resolved -------------------
mkdir -p "${WORK}/results"
yq '.spec.steps[0].script' "${TASK_FILE}" \
  | sed -e "s#\$(results\.\([a-z-]*\)\.path)#${WORK}/results/\1#g" \
        -e "s#\\\$(params\.vault-secret-name)#vault#g" \
  > "${WORK}/step.sh"

# --- stubs -----------------------------------------------------------------
mkdir -p "${WORK}/bin"
cat > "${WORK}/bin/curl" <<'STUB'
#!/usr/bin/env bash
# fake Vault KV v2 read: write the secret to the -o file, print HTTP 200
out=""
while [ $# -gt 0 ]; do [ "$1" = "-o" ] && { out="$2"; shift; }; shift; done
printf '{"data":{"data":{"username":"u","password":"p","ip":"vcenter.test"}}}' > "${out}"
printf '200'
STUB
cat > "${WORK}/bin/govc" <<'STUB'
#!/usr/bin/env bash
# fake govc over the directory tree at $FAKE_INVENTORY
set -u
inv() { printf '%s%s' "${FAKE_INVENTORY}" "${1%/}"; }
cmd="$1"; shift
case "${cmd}" in
  ls)
    p="$(inv "$1")"
    if [ -d "${p}" ]; then
      for c in "${p}"/*; do [ -e "${c}" ] && printf '%s\n' "${c#"${FAKE_INVENTORY}"}"; done
    elif [ -e "${p}" ]; then
      printf '%s\n' "${1%/}"
    fi
    exit 0 ;;
  object.collect)
    [ "$1" = "-s" ] && shift
    p="$(inv "$1")"
    [ -e "${p}" ] || { echo "govc: $1 not found" >&2; exit 1; }
    basename "${p}" ;;
  object.rename)
    p="$(inv "$1")"; [ -e "${p}" ] || { echo "govc: $1 not found" >&2; exit 1; }
    mv "${p}" "$(dirname "${p}")/$2" ;;
  object.mv)
    p="$(inv "$1")"; d="$(inv "$2")"
    [ -e "${p}" ] && [ -d "${d}" ] || { echo "govc: not found" >&2; exit 1; }
    mv "${p}" "${d}/" ;;
  object.destroy)
    p="$(inv "$1")"; [ -e "${p}" ] || { echo "govc: $1 not found" >&2; exit 1; }
    rm -rf "${p}" ;;
  *) echo "fake govc: unsupported ${cmd}" >&2; exit 2 ;;
esac
STUB
chmod +x "${WORK}/bin/curl" "${WORK}/bin/govc"

# --- harness -----------------------------------------------------------------
DC=/DC/vm/stuttgart-things
FAIL=0

setup() { # setup <entry>... : folders end in /, everything else is a VM file
  rm -rf "${WORK}/inv" "${WORK}/results"; mkdir -p "${WORK}/inv" "${WORK}/results"
  local e
  for e in "$@"; do
    case "${e}" in
      */) mkdir -p "${WORK}/inv${e}" ;;
      *) mkdir -p "$(dirname "${WORK}/inv${e}")"; touch "${WORK}/inv${e}" ;;
    esac
  done
}

run_promote() {
  env -i PATH="${WORK}/bin:/usr/bin:/bin" HOME="${WORK}" \
    FAKE_INVENTORY="${WORK}/inv" SSL_CERT_FILE="${WORK}/ca.crt" \
    ACTION=promote TEMPLATE_NAME=build-1 GOLDEN_NAME=gold \
    BUILD_FOLDER="${DC}/packer" GOLDEN_FOLDER="${DC}/vm-templates" \
    PREVIOUS_SUFFIX=-previous GOVC_INSECURE=true CA_CERTS_BOUND=false \
    SOURCE= TARGET= GOVC_DATACENTER= CA_CERTS_PATH= \
    VAULT_ADDR=https://vault.test VAULT_TOKEN=t VAULT_SECRET_PATH=cloud/data/vsphere \
    VAULT_KEY_USERNAME=username VAULT_KEY_PASSWORD=password VAULT_KEY_SERVER=ip \
    bash "${WORK}/step.sh" > "${WORK}/out.log" 2>&1
}

has()    { [ -e "${WORK}/inv$1" ]; }
lacks()  { ! has "$1"; }
result() { cat "${WORK}/results/$1" 2>/dev/null || true; }
check()  { # check <case> <description> <condition...>
  local name="$1" what="$2"; shift 2
  if "$@"; then echo "ok   ${name}: ${what}"
  else echo "FAIL ${name}: ${what}"; sed 's/^/     | /' "${WORK}/out.log"; FAIL=1; fi
}
succeeds() { run_promote; }
fails()    { ! run_promote; }
log_has()  { grep -q -- "$1" "${WORK}/out.log"; }

# --- cases -------------------------------------------------------------------
c="golden folder empty"
setup "${DC}/packer/build-1" "${DC}/vm-templates/"
check "${c}" "promote succeeds" succeeds
check "${c}" "golden image in place" has "${DC}/vm-templates/gold"
check "${c}" "build template gone from build folder" lacks "${DC}/packer/build-1"
check "${c}" "promoted-template result" test "$(result promoted-template)" = "${DC}/vm-templates/gold"
check "${c}" "previous-template result empty" test -z "$(result previous-template)"

c="golden exists, no previous"
setup "${DC}/packer/build-1" "${DC}/vm-templates/gold"
check "${c}" "promote succeeds" succeeds
check "${c}" "new golden in place" has "${DC}/vm-templates/gold"
check "${c}" "old golden demoted" has "${DC}/vm-templates/gold-previous"
check "${c}" "previous-template result" test "$(result previous-template)" = "${DC}/vm-templates/gold-previous"

c="golden and previous exist"
setup "${DC}/packer/build-1" "${DC}/vm-templates/gold" "${DC}/vm-templates/gold-previous"
echo old-gold > "${WORK}/inv${DC}/vm-templates/gold"
check "${c}" "promote succeeds" succeeds
check "${c}" "old golden is the new previous" grep -q old-gold "${WORK}/inv${DC}/vm-templates/gold-previous"
check "${c}" "new golden in place" has "${DC}/vm-templates/gold"

c="half-swapped (previous only)"
setup "${DC}/packer/build-1" "${DC}/vm-templates/gold-previous"
check "${c}" "promote refuses" fails
check "${c}" "explains the half-swap" log_has "half-swapped"
check "${c}" "previous untouched" has "${DC}/vm-templates/gold-previous"
check "${c}" "build template untouched" has "${DC}/packer/build-1"

c="golden folder missing"
setup "${DC}/packer/build-1"
check "${c}" "promote refuses" fails
check "${c}" "names the folder" log_has "not found in vCenter: ${DC}/vm-templates"
check "${c}" "build template untouched" has "${DC}/packer/build-1"

c="source template missing"
setup "${DC}/packer/" "${DC}/vm-templates/gold"
check "${c}" "promote refuses" fails
check "${c}" "names the template" log_has "not found in vCenter: ${DC}/packer/build-1"
check "${c}" "golden untouched" has "${DC}/vm-templates/gold"

if [ "${FAIL}" -ne 0 ]; then echo "execute-govc promote tests FAILED"; exit 1; fi
echo "all execute-govc promote cases passed"
