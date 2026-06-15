# BASE
FROM ghcr.io/stuttgart-things/sthings-alpine:3.11.14-alpine3.23

# METADATA INFORMATION
LABEL version=14.0.0
LABEL maintainer="Patrick Hermann <patrick.hermann@sva.de>"

# SOFTWARE
ARG YQ_VERSION=4.53.2
ARG ANSIBLE_VERSION=14.0.0
ARG ANSIBLE_LINT_VERSION=26.4.0

# NON-ROOT USER ID AND GROUP ID + PIP HYGIENE
ENV USER_ID=65532 \
    GROUP_ID=65532 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_ROOT_USER_ACTION=ignore

# RUNTIME PACKAGES (kept in the final image) + YQ.
# libffi/openssl are the runtime shared libs for cryptography/paramiko; the
# *-dev headers and compilers are build-only and live in the .build-deps layer.
RUN apk add --no-cache git curl wget tar bash python3 py3-pip py3-virtualenv libffi openssl \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" -o /usr/bin/yq \
    && chmod +x /usr/bin/yq

# PYTHON DEPS + ANSIBLE.
# The whole build toolchain (gcc/musl-dev/*-dev + the Rust used to compile the
# cryptography native extension) is installed, used, and torn down in a SINGLE
# layer, so none of it — nor the pip/cargo/rustup caches — ships in the final
# image. This is the main size win over the previous version, which left the
# compilers and ~/.cargo + ~/.rustup behind.
RUN apk add --no-cache --virtual .build-deps gcc musl-dev libffi-dev openssl-dev \
    && curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
    && . "$HOME/.cargo/env" \
    && /usr/local/bin/python -m pip install --upgrade pip \
    && pip install \
        cryptography hvac "hvac[parser]" paramiko jmespath openshift kubernetes \
        boto3 passlib kubernetes-validate==1.27.0 proxmoxer netaddr setuptools \
        requests pyVim PyVmomi python-dateutil dnspython pycryptodome pywinrm pytz \
        ansible==${ANSIBLE_VERSION} ansible-lint==${ANSIBLE_LINT_VERSION} \
    && apk del .build-deps \
    && rm -rf /root/.rustup /root/.cargo /root/.cache /tmp/*

# ANSIBLE COLLECTIONS — baked from stuttgart-things/ansible `main` requirements
# at build time into /home/nonroot/.ansible/collections (the path the runner
# resolves at run time). NOTE: this fetches REMOTE main, so push requirement
# changes before building. The build cache busts when main's requirements move.
RUN mkdir -p /home/nonroot/.ansible && chown -R ${USER_ID}:${GROUP_ID} /home/nonroot/.ansible
USER 65532
WORKDIR /home/nonroot/.ansible
RUN curl -fsSL https://raw.githubusercontent.com/stuttgart-things/ansible/refs/heads/main/requirements.yaml -o requirements.yaml \
    && ansible-galaxy install -r requirements.yaml --force \
    && rm -rf /home/nonroot/.ansible/tmp

USER root

# DEFAULT ENTRYPOINT AND/OR COMMAND (IF REQUIRED, CAN BE ADDED HERE)
CMD ["bash"]
