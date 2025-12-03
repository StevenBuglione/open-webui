output "synchronization_job_id" {
  description = "ID of the SCIM synchronization job (if created)."
  value       = var.enabled ? azuread_synchronization_job.scim[0].id : null
}
