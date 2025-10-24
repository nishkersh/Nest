variable "project_prefix" {
  description = "A prefix used for naming all resources, e.g., 'owasp-nest'."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the RDS instance will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the RDS instance and proxy."
  type        = list(string)
}

variable "db_instance_class" {
  description = "The instance class for the RDS database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage for the RDS database in GB."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "The PostgreSQL engine version."
  type        = string
  default     = "16.3"
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "owasp_nest"
}

variable "allowed_inbound_sg_ids" {
  description = "A list of Security Group IDs that are allowed to connect to the database."
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ. Recommended for prod."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. Recommended for prod."
  type        = bool
  default     = false
}

variable "enable_rds_proxy" {
  description = "Set to true to create an RDS Proxy for the database. Recommended for Lambda."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}