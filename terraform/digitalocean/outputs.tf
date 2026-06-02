output "public_ip" {
  description = "Public IP of the Enlight droplet."
  value       = digitalocean_droplet.enlight.ipv4_address
}

output "url" {
  description = "URL to open once the first build finishes (a few minutes)."
  value       = "http://${digitalocean_droplet.enlight.ipv4_address}"
}

output "ssh" {
  description = "SSH command (requires an SSH key on the droplet)."
  value       = length(var.ssh_key_fingerprints) > 0 ? "ssh root@${digitalocean_droplet.enlight.ipv4_address}" : "Add ssh_key_fingerprints to enable SSH."
}
