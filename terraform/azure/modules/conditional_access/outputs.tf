output "policy_ids" {
  description = "Map of conditional access policy names to IDs."
  value = {
    for name, policy in azuread_conditional_access_policy.this :
    name => policy.id
  }
}
