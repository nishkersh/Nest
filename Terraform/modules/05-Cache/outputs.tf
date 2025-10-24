output "primary_endpoint_address" {
  description = "The connection endpoint for the primary node of the Redis cluster."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "port" {
  description = "The port on which the Redis cluster is listening."
  value       = aws_elasticache_replication_group.main.port
}

output "cache_security_group_id" {
  description = "The ID of the security group for the ElastiCache cluster."
  value       = aws_security_group.cache.id
}