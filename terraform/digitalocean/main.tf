terraform {
  required_version = ">= 1.3.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

locals {
  user_data = templatefile("${path.module}/../../scripts/cloud-init.sh.tpl", {
    env_content = file("${path.module}/.env")
    deploy_repo = var.deploy_repo
    app_repo    = var.app_repo
  })
}

resource "digitalocean_droplet" "enlight" {
  name      = var.instance_name
  image     = "ubuntu-22-04-x64"
  size      = var.droplet_size
  region    = var.region
  user_data = local.user_data
  ssh_keys  = var.ssh_key_fingerprints
}

resource "digitalocean_firewall" "enlight" {
  name        = "${var.instance_name}-fw"
  droplet_ids = [digitalocean_droplet.enlight.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
