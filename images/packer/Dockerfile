# BASE
# Built on sthings-ansible rather than sthings-alpine: the packer templates
# this image builds use the `ansible` provisioner, which shells out to the
# ansible-playbook BINARY (the packer ansible *plugin* is only a shim and does
# not bring ansible with it). Their galaxy requirements pull in
# community.hashi_vault, community.vmware, kubernetes.core and community.docker,
# whose Python deps (hvac, PyVmomi, kubernetes, ...) are exactly the set
# sthings-ansible already installs. Inheriting that stack avoids maintaining a
# second copy of the pip list that would silently drift.
FROM ghcr.io/stuttgart-things/sthings-ansible:14.0.0

# METADATA INFORMATION
# NOTE: this LABEL is metadata only -- it does NOT drive the published tag.
# .github/workflows/docker-build-packer.yaml resolves the tag from
# ARG PACKER_VERSION below, so the image tag tracks the packer BINARY version.
# Keep the two in sync, or the label will name a version that was never
# published (as 1.16.0 did). A consequence worth knowing: an image-content
# change that leaves PACKER_VERSION alone republishes the SAME tag with
# different contents -- consumers pinned to it silently get a new image.
LABEL version=1.15.1
LABEL maintainer="Patrick Hermann <patrick.hermann@sva.de>"

# SOFTWARE
ARG PACKER_VERSION=1.15.1
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

# RUNTIME PACKAGES + packer.
# The base already provides git/curl/wget/tar/bash/ca-certificates/python3 and
# yq, so only the packer-specific additions are installed here.
# unzip: packer releases ship as a zip.
# xorriso: REQUIRED at build time by any template using `cd_files` (the
#   cloud-init user-data/meta-data ISO). packer accepts xorriso/mkisofs/hdiutil/
#   oscdimg; without one the build dies with "could not find a supported CD ISO
#   creation command". Note `packer validate` does NOT catch this.
# openssh-client: templates that provision over SSH or fetch sources.
RUN apk add --no-cache unzip xorriso openssh-client \
    && curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" -o /tmp/packer.zip \
    && unzip /tmp/packer.zip -d /usr/bin \
    && chmod +x /usr/bin/packer \
    && rm -f /tmp/packer.zip

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
