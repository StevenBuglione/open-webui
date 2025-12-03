output "administrative_unit_id" {
  description = "Object ID of the Administrative Unit created for OpenWebUI (if enabled)."
  value       = try(azuread_administrative_unit.openwebui[0].object_id, null)
  sensitive   = false
}

output "role_assignments" {
  description = "Map of role assignment IDs created by this module."
  value = {
    for key, assignment in azuread_directory_role_assignment.automation :
    key => assignment.id
  }
}
