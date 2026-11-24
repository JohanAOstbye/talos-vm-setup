#!/usr/bin/env bash
# Writes Entra signing keys to /etc/haproxy/jwks/<kid>.pem and reloads HAProxy on change.
set -euo pipefail

dir=/etc/haproxy/jwks
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsS "https://login.microsoftonline.com/<tenant-id>/discovery/v2.0/keys" \
    | jq -r '.keys[] | "\(.kid) \(.x5c[0])"' \
    | while read -r kid x5c; do
        [[ $kid =~ ^[A-Za-z0-9_-]+$ ]] || continue
        printf -- '-----BEGIN CERTIFICATE-----\n%s\n-----END CERTIFICATE-----\n' "$(fold -w64 <<<"$x5c")" > "$tmp/$kid.pem"
    done

ls "$tmp"/*.pem >/dev/null # fail rather than wipe keys if none came back
chmod 644 "$tmp"/*.pem
diff -qr "$tmp" "$dir" >/dev/null 2>&1 && exit 0
rm -f "$dir"/*.pem
cp "$tmp"/*.pem "$dir"/
systemctl reload haproxy
