################################
# Providers
################################
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

################################
# 0. Variables
################################
variable "domain" {
  description = "The apex domain (e.g. stage-pfe.store)"
  type        = string
}

variable "zone_id" {
  description = "Route 53 hosted zone ID for the domain"
  type        = string
}

variable "frontend_public_ip" {
  description = "The EC2 instance’s public IP (so CloudFront can fetch from it)"
  type        = string
}

variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "env" {
  description = "Environment label (e.g. prod, stage)"
  type        = string
}

################################
# 1. ACM certificate (us-east-1)
################################
resource "aws_acm_certificate" "cert" {
  provider          = aws.use1
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

########################################################
# 2. DNS validation CNAME (single record, TF 1.8 safe)
########################################################
locals {
  # Take the first domain_validation_options entry
  cert_dvo = element(
    tolist(aws_acm_certificate.cert.domain_validation_options),
    0
  )
}

resource "aws_route53_record" "cert_validation" {
  zone_id = var.zone_id

  name    = local.cert_dvo.resource_record_name
  type    = local.cert_dvo.resource_record_type
  ttl     = 60
  records = [local.cert_dvo.resource_record_value]
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

########################################################
# 3. origin.<domain> A-record → EC2’s public IP
########################################################
locals {
  origin_fqdn = "origin.${var.domain}"
}

resource "aws_route53_record" "origin_a" {
  zone_id = var.zone_id
  name    = "origin.${var.domain}"
  type    = "A"
  ttl     = 60
  records = [var.frontend_public_ip]
}


###################################
# 4. CloudFront distribution
###################################
resource "aws_cloudfront_distribution" "dist" {
  provider            = aws.use1
  enabled             = true
  default_root_object = "/"

  # CloudFront responds to your apex domain
  aliases = [var.domain]

  origin {
    domain_name = local.origin_fqdn
    origin_id   = "wlz-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "wlz-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_200"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Project = var.project
    Env     = var.env
  }

  depends_on = [
    aws_acm_certificate_validation.cert,
    aws_route53_record.origin_a
  ]
}

################################################
# 5. Root A-alias → CloudFront
################################################
resource "aws_route53_record" "root_alias" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.dist.domain_name
    zone_id                = aws_cloudfront_distribution.dist.hosted_zone_id
    evaluate_target_health = false
  }
}

################
# 6. Outputs
################
output "cf_domain_name" {
  description = "CloudFront distribution domain (e.g. d1234abcdef.cloudfront.net)"
  value       = aws_cloudfront_distribution.dist.domain_name
}

output "origin_fqdn" {
  description = "The DNS name (origin.<domain>) used by CloudFront as its origin"
  value       = local.origin_fqdn
}
