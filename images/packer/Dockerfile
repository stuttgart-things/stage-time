# BASE
FROM ghcr.io/stuttgart-things/sthings-alpine:3.11.14-alpine3.23

# METADATA INFORMATION
LABEL version=1.12.0
LABEL maintainer="Patrick Hermann <patrick.hermann@sva.de>"

# SOFTWARE
ARG PACKER_VERSION=1.12.0
ARG YQ_VERSION=4.53.2
# Plugin versions baked into the image. They must satisfy the
# `required_plugins` constraints in the templates this image builds; if a
# template pins a newer plugin, `packer init` pulls it at run time (needs
# network). Bump these alongside the templates to keep runs offline-fast.
ARG PACKER_PLUGIN_VSPHERE_VERSION=1.4.2
ARG PACKER_PLUGIN_PROXMOX_VERSION=1.2.2
ARG PACKER_PLUGIN_QEMU_VERSION=1.1.0

# NON-ROOT USER ID AND GROUP ID
ENV USER_ID=65532 \
    GROUP_ID=65532

# RUNTIME PACKAGES (kept in the final image) + packer + yq.
# openssh-client/git: templates that provision over SSH or fetch sources.
# unzip: packer releases ship as a zip. ca-certificates: TLS to builders.
RUN apk add --no-cache git curl wget tar bash unzip ca-certificates openssh-client \
    && curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" -o /tmp/packer.zip \
    && unzip /tmp/packer.zip -d /usr/bin \
    && chmod +x /usr/bin/packer \
    && rm -f /tmp/packer.zip \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" -o /usr/bin/yq \
    && chmod +x /usr/bin/yq

# PACKER PLUGINS — baked into the nonroot user's plugin dir so `packer init`
# resolves them offline and runs don't re-download on every PipelineRun.
# PACKER_PLUGIN_PATH is exported so the runtime user (65532) finds them
# regardless of HOME.
ENV PACKER_PLUGIN_PATH=/home/nonroot/.config/packer/plugins
RUN mkdir -p ${PACKER_PLUGIN_PATH} \
    && chown -R ${USER_ID}:${GROUP_ID} /home/nonroot/.config
USER 65532
WORKDIR /home/nonroot
RUN packer plugins install github.com/hashicorp/vsphere "${PACKER_PLUGIN_VSPHERE_VERSION}" \
    && packer plugins install github.com/hashicorp/proxmox "${PACKER_PLUGIN_PROXMOX_VERSION}" \
    && packer plugins install github.com/hashicorp/qemu "${PACKER_PLUGIN_QEMU_VERSION}"

USER root

# DEFAULT ENTRYPOINT AND/OR COMMAND (IF REQUIRED, CAN BE ADDED HERE)
CMD ["bash"]
