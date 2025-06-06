################################
# 5. Outputs
################################
output "frontend_public_ip" {
  description = "The public Elastic IP attached to the WLZ EC2 instance"
  value       = aws_eip.web_eip.public_ip
}

output "frontend_sg_id" {
  description = "ID of the security group that allows HTTP/SSH"
  value       = aws_security_group.frontend_sg.id
}