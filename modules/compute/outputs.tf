output "frontend_ip" {
  description = "Private IP of the compute instance"
  value       = aws_instance.web.private_ip
}
