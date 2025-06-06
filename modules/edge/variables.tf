
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


variable "frontend_ip" {
  type        = string
  description = "The WLZ EC2 public IPv4 address for origin."
}

variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "env" {
  description = "Environment label (e.g. prod, stage)"
  type        = string
}
