variable "project_id" {
  description = "GCP project ID to deploy into."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone."
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-small"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 30
}

variable "instance_name" {
  description = "Name for the VM and firewall rule."
  type        = string
  default     = "enlight-itsm"
}

variable "deploy_repo" {
  description = "Git URL of this deploy repo (provides docker-compose.yml)."
  type        = string
  default     = "https://github.com/rbacon4/enlight-itsm-deploy.git"
}

variable "app_repo" {
  description = "Git URL of the Enlight ITSM application repo (built on the VM)."
  type        = string
  default     = "https://github.com/rbacon4/enlight-itsm.git"
}
