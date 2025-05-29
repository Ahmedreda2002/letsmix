/* ---------- Outputs ---------- */
output "frontend_ip" {
  description = "Carrier-grade IP of the WLZ front-end instance"
  value       = aws_instance.frontend.private_ip
}