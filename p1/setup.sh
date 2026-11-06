#!/usr/bin/env bash
set -euo pipefail

sudo rm -f /etc/apt/sources.list.d/virtualbox.list*
sudo rm -f /etc/apt/sources.list.d/hashicorp.list*
sudo rm -f /etc/apt/sources.list.d/debian-bookworm-compat.list*

echo "deb http://deb.debian.org/debian bookworm main" | \
    sudo tee /etc/apt/sources.list.d/debian-bookworm-compat.list

sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg

curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com bookworm main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y \
    vagrant \
    qemu-system-x86 \
    libvirt-daemon-system \
    libvirt-dev \
    dnsmasq-base \
    ebtables \
    build-essential \
    pkg-config \
    ruby-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev

sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"

vagrant plugin install vagrant-libvirt

grep -q VAGRANT_DEFAULT_PROVIDER ~/.bashrc || \
    echo 'export VAGRANT_DEFAULT_PROVIDER=libvirt' >> ~/.bashrc

[ -e /dev/kvm ] || echo "ATTENTION : /dev/kvm absent, mettre lv.driver = \"qemu\" dans le Vagrantfile"
