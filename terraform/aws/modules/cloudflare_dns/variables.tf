variable "zone_id" {
  description = "Cloudflare zone identifier."
  type        = string
}

variable "record_name" {
  description = "DNS record name."
  type        = string
}

variable "record_value" {
  description = "Value for DNS record."
  type        = string
}

variable "record_type" {
  description = "DNS record type."
  type        = string
  default     = "CNAME"
}

variable "ttl" {
  description = "Record TTL when not proxied."
  type        = number
  default     = 300
}

variable "proxied" {
  description = "Whether Cloudflare should proxy the traffic."
  type        = bool
  default     = true
}
