resource "aws_s3_bucket" "artifact" {
  # 1) Lowercase the inputs
  # 2) Replace any underscores (“_”) with hyphens (“-”)
  bucket = "${replace(lower(var.project), "_", "-")}-${replace(lower(var.env), "_", "-")}-artifacts"

  force_destroy = false

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}