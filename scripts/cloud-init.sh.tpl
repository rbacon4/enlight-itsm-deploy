#!/bin/bash
# Cloud-init / startup script — installs Docker, clones Enlight, and brings the
# stack up. Rendered by Terraform (templatefile) with the values below injected.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

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
cd /opt/enlight
docker compose up -d --build

echo "Enlight ITSM is starting. First build can take several minutes."
