#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates gnupg git

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm -f get-docker.sh
fi

sudo usermod -aG docker "$USER"
sudo chmod 666 /var/run/docker.sock

if ! command -v kubectl &> /dev/null; then
    ARCH=$(dpkg --print-architecture)
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
fi

if ! command -v k3d &> /dev/null; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

