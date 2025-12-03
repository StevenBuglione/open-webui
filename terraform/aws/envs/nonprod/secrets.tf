resource "random_password" "openwebui_secret_key" {
  length  = 64
  special = false
}

locals {
  openwebui_oidc_secret_value = local.openwebui_oidc_secret_effective
  openwebui_scim_secret_value = var.openwebui_scim_token != "" ? var.openwebui_scim_token : "replace-me"
  litellm_config_secret_value = var.litellm_config_secret != "" ? var.litellm_config_secret : "{}"
  mcpo_config_secret_value    = var.mcpo_config_secret != "" ? var.mcpo_config_secret : "{}"
  openwebui_secret_key_value  = var.openwebui_secret_key != "" ? var.openwebui_secret_key : random_password.openwebui_secret_key.result
}

resource "aws_secretsmanager_secret" "openwebui_secret_key" {
  name        = "${local.name}/webui-secret-key"
  description = "Session signing secret for ${local.name}"
  kms_key_id  = module.security.kms_key_arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "openwebui_secret_key" {
  secret_id     = aws_secretsmanager_secret.openwebui_secret_key.id
  secret_string = local.openwebui_secret_key_value
}

resource "aws_secretsmanager_secret" "openwebui_oidc_client" {
  name        = "${local.name}/oidc-client"
  description = "OIDC client secret for ${local.name}"
  kms_key_id  = module.security.kms_key_arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "openwebui_oidc_client" {
  secret_id     = aws_secretsmanager_secret.openwebui_oidc_client.id
  secret_string = local.openwebui_oidc_secret_value
}

resource "aws_secretsmanager_secret" "openwebui_scim_token" {
  name        = "${local.name}/scim-token"
  description = "SCIM token used by ${local.name}"
  kms_key_id  = module.security.kms_key_arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "openwebui_scim_token" {
  secret_id     = aws_secretsmanager_secret.openwebui_scim_token.id
  secret_string = local.openwebui_scim_secret_value
}

resource "aws_secretsmanager_secret" "litellm_config" {
  name        = "${local.name}/litellm-config"
  description = "LiteLLM configuration for ${local.name}"
  kms_key_id  = module.security.kms_key_arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "litellm_config" {
  secret_id     = aws_secretsmanager_secret.litellm_config.id
  secret_string = local.litellm_config_secret_value
}

resource "aws_secretsmanager_secret" "mcpo_config" {
  name        = "${local.name}/mcpo-config"
  description = "mcpo configuration for ${local.name}"
  kms_key_id  = module.security.kms_key_arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "mcpo_config" {
  secret_id     = aws_secretsmanager_secret.mcpo_config.id
  secret_string = local.mcpo_config_secret_value
}
