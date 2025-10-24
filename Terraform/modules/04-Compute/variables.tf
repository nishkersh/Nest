variable "project_prefix" {
  description = "A prefix used for naming all resources, e.g., 'owasp-nest'."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for compute resources."
  type        = list(string)
}

# --- ALB Integration ---
variable "alb_https_listener_arn" {
  description = "The ARN of the ALB's HTTPS listener to attach rules to."
  type        = string
}

variable "alb_dns_name" {
  description = "The DNS name of the ALB."
  type        = string
}

variable "alb_security_group_id" {
  description = "The ID of the ALB's security group, for creating SG rules."
  type        = string
}

# --- ECS / Fargate (Frontend) ---
variable "frontend_container_image" {
  description = "The Docker image for the frontend Next.js application (e.g., from ECR)."
  type        = string
}

variable "frontend_container_port" {
  description = "The port the frontend container listens on."
  type        = number
  default     = 3000
}

variable "frontend_cpu" {
  description = "The number of CPU units to reserve for the frontend container."
  type        = number
  default     = 256 # 0.25 vCPU
}

variable "frontend_memory" {
  description = "The amount of memory (in MiB) to reserve for the frontend container."
  type        = number
  default     = 512 # 0.5 GB
}

variable "frontend_desired_count" {
  description = "The desired number of frontend tasks to run."
  type        = number
  default     = 1
}

# --- Lambda (Backend) ---
variable "backend_lambda_function_arn" {
  description = "The ARN of the backend Lambda function. This is created by Zappa, not Terraform."
  type        = string
}

# --- EC2 (Cron Jobs) ---
variable "cron_instance_type" {
  description = "The EC2 instance type for the cron job runner."
  type        = string
  default     = "t3.micro"
}

variable "cron_ami_id" {
  description = "The AMI ID for the cron job EC2 instance. Use an Amazon Linux 2023 AMI."
  type        = string
}

# --- Secrets ---
variable "db_master_user_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret for the database credentials."
  type        = string
}

variable "app_secrets_manager_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret containing other application secrets (e.g., Algolia, Sentry)."
  type        = string
}

# --- Tags ---
variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}