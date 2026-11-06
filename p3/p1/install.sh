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
    gnupg \
    dkms \
    linux-headers-"$(uname -r)"

curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | \
    sudo gpg --dearmor --yes -o /usr/share/keyrings/oracle-virtualbox.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian bookworm contrib" | \
    sudo tee /etc/apt/sources.list.d/virtualbox.list

curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com bookworm main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y --no-install-recommends virtualbox-7.0
sudo apt-get install -y vagrant

sudo usermod -aG vboxusers "$USER"
sudo /sbin/vboxconfig || true
sudo modprobe -r kvm_intel 2>/dev/null || true
sudo modprobe -r kvm_amd 2>/dev/null || true
sudo modprobe -r kvm 2>/dev/null || true
