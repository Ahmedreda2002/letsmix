# modules/edge/variables.tf
variable "domain" {
  type = string          # e.g. "stage-pfe.store"
}

variable "frontend_ip" {
  type = string          # carrier-grade IP of WLZ EC2
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "zone_id" {
  description = "ID of the public hosted zone for var.domain"
  type        = string
}
