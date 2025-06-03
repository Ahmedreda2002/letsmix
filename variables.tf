variable "project" { type = string }
variable "env" { type = string }
variable "domain" { type = string } # e.g. example.com
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

variable "key_name" {
  description = "SSH key pair name to attach to the instance"
  type        = string
}
variable "zone_id" {
  description = "Route 53 public hosted zone ID for the domain"
  type        = string
}

