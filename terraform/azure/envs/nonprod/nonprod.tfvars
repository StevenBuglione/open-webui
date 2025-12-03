tenant_id       = "abfcbee8-658f-4ab3-97f5-9b357e0f8cda"
subscription_id = "1f47ae5c-ae18-452e-96f3-f8db19062ca8"
location        = "eastus2"

security_resource_group_name   = "rg-openwebui-sec-nonprod"
monitoring_resource_group_name = "rg-openwebui-monitor-nonprod"

key_vault_name                      = "kv-openwebui-nonprod"
key_vault_private_endpoint_subnet_id = null
virtual_network_id                   = null
log_analytics_workspace_name        = "law-openwebui-nonprod"

groups = [
  {
    display_name = "OWUI-Admins-NonProd"
    description  = "Non-prod OpenWebUI administrators"
  },
  {
    display_name = "OWUI-Developers-NonProd"
    description  = "Non-prod developers and advanced builders"
  },
  {
    display_name = "OWUI-Business-NonProd"
    description  = "Business analysts / read-write users"
  }
]

rbac_mappings = {
  "OWUI-Admins-NonProd" = {
    openwebui_role = "admin"
    lite_llm_team  = "owui-nonprod-admins"
  }
  "OWUI-Developers-NonProd" = {
    openwebui_role = "workspace-admin"
    lite_llm_team  = "owui-nonprod-builders"
  }
  "OWUI-Business-NonProd" = {
    openwebui_role = "user"
    lite_llm_team  = "owui-nonprod-business"
  }
}

role_assignments = []

create_administrative_unit        = true
administrative_unit_display_name  = "OpenWebUI NonProd AU"

openwebui_redirect_uris = [
  "https://owui-nonprod.oremuslabs.app/oauth/callback"
]
openwebui_logout_url     = "https://owui-nonprod.oremuslabs.app/logout"
openwebui_identifier_uris = []
openwebui_app_roles = [
  {
    allowed_member_types = ["User"]
    description          = "Full administrative access to OpenWebUI non-prod"
    display_name         = "OWUI Admin"
    value                = "admin"
  },
  {
    allowed_member_types = ["User"]
    description          = "Can manage workspaces and tooling"
    display_name         = "OWUI Workspace Admin"
    value                = "workspace-admin"
  }
]

scim_base_address = "https://owui-nonprod.oremuslabs.app/scim"
scim_secret_token = "nonprod-scim-token-a9f3df04"
scim_template_id  = "d4d8f7f3-19c7-4dbf-a489-8f3f85c24f0c"
scim_enabled      = false

lite_llm_application_enabled = true
lite_llm_identifier_uris     = []
lite_llm_display_name        = "LiteLLM NonProd"

conditional_access_policies = []

diagnostic_sources      = []
key_vault_rbac_assignments = []

tags = {
  Application = "OpenWebUI"
  Environment = "nonprod"
  Owner       = "ai-platform"
}
