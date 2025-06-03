output "frontend_private_ip" {
  description = "Private IP of the compute instance"
  value       = aws_instance.web.private_ip
}

output "frontend_public_ip" {
  description = "Public IPv4 of the compute instance"
  value       = aws_instance.web.public_ip
}
