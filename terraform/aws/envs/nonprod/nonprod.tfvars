environment = "nonprod"

tags = {
  Owner      = "ai-platform"
  CostCenter = "llm"
}

vpc_cidr             = "10.20.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]
enable_nat_gateway   = true

alb_ingress_cidrs = [
  "0.0.0.0/0"
]

database_username              = "openwebui"
database_name                  = "openwebui"
database_instance_class        = "db.m6g.large"
database_allocated_storage     = 200
database_engine_version        = "15.15"
database_multi_az              = true
database_backup_retention_days = 7
database_deletion_protection   = true
skip_final_snapshot            = false

openwebui_container_image = "ghcr.io/open-webui/open-webui:main"
openwebui_container_port  = 8080
openwebui_desired_count   = 2
openwebui_cpu             = 1024
openwebui_memory          = 2048

openwebui_env = {
  OPENWEBUI_PUBLIC_URL          = "https://external.owui-prod.oremuslabs.app"
  OAUTH_PROVIDER                = "oidc"
  OAUTH_CLIENT_ID               = "replace-with-openid-client-id"
  OAUTH_ISSUER_URL              = "https://login.microsoftonline.com/abfcbee8-658f-4ab3-97f5-9b357e0f8cda/v2.0"
  OPENID_PROVIDER_URL           = "https://login.microsoftonline.com/abfcbee8-658f-4ab3-97f5-9b357e0f8cda/v2.0/.well-known/openid-configuration"
  OPENID_REDIRECT_URI           = "https://external.owui-prod.oremuslabs.app/oauth/callback"
  OAUTH_PROVIDER_NAME           = "Microsoft Entra ID"
  CONFIG_LOG_LEVEL              = "DEBUG"
  OAUTH_LOG_LEVEL               = "DEBUG"
  ENABLE_OAUTH                  = "true"
  ENABLE_OAUTH_GROUP_MANAGEMENT = "true"
  OAUTH_GROUPS_CLAIM            = "groups"
  ENABLE_SCIM                   = "false"
  SCIM_BASE_URL                 = "https://external.owui-prod.oremuslabs.app/scim"
  LITELLM_BASE_URL              = "https://external.owui-prod.oremuslabs.app/litellm"
  VECTOR_DB                     = "pgvector"
}

openwebui_secret_arns = []

litellm_internal_url    = "https://external.owui-prod.oremuslabs.app/litellm"
litellm_container_image = "ghcr.io/berriai/litellm:main"
litellm_container_port  = 4000
litellm_env = {
  PORT                    = "4000"
  LITELLM_DEBUG           = "true"
  AWS_REGION              = "us-east-1"
  AWS_DEFAULT_REGION      = "us-east-1"
  LITELLM_CONFIG_FALLBACK = <<-EOT
  {
    "model_list": [
      {
        "model_name": "claude-sonnet",
        "litellm_params": {
          "model": "bedrock/anthropic.claude-3-sonnet-20240229-v1:0",
          "aws_region": "us-east-1",
          "timeout": 60
        }
      },
      {
        "model_name": "claude-haiku",
        "litellm_params": {
          "model": "bedrock/anthropic.claude-3-haiku-20240307-v1:0",
          "aws_region": "us-east-1",
          "timeout": 60
        }
      },
      {
        "model_name": "llama3-405b",
        "litellm_params": {
          "model": "bedrock/meta.llama3.1-405b-instruct-v1:0",
          "aws_region": "us-east-1",
          "timeout": 60
        }
      }
    ],
    "litellm_settings": {
      "drop_params": true,
      "set_verbose": true
    }
  }
  EOT
}
litellm_config_secret = <<-EOT
{
  "model_list": [
    {
      "model_name": "claude-sonnet",
      "litellm_params": {
        "model": "bedrock/anthropic.claude-3-sonnet-20240229-v1:0",
        "aws_region": "us-east-1",
        "timeout": 60
      }
    },
    {
      "model_name": "claude-haiku",
      "litellm_params": {
        "model": "bedrock/anthropic.claude-3-haiku-20240307-v1:0",
        "aws_region": "us-east-1",
        "timeout": 60
      }
    },
    {
      "model_name": "llama3-405b",
      "litellm_params": {
        "model": "bedrock/meta.llama3.1-405b-instruct-v1:0",
        "aws_region": "us-east-1",
        "timeout": 60
      }
    }
  ],
  "litellm_settings": {
    "drop_params": true,
    "set_verbose": true
  }
}
EOT
litellm_secrets       = []

mcpo_container_image = "public.ecr.aws/docker/library/python:3.11-slim"
mcpo_container_port  = 8081
mcpo_env = {
  PORT                 = "8081"
  PYTHONUNBUFFERED     = "1"
  PIP_NO_CACHE_DIR     = "1"
  PIP_ROOT_USER_ACTION = "ignore"
}
mcpo_config_secret = <<-EOT
{
  "mcpServers": {}
}
EOT
mcpo_secrets       = []

log_retention_in_days = 30

enable_cloudflare_dns  = true
cloudflare_zone_id     = "54e6b3c156fa928a6c7d73025408e845"
cloudflare_record_name = "external.owui-prod"

certificate_domain_name  = "external.owui-prod.oremuslabs.app"
certificate_san          = []
use_managed_certificate  = true
existing_certificate_arn = ""

alarm_topic_arns   = []
create_alarm_topic = true
