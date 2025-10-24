variable "project_prefix" {
  description = "A prefix used for naming all resources, e.g., 'owasp-nest'."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the ElastiCache cluster will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the ElastiCache cluster."
  type        = list(string)
}

variable "node_type" {
  description = "The instance type for the Redis cache nodes."
  type        = string
  default     = "cache.t3.micro"
}

variable "num_node_groups" {
  description = "The number of node groups (shards) for this Redis cluster."
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "The number of replicas per node group. Set to > 0 for Multi-AZ."
  type        = number
  default     = 0 # For dev. Set to 1 or more for prod.
}

variable "engine_version" {
  description = "The Redis engine version."
  type        = string
  default     = "7.1"
}

variable "allowed_inbound_sg_ids" {
  description = "A list of Security Group IDs that are allowed to connect to the cache."
  type        = list(string)
  default     = []
}

variable "redis_auth_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret containing the auth token for Redis. The secret should store the token as a plain string."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}