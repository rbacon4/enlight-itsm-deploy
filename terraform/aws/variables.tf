variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.small"
}

variable "disk_size_gb" {
  description = "Root volume size in GB."
  type        = number
  default     = 30
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH access. Leave blank to skip."
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Name tag for the instance and security group."
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
