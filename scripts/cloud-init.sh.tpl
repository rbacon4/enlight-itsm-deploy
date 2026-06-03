#!/bin/bash
# Cloud-init / startup script — installs Docker, clones Enlight, and brings the
# stack up. Rendered by Terraform (templatefile) with the values below injected.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# ── Swap ─────────────────────────────────────────────────────────────────────
# Building the app from source (TypeScript + Vite) can exceed 2 GB of RAM. Add a
# 2 GB swapfile so small instances (e.g. e2-small / t3.small / s-1vcpu-2gb) don't
# get OOM-killed mid-build, which would leave the web stack down.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# ── Install Docker Engine + Compose plugin + git ─────────────────────────────
apt-get update
apt-get install -y ca-certificates curl git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker

# ── Fetch the deploy bundle (docker-compose.yml) + the app source ────────────
mkdir -p /opt/enlight
cd /opt/enlight
git clone "${deploy_repo}" . || git pull
git clone "${app_repo}" enlight-itsm || (cd enlight-itsm && git pull)

# ── Write configuration ──────────────────────────────────────────────────────
cat > /opt/enlight/.env <<'ENLIGHT_ENV_EOF'
${env_content}
ENLIGHT_ENV_EOF

# ── Build + launch ───────────────────────────────────────────────────────────
# Pass --env-file explicitly so Compose interpolation (e.g. POSTGRES_PASSWORD)
# always resolves, regardless of the working directory it's invoked from.
cd /opt/enlight
docker compose --env-file /opt/enlight/.env up -d --build

echo "Enlight ITSM is starting. First build can take several minutes."
