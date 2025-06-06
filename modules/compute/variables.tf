variable "public_subnet" {
  description = "ID of the public subnet (from the network module)"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for the WLZ EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t3.medium)"
  type        = string
}

variable "project" {
  description = "Project tag"
  type        = string
}

variable "env" {
  description = "Environment tag (e.g. prod, stage)"
  type        = string
}

variable "domain" {
  description = "Domain name (e.g. stage-pfe.store) for tagging"
  type        = string
}
