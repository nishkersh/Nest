variable "project_prefix" {
  description = "A prefix used for naming all resources, e.g., 'owasp-nest'."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

variable "static_assets_bucket_name" {
  description = "The desired name for the S3 bucket that will store public static assets. Must be globally unique."
  type        = string
}

variable "private_media_bucket_name" {
  description = "The desired name for the S3 bucket that will store private user media. Must be globally unique."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}