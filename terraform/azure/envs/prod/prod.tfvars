tenant_id       = "abfcbee8-658f-4ab3-97f5-9b357e0f8cda"
subscription_id = "1f47ae5c-ae18-452e-96f3-f8db19062ca8"
location        = "eastus2"

security_resource_group_name   = "rg-openwebui-sec-prod"
monitoring_resource_group_name = "rg-openwebui-monitor-prod"

key_vault_name                      = "kv-openwebui-prod"
key_vault_private_endpoint_subnet_id = null
virtual_network_id                   = null
log_analytics_workspace_name        = "law-openwebui-prod"

groups = [
  {
    display_name = "OWUI-Admins-Prod"
    description  = "Production OpenWebUI administrators"
  },
  {
    display_name = "OWUI-Developers-Prod"
    description  = "Production developers and advanced builders"
  },
  {
    display_name = "OWUI-Business-Prod"
    description  = "Production business analysts"
  }
]

rbac_mappings = {
  "OWUI-Admins-Prod" = {
    openwebui_role = "admin"
    lite_llm_team  = "admins"
  }
  "OWUI-Developers-Prod" = {
    openwebui_role = "workspace-admin"
    lite_llm_team  = "developers"
  }
  "OWUI-Business-Prod" = {
    openwebui_role = "user"
    lite_llm_team  = "business"
  }
}

role_assignments = []

create_administrative_unit       = true
administrative_unit_display_name = "OpenWebUI Prod AU"

openwebui_redirect_uris = [
  "https://owui.example.com/oauth/callback"
]
openwebui_logout_url     = "https://owui.example.com/logout"
openwebui_identifier_uris = []
openwebui_app_roles = [
  {
    allowed_member_types = ["User"]
    description          = "Full administrative access to OpenWebUI prod"
    display_name         = "OWUI Admin"
    value                = "admin"
  },
  {
    allowed_member_types = ["User"]
    description          = "Manage production workspaces"
    display_name         = "OWUI Workspace Admin"
    value                = "workspace-admin"
  }
]

scim_base_address = "https://owui.example.com/scim"
scim_secret_token = "PLEASE_UPDATE_SCIM_TOKEN"
scim_template_id  = "d4d8f7f3-19c7-4dbf-a489-8f3f85c24f0c"
scim_enabled      = true

lite_llm_application_enabled = true
lite_llm_identifier_uris     = []
lite_llm_display_name        = "LiteLLM Prod"

conditional_access_policies = []

diagnostic_sources      = []
key_vault_rbac_assignments = []

tags = {
  Application = "OpenWebUI"
  Environment = "prod"
  Owner       = "ai-platform"
}
