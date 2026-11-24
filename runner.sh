#!/usr/bin/env bash
# Registers a self-hosted GitHub Actions runner as a service. Run as root.
set -euo pipefail

URL="${1:?usage: runner.sh <repo-or-org-url> <registration-token> [labels]}"
TOKEN="${2:?usage: runner.sh <repo-or-org-url> <registration-token> [labels]}"
LABELS="${3:-talos}"
HOME_DIR=/opt/actions-runner

case "$(dpkg --print-architecture)" in
    amd64) arch=x64 ;;
    arm64) arch=arm64 ;;
    *) echo "Unsupported architecture" >&2; exit 1 ;;
esac

id runner >/dev/null 2>&1 || useradd -m -s /bin/bash runner
mkdir -p "$HOME_DIR"
version="$(curl -fsS https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | tr -d v)"
curl -fsSL "https://github.com/actions/runner/releases/download/v$version/actions-runner-linux-$arch-$version.tar.gz" \
    | tar -xz -C "$HOME_DIR"
"$HOME_DIR/bin/installdependencies.sh"
chown -R runner: "$HOME_DIR"

sudo -u runner "$HOME_DIR/config.sh" --url "$URL" --token "$TOKEN" --labels "$LABELS" --name "$(hostname)" --unattended --replace
cd "$HOME_DIR"
./svc.sh install runner
./svc.sh start
