output "public_ip" {
  description = "Public IP of the Enlight VM."
  value       = google_compute_instance.enlight.network_interface[0].access_config[0].nat_ip
}

output "url" {
  description = "URL to open once the first build finishes (a few minutes)."
  value       = "http://${google_compute_instance.enlight.network_interface[0].access_config[0].nat_ip}"
}

output "ssh" {
  description = "SSH command (uses your gcloud-configured key)."
  value       = "gcloud compute ssh ${google_compute_instance.enlight.name} --zone ${var.zone}"
}
