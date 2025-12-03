environment = "prod"

tags = {
  Owner      = "ai-platform"
  CostCenter = "llm"
}

vpc_cidr             = "10.30.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.30.0.0/24", "10.30.1.0/24"]
private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24"]
enable_nat_gateway   = true

alb_ingress_cidrs = ["0.0.0.0/0"]

database_username          = "openwebui"
database_name              = "openwebui"
database_instance_class    = "db.m6g.large"
database_allocated_storage = 400
database_engine_version    = "15.15"
database_multi_az          = true
database_backup_retention_days = 7
database_deletion_protection   = true
skip_final_snapshot            = false

openwebui_container_image = "ghcr.io/open-webui/open-webui:main"
openwebui_container_port  = 8080
openwebui_desired_count   = 3
openwebui_cpu             = 1024
openwebui_memory          = 2048
openwebui_env = {
  OPENWEBUI_PUBLIC_URL            = "https://owui.oremuslabs.app"
  OAUTH_PROVIDER                  = "oidc"
  OAUTH_CLIENT_ID                 = "replace-with-openid-client-id"
  OAUTH_ISSUER_URL                = "https://login.microsoftonline.com/abfcbee8-658f-4ab3-97f5-9b357e0f8cda/v2.0"
  ENABLE_OAUTH                    = "true"
  ENABLE_OAUTH_GROUP_MANAGEMENT   = "true"
  OAUTH_GROUPS_CLAIM              = "groups"
  ENABLE_SCIM                     = "false"
  SCIM_BASE_URL                   = "https://owui.oremuslabs.app/scim"
  LITELLM_BASE_URL                = "https://owui.oremuslabs.app/litellm"
  VECTOR_DB                       = "postgres"
}
openwebui_secret_arns = [
  {
    name       = "OAUTH_CLIENT_SECRET"
    value_from = "arn:aws:secretsmanager:us-east-1:000000000000:secret:openwebui/oidc-client"
  },
  {
    name       = "SCIM_TOKEN"
    value_from = "arn:aws:secretsmanager:us-east-1:000000000000:secret:openwebui/scim-token"
  }
]

litellm_container_image = "ghcr.io/berriai/litellm:main"
litellm_container_port  = 4000
litellm_env = {
  PORT          = "4000"
  LITELLM_DEBUG = "true"
}
litellm_secrets = [
  {
    name       = "LITELLM_CONFIG"
    value_from = "arn:aws:secretsmanager:us-east-1:000000000000:secret:litellm/config"
  }
]
litellm_internal_url = "https://owui.oremuslabs.app/litellm"

mcpo_container_image = "ghcr.io/modelcontextprotocol/mcpo:latest"
mcpo_container_port  = 8081
mcpo_env = {
  PORT = "8081"
}
mcpo_secrets = [
  {
    name       = "MCPO_CONFIG"
    value_from = "arn:aws:secretsmanager:us-east-1:000000000000:secret:mcpo/config"
  }
]

log_retention_in_days = 60

enable_cloudflare_dns  = false
cloudflare_zone_id     = ""
cloudflare_record_name = "owui"

certificate_domain_name  = "owui.oremuslabs.app"
certificate_san          = []
use_managed_certificate  = false
existing_certificate_arn = "arn:aws:acm:us-east-1:000000000000:certificate/replace-me"

alarm_topic_arns  = []
create_alarm_topic = true
