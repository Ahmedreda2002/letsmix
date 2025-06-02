variable "project" { type = string }
variable "env" { type = string }

resource "aws_s3_bucket" "artifact" {
  bucket        = "${var.project}-${var.env}-artifacts"
  force_destroy = false
  versioning { enabled = true }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = { Project = var.project, Env = var.env }
}

output "artifact_bucket" { value = aws_s3_bucket.artifact.bucket }
