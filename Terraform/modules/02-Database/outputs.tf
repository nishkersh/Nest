output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance."
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_proxy_endpoint" {
  description = "The connection endpoint for the RDS Proxy. Applications should use this endpoint."
  value       = var.enable_rds_proxy ? aws_db_proxy.main[0].endpoint : null
  sensitive   = true
}

output "db_instance_port" {
  description = "The port on which the RDS instance is listening."
  value       = aws_db_instance.main.port
}

output "db_security_group_id" {
  description = "The ID of the security group for the RDS instance."
  value       = aws_security_group.db.id
}

output "db_name" {
  description = "The name of the database."
  value       = aws_db_instance.main.db_name
}

output "db_master_user_secret_arn" {
  description = "The ARN of the secret in Secrets Manager containing the master user credentials."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
  sensitive   = true
}