data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- IAM Roles & Policies ---

# 1. ECS Task Execution Role: Grants the ECS agent permissions to pull container images and write logs.
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_prefix}-${var.environment}-ecs-exec-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. ECS Task Role (Frontend): Grants the frontend application container permissions.
resource "aws_iam_role" "frontend_ecs_task_role" {
  name               = "${var.project_prefix}-${var.environment}-frontend-task-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_policy" "frontend_ecs_task_policy" {
  name        = "${var.project_prefix}-${var.environment}-frontend-task-policy"
  description = "Policy for the frontend ECS task to access application secrets."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = var.app_secrets_manager_secret_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "frontend_ecs_task_role_attachment" {
  role       = aws_iam_role.frontend_ecs_task_role.name
  policy_arn = aws_iam_policy.frontend_ecs_task_policy.arn
}

# 3. Lambda Execution Role (Backend): Grants the backend Lambda function permissions.
resource "aws_iam_role" "backend_lambda_role" {
  name               = "${var.project_prefix}-${var.environment}-backend-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_lambda_basic_execution" {
  role       = aws_iam_role.backend_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "backend_lambda_vpc_policy" {
  name        = "${var.project_prefix}-${var.environment}-backend-lambda-vpc-policy"
  description = "Allows Lambda function to create ENIs within the VPC."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backend_lambda_vpc_access" {
  role       = aws_iam_role.backend_lambda_role.name
  policy_arn = aws_iam_policy.backend_lambda_vpc_policy.arn
}

resource "aws_iam_policy" "backend_lambda_policy" {
  name        = "${var.project_prefix}-${var.environment}-backend-lambda-policy"
  description = "Policy for the backend Lambda to access secrets and other services."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "secretsmanager:GetSecretValue",
        Resource = [
          var.app_secrets_manager_secret_arn,
          var.db_master_user_secret_arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backend_lambda_custom_policy" {
  role       = aws_iam_role.backend_lambda_role.name
  policy_arn = aws_iam_policy.backend_lambda_policy.arn
}

# 4. EC2 Instance Role (Cron Jobs)
resource "aws_iam_role" "cron_ec2_role" {
  name               = "${var.project_prefix}-${var.environment}-cron-ec2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_instance_profile" "cron_ec2_profile" {
  name = "${var.project_prefix}-${var.environment}-cron-ec2-profile"
  role = aws_iam_role.cron_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "cron_ec2_ssm_policy" {
  role       = aws_iam_role.cron_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "cron_ec2_policy" {
  name        = "${var.project_prefix}-${var.environment}-cron-ec2-policy"
  description = "Policy for the cron EC2 instance to access secrets."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "secretsmanager:GetSecretValue",
        Resource = [
          var.app_secrets_manager_secret_arn,
          var.db_master_user_secret_arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cron_ec2_custom_policy" {
  role       = aws_iam_role.cron_ec2_role.name
  policy_arn = aws_iam_policy.cron_ec2_policy.arn
}

# --- Security Groups ---

resource "aws_security_group" "frontend_ecs" {
  name        = "${var.project_prefix}-${var.environment}-frontend-ecs-sg"
  description = "Allow traffic from ALB to Frontend ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
    security_groups = [var.alb_security_group_id] 
    description     = "Allow traffic from ALB"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-frontend-ecs-sg" })
}

resource "aws_security_group" "backend_lambda" {
  name        = "${var.project_prefix}-${var.environment}-backend-lambda-sg"
  description = "Security group for the backend Lambda function"
  vpc_id      = var.vpc_id

  # No ingress rules needed as it's invoked by API Gateway (managed by Zappa) or ALB.
  # Egress is required to connect to RDS, Redis, and public APIs.
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-backend-lambda-sg" })
}

resource "aws_security_group" "cron_ec2" {
  name        = "${var.project_prefix}-${var.environment}-cron-ec2-sg"
  description = "Controls access to the cron EC2 instance"
  vpc_id      = var.vpc_id

  # No ingress rules. Access is via SSM Session Manager.
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-cron-ec2-sg" })
}

# --- ECS Fargate for Frontend ---

resource "aws_ecs_cluster" "main" {
  name = "${var.project_prefix}-${var.environment}-cluster"
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_prefix}-${var.environment}/frontend"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_prefix}-${var.environment}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.frontend_ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = var.frontend_container_image
    cpu       = var.frontend_cpu
    memory    = var.frontend_memory
    essential = true
    portMappings = [{
      containerPort = var.frontend_container_port
      hostPort      = var.frontend_container_port
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
    secretsConfiguration = {
      secrets = {
        APP_SECRETS = var.app_secrets_manager_secret_arn
      }
    }
    environment = [
      {
        name  = "NEXT_PUBLIC_API_URL",
        value = "https://${var.alb_dns_name}" # Simplified URL
      },
      {
        name  = "NEXT_PUBLIC_ENVIRONMENT",
        value = var.environment
      },
    ]
  }])

  tags = var.tags
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project_prefix}-${var.environment}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.frontend_ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_lb_listener_rule.https_frontend_rule]
  tags       = var.tags
}

# --- ALB Configuration for Frontend ---

resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_prefix}-${var.environment}-frontend-tg"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = "/"
    matcher = "200"
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "https_frontend_rule" {
  listener_arn = var.alb_https_listener_arn
  priority     = 100 # Default rule with lowest priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# --- ALB Configuration for Backend (Lambda) ---

resource "aws_lb_target_group" "backend_lambda" {
  name        = "${var.project_prefix}-${var.environment}-backend-lambda-tg"
  target_type = "lambda"
  tags        = var.tags
}

resource "aws_lb_target_group_attachment" "backend_lambda" {
  target_group_arn = aws_lb_target_group.backend_lambda.arn
  target_id        = var.backend_lambda_function_arn

  # This depends on the Lambda function, which is created by Zappa.
  # This creates a dependency that must be managed during deployment.
  # Initially, this might be commented out or use a placeholder.
}

resource "aws_lambda_permission" "alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = var.backend_lambda_function_arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.backend_lambda.arn
}

resource "aws_lb_listener_rule" "https_backend_rule" {
  listener_arn = var.alb_https_listener_arn
  priority     = 10 # Higher priority to catch API paths

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_lambda.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/graphql/*", "/csrf/*"] # Add all backend paths
    }
  }
}

# --- EC2 Instance for Cron Jobs ---

resource "aws_instance" "cron" {
  ami           = var.cron_ami_id
  instance_type = var.cron_instance_type
  subnet_id     = var.private_subnet_ids[0]

  vpc_security_group_ids = [aws_security_group.cron_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.cron_ec2_profile.name

  # Ensure secure access via SSM, not public SSH keys
  user_data = <<-EOT
              #!/bin/bash
              # Add setup scripts here, e.g., installing cron, application code, etc.
              EOT

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-cron-instance" })
}