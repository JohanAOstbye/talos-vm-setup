#!/usr/bin/env bash
# Installs Talos runner tools and HAProxy on Ubuntu. Run as root.
set -euo pipefail

TENANT_ID="${1:?usage: setup.sh <entra-tenant-id>}"
TALOS_VERSION="${TALOS_VERSION:-latest}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH="$(dpkg --print-architecture)"

gh_asset() { # repo version asset
    [[ $2 == latest ]] && echo "https://github.com/$1/releases/latest/download/$3" \
                       || echo "https://github.com/$1/releases/download/$2/$3"
}

apt-get update
apt-get install -y git jq curl gh haproxy ca-certificates gnupg

# shortcut: Microsoft has no repo for 26.04 yet, noble packages are used; switch when one exists
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg --yes
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" \
    > /etc/apt/sources.list.d/azure-cli.list
apt-get update && apt-get install -y azure-cli

curl -fsSLo /usr/local/bin/talosctl "$(gh_asset siderolabs/talos "$TALOS_VERSION" "talosctl-linux-$ARCH")"
curl -fsSLo /usr/local/bin/yq "$(gh_asset mikefarah/yq latest "yq_linux_$ARCH")"
curl -fsSL "$(gh_asset budimanjojo/talhelper latest "talhelper_linux_$ARCH.tar.gz")" | tar -xz -C /usr/local/bin talhelper
chmod +x /usr/local/bin/{talosctl,yq,talhelper}

mkdir -p /etc/haproxy/{certs,ca,jwks}
sed "s/<tenant-id>/$TENANT_ID/" "$DIR/haproxy-jwks.sh" > /usr/local/bin/haproxy-jwks.sh
chmod +x /usr/local/bin/haproxy-jwks.sh
echo '0 * * * * root /usr/local/bin/haproxy-jwks.sh' > /etc/cron.d/haproxy-jwks
/usr/local/bin/haproxy-jwks.sh || true # haproxy has no config yet, reload may fail

talosctl version --client --short
talhelper --version
yq --version
az version -o tsv --query '"azure-cli"'
haproxy -v | head -1
