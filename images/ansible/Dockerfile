# BASE
FROM ghcr.io/stuttgart-things/sthings-alpine:3.13-alpine

# METADATA INFORMATION
LABEL version=12.0.0
LABEL maintainer="Patrick Hermann <patrick.hermann@sva.de>"

# SOFTWARE
ARG YQ_VERSION=4.47.2
ARG ANSIBLE_VERSION=12.0.0
ARG ANSIBLE_LINT_VERSION=25.9.1
ARG MACHINE_SHOP_VERSION=2.6.10

# NON-ROOT USER ID AND GROUP ID
ENV USER_ID=65532
ENV GROUP_ID=65532
ENV PATH="/root/.cargo/bin:${PATH}"

# INSTALL RUST
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y

# INSTALL NECESSARY PACKAGES
RUN apk add --no-cache \
        git \
        curl \
        wget \
        tar \
        python3 \
        py3-pip \
        bash \
        py3-virtualenv \
        gcc \
        musl-dev \
        libffi-dev \
        openssl-dev

# SET THE PATH FOR PIPX-INSTALLED BINARIES
ENV PATH=/root/.local/bin:$PATH

# INSTALL YQ
RUN wget -q "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64.tar.gz" \
    && tar -xzf yq_linux_amd64.tar.gz -C /usr/bin \
    && mv /usr/bin/yq_linux_amd64 /usr/bin/yq \
    && chmod +x /usr/bin/yq \
    && rm -f yq_linux_amd64.tar.gz

# INSTALL MACHINESHOP
RUN wget -q "https://github.com/stuttgart-things/machineshop/releases/download/v${MACHINE_SHOP_VERSION}/machineshop_Linux_x86_64.tar.gz" \
    && tar -xzf machineshop_Linux_x86_64.tar.gz -C /usr/bin machineshop \
    && chmod +x /usr/bin/machineshop \
    && rm -f machineshop_Linux_x86_64.tar.gz

# GET RUST; NOTE: USING SH FOR BETTER COMPATIBILITY WITH OTHER BASE IMAGES
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN /usr/local/bin/python -m pip install --upgrade pip && pip install pip --upgrade
RUN pip install --no-cache-dir cryptography hvac "hvac[parser]" paramiko jmespath openshift kubernetes boto3 passlib kubernetes-validate==1.27.0 proxmoxer netaddr setuptools requests pyVim PyVmomi python.dateutil dnspython pycrypto pywinrm pytz ansible==${ANSIBLE_VERSION} ansible-lint==${ANSIBLE_LINT_VERSION}
RUN mkdir -p /home/nonroot/.ansible && chown -R ${USER_ID}:${GROUP_ID} /home/nonroot/.ansible

# ANSIBLE REQUIREMENTS
USER 65532
WORKDIR /home/nonroot/.ansible
RUN wget --progress=dot:giga https://raw.githubusercontent.com/stuttgart-things/ansible/refs/heads/main/requirements.yaml \
    && ansible-galaxy install -r requirements.yaml --force

USER root

# DEFAULT ENTRYPOINT AND/OR COMMAND (IF REQUIRED, CAN BE ADDED HERE)
CMD ["bash"]
