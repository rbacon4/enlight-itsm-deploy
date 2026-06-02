variable "do_token" {
  description = "DigitalOcean API token."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region slug."
  type        = string
  default     = "nyc1"
}

variable "droplet_size" {
  description = "Droplet size slug."
  type        = string
  default     = "s-1vcpu-2gb"
}

variable "ssh_key_fingerprints" {
  description = "Optional list of SSH key fingerprints (from your DO account) for SSH access."
  type        = list(string)
  default     = []
}

variable "instance_name" {
  description = "Droplet + firewall name."
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
