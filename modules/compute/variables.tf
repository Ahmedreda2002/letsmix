variable "instance_type" {
  description = "Size of the EC2 instance (e.g. t3.medium)"
  type        = string
}

variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "env" {
  description = "Environment (e.g. dev, prod)"
  type        = string
}

variable "domain" {
  description = "Our domain (e.g. stage-pfe.store)"
  type        = string
}

variable "ami_id" {
  description = "WLZ-compatible AMI ID (e.g. ami-074e262099d145e90)"
  type        = string
}

variable "key_name" {
  description = "An existing AWS Key Pair name to attach to the instance"
  type        = string
}

variable "public_subnet" {
  description = "Subnet ID where the EC2 instance will be launched"
  type        = string
}
