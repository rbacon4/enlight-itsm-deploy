#!/bin/bash
# Cloud-init / startup script — installs Docker, fetches Enlight, and brings the
# stack up. Rendered by Terraform (templatefile) with the values below injected.
#
# Note: we deliberately do NOT use `set -e`. Transient failures (e.g. a flaky git
# clone on first boot) must not abort the script before the .env is written and
# the stack is started — the critical steps below retry and verify explicitly.
set -uxo pipefail
export DEBIAN_FRONTEND=noninteractive

retry() {  # retry <attempts> <cmd...>
  local n=$1; shift
  local i
  for i in $(seq 1 "$n"); do
    "$@" && return 0
    echo "attempt $i/$n failed: $* — retrying in 10s" >&2
    sleep 10
  done
  return 1
}

# ── Swap ─────────────────────────────────────────────────────────────────────
# Building the app from source (TypeScript + Vite) can exceed 2 GB of RAM. Add a
# 2 GB swapfile so small instances (e2-small / t3.small / s-1vcpu-2gb) don't get
# OOM-killed mid-build, which would leave the web stack down.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# ── Install Docker Engine + Compose plugin + git ─────────────────────────────
retry 5 apt-get update
apt-get install -y ca-certificates curl git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
retry 5 apt-get update
retry 5 apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker

# ── Write configuration FIRST (so it always exists, even if a clone retries) ──
mkdir -p /opt/enlight
cat > /opt/enlight/.env <<'ENLIGHT_ENV_EOF'
${env_content}
ENLIGHT_ENV_EOF

# ── Fetch the deploy bundle (compose + Caddyfile) and the app source ──────────
clone() {  # clone <repo> <dest>
  rm -rf "$2"
  git clone --depth 1 "$1" "$2"
}

retry 5 clone "${deploy_repo}" /opt/enlight/_bundle
cp /opt/enlight/_bundle/docker-compose.yml /opt/enlight/docker-compose.yml
cp /opt/enlight/_bundle/Caddyfile          /opt/enlight/Caddyfile

retry 5 clone "${app_repo}" /opt/enlight/enlight-itsm

# ── Build + launch ───────────────────────────────────────────────────────────
# Pass --env-file explicitly so Compose interpolation (e.g. POSTGRES_PASSWORD)
# always resolves, regardless of the working directory it's invoked from.
cd /opt/enlight
retry 3 docker compose --env-file /opt/enlight/.env up -d --build

echo "Enlight ITSM is starting. First build can take several minutes."
