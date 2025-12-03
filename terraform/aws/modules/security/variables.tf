variable "name" {
  description = "Name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "Allowed CIDRs for ALB ingress."
  type        = list(string)
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
