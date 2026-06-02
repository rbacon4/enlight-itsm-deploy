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

  Where would you like to deploy?
    1) Google Cloud Platform (Compute Engine)
    2) Amazon Web Services (EC2)
    3) DigitalOcean (Droplet)
  Choose [1-3]:
```

## What it builds

A single VM running three containers via Docker Compose:

| Container | Image | Purpose |
|---|---|---|
| `app` | built from `enlight-itsm/Dockerfile.prod` | API + BullMQ worker + React SPA |
| `postgres` | `pgvector/pgvector:pg16` | database + knowledge-base vector search |
| `redis` | `redis:7-alpine` | job queue |

Database migrations run automatically on first boot. The app is served on
**port 80**.

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

### Adding a domain + HTTPS

The instance serves plain HTTP on port 80. To add HTTPS:

1. Point an A record at the server's public IP.
2. SSH in, set `WEB_URL` / `API_URL` in `/opt/enlight/.env` to `https://your-domain`.
3. Put a TLS-terminating reverse proxy in front (Caddy is easiest — it gets
   certificates automatically), or front the VM with your cloud's load balancer.

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
