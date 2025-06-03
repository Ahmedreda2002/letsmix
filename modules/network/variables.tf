variable "wlz_name" { type = string }

variable "env" {
  description = "Environment label (e.g. prod, stage)"
  type        = string
}

variable "project" {
  description = "Project name for tagging"
  type        = string
}