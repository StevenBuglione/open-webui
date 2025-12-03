resource "cloudflare_dns_record" "this" {
  zone_id = var.zone_id
  name    = var.record_name
  type    = var.record_type
  content = var.record_value
  proxied = var.proxied
  ttl     = var.proxied ? 1 : var.ttl
}
