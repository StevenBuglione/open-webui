locals {
  policies = { for policy in var.policies : policy.display_name => policy }
}

resource "azuread_conditional_access_policy" "this" {
  for_each     = local.policies
  display_name = each.value.display_name
  state        = each.value.state

  conditions {
    client_app_types = try(each.value.client_app_types, ["all"])

    applications {
      included_applications = each.value.include_applications
    }

    users {
      included_groups = each.value.include_groups
      excluded_groups = try(each.value.exclude_groups, [])
    }

    dynamic "locations" {
      for_each = try(each.value.locations, null) == null ? [] : [each.value.locations]
      content {
        included_locations = length(try(locations.value.include_locations, [])) > 0 ? locations.value.include_locations : ["All"]
        excluded_locations = try(locations.value.exclude_locations, [])
      }
    }

    dynamic "platforms" {
      for_each = try(each.value.platforms, null) == null ? [] : [each.value.platforms]
      content {
        included_platforms = length(try(platforms.value.include_platforms, [])) > 0 ? platforms.value.include_platforms : ["all"]
        excluded_platforms = try(platforms.value.exclude_platforms, [])
      }
    }

    sign_in_risk_levels = try(each.value.conditions.sign_in_risk_levels, [])
    user_risk_levels    = try(each.value.conditions.user_risk_levels, [])
  }

  grant_controls {
    operator          = try(each.value.grant_controls.operator, "AND")
    built_in_controls = each.value.grant_controls.built_in_controls
  }

  dynamic "session_controls" {
    for_each = try(each.value.session_controls, null) == null ? [] : [each.value.session_controls]
    content {
      application_enforced_restrictions_enabled = try(session_controls.value.application_enforced_restrictions, false)
      persistent_browser_mode                   = try(session_controls.value.persist_browser_session, null)
      sign_in_frequency                         = try(session_controls.value.sign_in_frequency_days, null)
      sign_in_frequency_period                  = try(session_controls.value.sign_in_frequency_days, null) == null ? null : "days"
    }
  }
}
