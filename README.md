# talos-vm-setup

Sets up an Ubuntu VM as a self-hosted GitHub Actions runner for Talos (az, talosctl, talhelper, yq, gh) and as an HAProxy in front of the Talos kube APIs.

```bash
git clone https://github.com/JohanAOstbye/talos-vm-setup.git && cd talos-vm-setup
sudo TALOS_VERSION=v1.11.0 ./setup.sh <entra-tenant-id>   # TALOS_VERSION defaults to latest
sudo ./runner.sh https://github.com/<org>/<repo> <registration-token> talos
```

The registration token is under the repo's Settings → Actions → Runners → New self-hosted runner.

HAProxy then needs `haproxy.cfg`, `aud.map` and `backends.map` in `/etc/haproxy/`, the TLS cert in `certs/` and each cluster's CA in `ca/<cluster>.crt`. Validate with `haproxy -c -f /etc/haproxy/haproxy.cfg` and start with `systemctl enable --now haproxy`. Entra signing keys are refreshed hourly into `/etc/haproxy/jwks/`.
