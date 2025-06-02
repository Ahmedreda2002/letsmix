terraform {
  backend "s3" {
    bucket         = "wlz-tf-state-portfolio-20250512" # change if taken
    key            = "global/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}
