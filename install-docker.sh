#!/bin/bash

set -euxo pipefail

if [ ${EUID} != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

dnf remove -y docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine

dnf install -y dnf-plugins-core grubby

dnf config-manager \
  --add-repo \
  https://download.docker.com/linux/fedora/docker-ce.repo

dnf install -y docker-ce docker-ce-cli containerd.io
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"
systemctl enable docker
systemctl start docker


curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /bin/docker-compose
chmod +x /bin/docker-compose

