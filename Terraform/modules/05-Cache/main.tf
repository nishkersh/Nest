# --- ElastiCache Subnet Group ---
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_prefix}-${var.environment}-redis-sng"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-redis-sng" })
}

# --- ElastiCache Security Group ---
resource "aws_security_group" "cache" {
  name        = "${var.project_prefix}-${var.environment}-cache-sg"
  description = "Controls access to the ElastiCache Redis cluster"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 6379
    to_port         = 6379
    security_groups = var.allowed_inbound_sg_ids
    description     = "Allow Redis traffic from application components"
  }


  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-cache-sg" })
}

# --- Secure User and Group Management for Redis Auth ---
resource "aws_elasticache_user" "app_user" {
  user_id       = "${var.project_prefix}-${var.environment}-app-user"
  user_name     = "app-user"
  engine        = "REDIS"
  access_string = "on ~* +@all" # Grants the user all permissions
  authentication_mode {
    type     = "password"
    passwords = [data.aws_secretsmanager_secret_version.redis_auth.secret_string]
  }
}

resource "aws_elasticache_user_group" "app_user_group" {
  user_group_id = "${var.project_prefix}-${var.environment}-app-group"
  engine        = "REDIS"
  user_ids      = [aws_elasticache_user.app_user.user_id]
}

# --- ElastiCache Redis Cluster ---
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_prefix}-${var.environment}-redis"
  description                = "OWASP Nest Redis Cluster"
  node_type                  = var.node_type
  engine                     = "redis"
  engine_version             = var.engine_version
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.cache.id]
  automatic_failover_enabled = var.replicas_per_node_group > 0
  multi_az_enabled           = var.replicas_per_node_group > 0

  # Cluster mode settings
  num_node_groups         = var.num_node_groups
  replicas_per_node_group = var.replicas_per_node_group

  # Security settings
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  user_group_ids             = [aws_elasticache_user_group.app_user_group.id]

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-redis-cluster" })
}

# --- Data source to fetch Redis auth token from Secrets Manager ---
data "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = var.redis_auth_secret_arn
}