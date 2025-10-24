output "static_assets_bucket_id" {
  description = "The ID (name) of the S3 bucket for static assets."
  value       = aws_s3_bucket.static_assets.id
}

output "static_assets_bucket_arn" {
  description = "The ARN of the S3 bucket for static assets."
  value       = aws_s3_bucket.static_assets.arn
}

output "private_media_bucket_id" {
  description = "The ID (name) of the S3 bucket for private media."
  value       = aws_s3_bucket.private_media.id
}

output "private_media_bucket_arn" {
  description = "The ARN of the S3 bucket for private media."
  value       = aws_s3_bucket.private_media.arn
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution for static assets."
  value       = aws_cloudfront_distribution.static_assets.domain_name
}