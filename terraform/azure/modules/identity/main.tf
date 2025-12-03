locals {
  assignments = {
    for idx, assignment in var.role_assignments :
    format("%03d-%s", idx, assignment.principal_object_id) => assignment
  }
  default_admin_unit_id = try(azuread_administrative_unit.openwebui[0].id, null)
  assignment_scopes = {
    for key, assignment in local.assignments :
    key => coalesce(assignment.administrative_unit_object_id, local.default_admin_unit_id, "")
  }
}

resource "azuread_administrative_unit" "openwebui" {
  count                     = var.create_administrative_unit ? 1 : 0
  display_name              = var.administrative_unit_display_name
  description               = var.administrative_unit_description
  hidden_membership_enabled = true
}

resource "azuread_directory_role_assignment" "automation" {
  for_each = local.assignments

  role_id             = each.value.directory_role_id
  principal_object_id = each.value.principal_object_id
  directory_scope_id  = local.assignment_scopes[each.key] != "" ? format("/administrativeUnits/%s", local.assignment_scopes[each.key]) : null

  lifecycle {
    precondition {
      condition     = each.value.directory_role_id != null
      error_message = "Each role assignment must include directory_role_id referencing an enabled directory role."
    }
  }
}
