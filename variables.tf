variable "project"        { type = string }
variable "env"            { type = string }
variable "domain"         { type = string }    # e.g. example.com
variable "wlz_name" {
  type    = string
  default = "eu-west-3-cmn-wlz-1a"
}

variable "ami_id" {
  description = "AMI for WLZ instances (must be available in eu-west-3‑WLZ)"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

