output "public_ip" {
  description = "Public IP of the Enlight instance."
  value       = aws_instance.enlight.public_ip
}

output "url" {
  description = "URL to open once the first build finishes (a few minutes)."
  value       = "http://${aws_instance.enlight.public_ip}"
}

output "ssh" {
  description = "SSH command (requires the key pair you specified)."
  value       = var.key_name != "" ? "ssh ubuntu@${aws_instance.enlight.public_ip}" : "Set key_name to enable SSH."
}
