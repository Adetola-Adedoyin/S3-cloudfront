# AWS S3 Static Website with CloudFront

# Provider configuration
provider "aws" {
  region = "us-east-1"  # North Virginia region
}

# Create an S3 bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = "bucketty-${random_pet.bucket_suffix.id}"  # Unique name with random suffix
  
  tags = {
    Name        = "Website Bucket"
    Environment = "Dev"
  }
}

# Generate a random suffix for globally unique bucket name
resource "random_pet" "bucket_suffix" {
  length = 2
}

# Set bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Configure the bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Set public access block configuration
resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Create bucket policy to allow public read access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Upload index.html to the bucket
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>My Terraform Website</title>
    <style>
        body { 
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: #f0f2f5;
        }
        .container {
            text-align: center;
            padding: 40px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            max-width: 800px;
        }
        h1 { color: #4285f4; }
        p { color: #5f6368; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello from Terraform!</h1>
        <p>This static website is hosted on Amazon S3 and served through CloudFront.</p>
        <p>It is designed to be simple and easy to understand.</p>
        <p>Adetola Adedoyin is the author of this website.</p>
        <p>All infrastructure was created using Terraform.</p>
    </div>
</body>
</html>
EOF
  content_type = "text/html"
}

# Upload error.html to the bucket
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Error - My Terraform Website</title>
    <style>
        body { 
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: #f0f2f5;
        }
        .container {
            text-align: center;
            padding: 40px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            max-width: 800px;
        }
        h1 { color: #ea4335; }
        p { color: #5f6368; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Oops! Something went wrong</h1>
        <p>The page you're looking for might have been moved or doesn't exist.</p>
        <p><a href="/">Return to homepage</a></p>
    </div>
</body>
</html>
EOF
  content_type = "text/html"
}

# Create CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "access-identity-for-static-website"
}

# Create CloudFront distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # Use only North America and Europe edge locations (cheapest)

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website.bucket}"

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

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }
}

# Output the S3 website URL
output "s3_website_url" {
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "URL of the S3 static website (no HTTPS)"
}

# Output CloudFront distribution domain name
output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.website_distribution.domain_name
  description = "Domain name of the CloudFront distribution (with HTTPS)"
}
#automation script 
resource "aws_s3_bucket_public_access_block" "disable_block" {
  bucket = aws_s3_bucket.website.id  

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id 
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.disable_block]
}
