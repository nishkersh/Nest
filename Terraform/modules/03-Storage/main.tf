# --- S3 Bucket for Private Media Uploads ---
resource "aws_s3_bucket" "private_media" {
  bucket = var.private_media_bucket_name
  tags   = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-private-media-bucket" })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_media" {
  bucket = aws_s3_bucket.private_media.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_versioning" "private_media" {
  bucket = aws_s3_bucket.private_media.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "private_media" {
  bucket                  = aws_s3_bucket.private_media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "private_media" {
  bucket = aws_s3_bucket.private_media.id
  policy = data.aws_iam_policy_document.private_media_policy.json
}

data "aws_iam_policy_document" "private_media_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.private_media.arn,
      "${aws_s3_bucket.private_media.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# --- S3 Bucket for Static Assets (Served via CloudFront) ---
resource "aws_s3_bucket" "static_assets" {
  bucket = var.static_assets_bucket_name
  tags   = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-static-assets-bucket" })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket                  = aws_s3_bucket.static_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  policy = data.aws_iam_policy_document.static_assets_policy.json
}

# --- CloudFront for Public Static Assets ---
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_prefix}-${var.environment}-s3-oac"
  description                       = "Origin Access Control for static assets bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "static_assets" {
  origin {
    domain_name              = aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id                = "S3-${var.static_assets_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.static_assets_bucket_name}"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.static_assets_bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100" 

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(var.tags, { Name = "${var.project_prefix}-${var.environment}-static-assets-cdn" })
}

data "aws_iam_policy_document" "static_assets_policy" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_assets.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static_assets.arn]
    }
  }
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.static_assets.arn,
      "${aws_s3_bucket.static_assets.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}