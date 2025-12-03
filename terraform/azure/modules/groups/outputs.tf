output "groups" {
  description = "Map of group display names to key properties."
  value = {
    for name, resource in local.group_resources :
    name => {
      object_id = resource.id
      mail      = resource.mail
    }
  }
}
