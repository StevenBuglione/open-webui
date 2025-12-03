locals {
  groups_with_owners = {
    for group in var.groups : group.display_name => group
    if try(length(group.owners), 0) > 0
  }

  groups_without_owners = {
    for group in var.groups : group.display_name => group
    if try(length(group.owners), 0) == 0
  }
}

resource "azuread_group" "with_owners" {
  for_each = local.groups_with_owners

  display_name               = each.value.display_name
  description                = try(each.value.description, null)
  security_enabled           = try(each.value.security_enabled, true)
  mail_enabled               = try(each.value.mail_enabled, false)
  mail_nickname              = coalesce(try(each.value.mail_nickname, null), substr(replace(lower(each.value.display_name), "[^0-9a-z]", "-"), 0, 64))
  visibility                 = try(each.value.visibility, "Private")
  owners                     = each.value.owners
  members                    = try(each.value.members, null)
  assignable_to_role         = try(each.value.assignable_to_role, false)
  auto_subscribe_new_members = try(each.value.auto_subscribe_new_members, false)
  external_senders_allowed   = try(each.value.external_senders_allowed, false)
  behaviors                  = try(each.value.behaviors, null)
  types                      = try(each.value.types, null)
  administrative_unit_ids    = compact([var.administrative_unit_id])
  prevent_duplicate_names    = var.prevent_duplicate_names

  dynamic "dynamic_membership" {
    for_each = try(each.value.dynamic_membership, null) == null ? [] : [each.value.dynamic_membership]
    content {
      enabled = dynamic_membership.value.enabled
      rule    = dynamic_membership.value.rule
    }
  }
}

resource "azuread_group" "without_owners" {
  for_each = local.groups_without_owners

  display_name               = each.value.display_name
  description                = try(each.value.description, null)
  security_enabled           = try(each.value.security_enabled, true)
  mail_enabled               = try(each.value.mail_enabled, false)
  mail_nickname              = coalesce(try(each.value.mail_nickname, null), substr(replace(lower(each.value.display_name), "[^0-9a-z]", "-"), 0, 64))
  visibility                 = try(each.value.visibility, "Private")
  members                    = try(each.value.members, null)
  assignable_to_role         = try(each.value.assignable_to_role, false)
  auto_subscribe_new_members = try(each.value.auto_subscribe_new_members, false)
  external_senders_allowed   = try(each.value.external_senders_allowed, false)
  behaviors                  = try(each.value.behaviors, null)
  types                      = try(each.value.types, null)
  administrative_unit_ids    = compact([var.administrative_unit_id])
  prevent_duplicate_names    = var.prevent_duplicate_names

  dynamic "dynamic_membership" {
    for_each = try(each.value.dynamic_membership, null) == null ? [] : [each.value.dynamic_membership]
    content {
      enabled = dynamic_membership.value.enabled
      rule    = dynamic_membership.value.rule
    }
  }
}

locals {
  group_resources = merge(
    { for name, resource in azuread_group.with_owners : name => resource },
    { for name, resource in azuread_group.without_owners : name => resource }
  )
}
