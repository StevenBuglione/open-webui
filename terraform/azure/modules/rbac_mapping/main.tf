locals {
  mapping = {
    for group_name, mapping in var.mappings :
    group_name => merge(mapping, {
      object_id = try(var.group_lookup[group_name].object_id, null)
      mail      = try(var.group_lookup[group_name].mail, null)
    })
  }

  missing_groups = [for name, mapping in local.mapping : name if mapping.object_id == null]
}

resource "null_resource" "rbac_validation" {
  triggers = {
    hash = sha1(jsonencode(local.mapping))
  }

  lifecycle {
    precondition {
      condition     = length(local.missing_groups) == 0
      error_message = format("RBAC mapping references groups that do not exist: %s", join(", ", local.missing_groups))
    }
  }
}
