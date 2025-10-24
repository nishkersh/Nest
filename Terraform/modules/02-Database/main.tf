# --- Database Subnet Group ---
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_prefix}-${var.environment}-rds-sng"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-rds-sng" })
}

# --- Database Security Group ---
resource "aws_security_group" "db" {
  name        = "${var.project_prefix}-${var.environment}-db-sg"
  description = "Controls access to the RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = var.allowed_inbound_sg_ids
    description     = "Allow PostgreSQL traffic from application components"
  }

  # Egress to other resources within the VPC can be handled by referencing their security groups if needed.

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-db-sg" })
}

# --- RDS PostgreSQL Instance ---
resource "aws_db_instance" "main" {
  identifier             = "${var.project_prefix}-${var.environment}-db"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = 100
  storage_type           = "gp3"
  db_name                = var.db_name
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az               = var.multi_az
  skip_final_snapshot    = var.environment == "prod" ? false : true
  deletion_protection    = var.deletion_protection


  manage_master_user_password   = true
  master_user_secret_kms_key_id = "alias/aws/secretsmanager" 

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:05:00-sun:06:00"

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-db-instance" })

  depends_on = [aws_iam_role_policy_attachment.rds_monitoring]
}

# --- IAM Role for Enhanced Monitoring ---
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_prefix}-${var.environment}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# --- RDS Proxy for Serverless Connection Pooling ---

resource "aws_iam_role" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0
  name  = "${var.project_prefix}-${var.environment}-rds-proxy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_proxy_secrets" {
  count      = var.enable_rds_proxy ? 1 : 0
  role       = aws_iam_role.rds_proxy[0].name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" 
}

resource "aws_db_proxy" "main" {
  count              = var.enable_rds_proxy ? 1 : 0
  name               = "${var.project_prefix}-${var.environment}-proxy"
  debug_logging      = false
  engine_family      = "POSTGRESQL"
  idle_client_timeout = 1800
  require_tls        = true
  role_arn           = aws_iam_role.rds_proxy[0].arn
  vpc_security_group_ids = [aws_security_group.db.id] 
  vpc_subnet_ids     = var.private_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_db_instance.main.master_user_secret[0].secret_arn
  }

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-rds-proxy" })
}

resource "aws_db_proxy_default_target_group" "main" {
  count         = var.enable_rds_proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.main[0].name
  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  count                = var.enable_rds_proxy ? 1 : 0
  db_instance_identifier = aws_db_instance.main.id
  db_proxy_name          = aws_db_proxy.main[0].name
  target_group_name      = aws_db_proxy_default_target_group.main[0].name
}