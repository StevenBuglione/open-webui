output "record_id" {
  value       = cloudflare_dns_record.this.id
  description = "Cloudflare record identifier."
}

output "hostname" {
  value       = cloudflare_dns_record.this.name
  description = "DNS name configured on the record."
}
