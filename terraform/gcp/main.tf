terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  startup_script = templatefile("${path.module}/../../scripts/cloud-init.sh.tpl", {
    env_content = file("${path.module}/.env")
    deploy_repo = var.deploy_repo
    app_repo    = var.app_repo
  })
}

resource "google_compute_instance" "enlight" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network = "default"
    access_config {} # ephemeral external IP
  }

  metadata = {
    startup-script = local.startup_script
  }

  tags = ["enlight-itsm"]
}

resource "google_compute_firewall" "enlight" {
  name    = "${var.instance_name}-allow"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["enlight-itsm"]
}
