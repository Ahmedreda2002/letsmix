################
# 6. Outputs
################
output "cf_domain_name" {
  description = "The CloudFront distribution domain (e.g. d1234abcdef.cloudfront.net)"
  value       = aws_cloudfront_distribution.dist.domain_name
}

output "origin_fqdn" {
  description = "The DNS name (origin.<domain>) that CloudFront uses as its origin"
  value       = local.origin_fqdn
}
