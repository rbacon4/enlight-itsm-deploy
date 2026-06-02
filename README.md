# Enlight ITSM — Deploy Tool

Stand up a production [Enlight ITSM](https://github.com/rbacon4/enlight-itsm)
instance on **Google Cloud, AWS, or DigitalOcean** with a single command.

```bash
git clone https://github.com/rbacon4/enlight-itsm-deploy.git
cd enlight-itsm-deploy
node deploy.mjs
```

Answer a few questions and the tool provisions a VM, installs Docker, builds
Enlight from source, and runs the whole stack (app + PostgreSQL/pgvector +
Redis). When it finishes you get a URL — open it and the in-app setup wizard
creates your organisation and admin account.

```
  ╔═══════════════════════════════════════════╗
  ║        Enlight ITSM — Deploy Tool         ║
  ╚═══════════════════════════════════════════╝

  ─── Step 1/4 · Choose your cloud ───

  Cloud provider
    1) Google Cloud Platform
       Compute Engine VM · ~$13/mo (e2-small)
    2) Amazon Web Services
       EC2 instance · ~$15/mo (t3.small)
    3) DigitalOcean
       Droplet · $12/mo · easiest (just an API token)
  Choose [1-3]:
```

The wizard walks you through four guided steps, with instructions and links at
each one:

1. **Choose your cloud** — GCP, AWS, or DigitalOcean (with a credentials checklist).
2. **AI configuration** — pick the agent's **AI platform** (Anthropic Claude or
   OpenAI GPT) and an embeddings provider for knowledge-base search. Keys are
   optional here and can be added in-app later; your choice becomes the default
   (changeable any time under Settings → AI Keys).
3. **Domain & HTTPS** — supply a domain for automatic HTTPS, or skip for plain HTTP.
4. **Cloud settings** — region, size, and provider-specific options (sensible
   defaults throughout).

All secrets are auto-generated for you.

## What it builds

A single VM running four containers via Docker Compose:

| Container | Image | Purpose |
|---|---|---|
| `caddy` | `caddy:2-alpine` | reverse proxy + **automatic HTTPS** (Let's Encrypt) |
| `app` | built from `enlight-itsm/Dockerfile.prod` | API + BullMQ worker + React SPA |
| `postgres` | `pgvector/pgvector:pg16` | database + knowledge-base vector search |
| `redis` | `redis:7-alpine` | job queue |

Database migrations run automatically on first boot.

**HTTPS is automatic.** If you give the wizard a domain name, Caddy obtains and
renews a TLS certificate for it and serves the app over HTTPS (port 443, with
HTTP redirected). If you don't supply a domain, Caddy serves plain HTTP on
port 80 — and you can add a domain later without redeploying.

This single-VM layout matches Enlight's design goal — a self-hosted product that
runs on one modest instance. Default sizes:

| Cloud | Default size | ~ Monthly |
|---|---|---|
| GCP | `e2-small` (2 vCPU, 2 GB) | ~$13 |
| AWS | `t3.small` (2 vCPU, 2 GB) | ~$15 |
| DigitalOcean | `s-1vcpu-2gb` | $12 |

## Prerequisites

1. **Node.js 18+** (to run the wizard)
2. **[Terraform](https://developer.hashicorp.com/terraform/install)** (the wizard
   uses it to provision). If it's not installed, the wizard still generates all
   config and prints the exact commands to run.
3. **Cloud credentials** for your chosen provider:

   | Cloud | Setup |
   |---|---|
   | **GCP** | `gcloud auth application-default login` + a project ID |
   | **AWS** | `aws configure` (or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars). Needs a default VPC. |
   | **DigitalOcean** | A [personal access token](https://cloud.digitalocean.com/account/api/tokens) — you paste it into the wizard. |

You'll also want an **Anthropic API key** for the AI agent (you can also add it
later in the app under Settings → AI Keys).

## Usage

```bash
node deploy.mjs                  # interactive deploy
node deploy.mjs --generate-only  # write config files but don't provision
node deploy.mjs destroy          # tear down the last deployment
```

The wizard auto-generates all secrets (DB password, JWT/session secrets, the
encryption key) so you never have to.

## After deploying

- The first build on the VM takes **3–5 minutes**. Then open the URL.
- The in-app **setup wizard** creates your first organisation + super admin.
- Configure Slack, AI keys, etc. from **Settings** inside the app.

### HTTPS

**With a domain (recommended):** enter it when the wizard asks. Point an A record
for that domain at the server's public IP (shown after provisioning). Within a
minute or two Caddy issues a Let's Encrypt certificate and the site is live on
`https://your-domain` — no extra steps.

**Added a domain later?** SSH into the VM and edit `/opt/enlight/.env`:

```bash
SITE_ADDRESS=itsm.example.com          # was ":80"
API_URL=https://itsm.example.com
WEB_URL=https://itsm.example.com
```

then `cd /opt/enlight && docker compose up -d`. Caddy picks up the new domain and
secures it automatically.

## How it works

```
node deploy.mjs
   │  asks: cloud + config
   │  generates secrets
   ▼
terraform/<cloud>/.env          ← app configuration
terraform/<cloud>/terraform.tfvars  ← cloud settings
   │
   ▼  terraform apply
provisions ONE VM ──► cloud-init:
                        • installs Docker
                        • clones enlight-itsm-deploy (compose) + enlight-itsm (app)
                        • writes .env
                        • docker compose up -d --build
```

The Terraform for each cloud lives in `terraform/<cloud>/`. The VM startup logic
is `scripts/cloud-init.sh.tpl` (shared across all three clouds).

## Security notes

- The generated `terraform/<cloud>/.env` and `*.tfvars` contain secrets and are
  **git-ignored**. Don't commit them.
- Terraform state (`*.tfstate`) also contains secrets and is git-ignored — keep
  it private (or configure a remote backend).
- The firewall opens ports 22, 80, and 443 only.

## Customising

- **Sizes / regions** — change them in the wizard, or edit
  `terraform/<cloud>/terraform.tfvars`.
- **Forks** — set `deploy_repo` / `app_repo` in the tfvars to point the VM at
  your own forks.
- **Manual Terraform** — everything the wizard does, you can do by hand:
  ```bash
  cd terraform/gcp   # or aws / digitalocean
  # create .env (see .env.example) and terraform.tfvars
  terraform init && terraform apply
  ```
