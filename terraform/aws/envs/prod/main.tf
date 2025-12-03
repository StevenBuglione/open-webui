locals {
  environment = var.environment
  name        = "owui-${local.environment}"
  tags = merge(var.tags, {
    Environment = local.environment
    Application = "OpenWebUI"
  })

  certificate_arn = var.use_managed_certificate ? aws_acm_certificate.managed[0].arn : var.existing_certificate_arn
}

resource "aws_acm_certificate" "managed" {
  count                     = var.use_managed_certificate ? 1 : 0
  domain_name               = var.certificate_domain_name
  subject_alternative_names = var.certificate_san
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "acm_validation" {
  for_each = var.use_managed_certificate && var.enable_cloudflare_dns ? {
    for dvo in aws_acm_certificate.managed[0].domain_validation_options :
    dvo.domain_name => dvo
  } : {}

  zone_id = var.cloudflare_zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  value   = each.value.resource_record_value
  ttl     = 300
}

resource "aws_acm_certificate_validation" "managed" {
  count                   = var.use_managed_certificate && var.enable_cloudflare_dns ? 1 : 0
  certificate_arn         = aws_acm_certificate.managed[0].arn
  validation_record_fqdns = [for record in cloudflare_record.acm_validation : record.hostname]
}

module "network" {
  source               = "../../modules/network"
  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.tags
}

module "security" {
  source            = "../../modules/security"
  name              = local.name
  vpc_id            = module.network.vpc_id
  alb_ingress_cidrs = var.alb_ingress_cidrs
  tags              = local.tags
}

module "data" {
  source                         = "../../modules/data"
  name                           = local.name
  private_subnet_ids             = module.network.private_subnet_ids
  rds_security_group_id          = module.security.rds_security_group_id
  efs_security_group_id          = module.security.efs_security_group_id
  kms_key_arn                    = module.security.kms_key_arn
  database_username              = var.database_username
  database_name                  = var.database_name
  database_instance_class        = var.database_instance_class
  database_allocated_storage     = var.database_allocated_storage
  database_engine_version        = var.database_engine_version
  database_multi_az              = var.database_multi_az
  database_deletion_protection   = var.database_deletion_protection
  database_backup_retention_days = var.database_backup_retention_days
  skip_final_snapshot            = var.skip_final_snapshot
  tags                           = local.tags
}

locals {
  services = {
    openwebui = {
      container_image   = var.openwebui_container_image
      container_port    = var.openwebui_container_port
      desired_count     = var.openwebui_desired_count
      cpu               = var.openwebui_cpu
      memory            = var.openwebui_memory
      attach_to_alb     = true
      path_patterns     = ["/*"]
      health_check_path = "/"
      env = merge(var.openwebui_env, {
        OPENAI_API_BASE = var.litellm_internal_url
      })
      secrets = concat([
        {
          name       = "DATABASE_URL"
          value_from = module.data.database_url_secret_arn
        }
      ], var.openwebui_secret_arns)
      efs_volume = {
        file_system_id     = module.data.efs_file_system_id
        access_point_id    = module.data.efs_access_point_id
        container_path     = "/data"
        transit_encryption = true
        use_iam            = true
      }
    }
    litellm = {
      container_image = var.litellm_container_image
      container_port  = var.litellm_container_port
      desired_count   = 1
      cpu             = 512
      memory          = 1024
      attach_to_alb   = true
      path_patterns   = ["/litellm/*"]
      env             = var.litellm_env
      secrets         = var.litellm_secrets
    }
    mcpo = {
      container_image = var.mcpo_container_image
      container_port  = var.mcpo_container_port
      desired_count   = 1
      cpu             = 512
      memory          = 1024
      attach_to_alb   = true
      path_patterns   = ["/mcpo/*"]
      env             = var.mcpo_env
      secrets         = var.mcpo_secrets
    }
  }
}

module "compute" {
  source                    = "../../modules/compute"
  name                      = local.name
  region                    = var.aws_region
  tags                      = local.tags
  vpc_id                    = module.network.vpc_id
  public_subnet_ids         = module.network.public_subnet_ids
  private_subnet_ids        = module.network.private_subnet_ids
  alb_security_group_id     = module.security.alb_security_group_id
  service_security_group_id = module.security.ecs_service_security_group_id
  certificate_arn           = local.certificate_arn
  kms_key_arn               = module.security.kms_key_arn
  services                  = local.services
  primary_service           = "openwebui"
  log_retention_in_days     = var.log_retention_in_days
}

module "integrations" {
  source = "../../modules/integrations"
  ssm_parameters = {
    "/openwebui/${local.environment}/oauth/client_id" = {
      value       = var.openwebui_env["OAUTH_CLIENT_ID"]
      description = "OpenWebUI OIDC client ID"
    }
    "/openwebui/${local.environment}/oauth/issuer" = {
      value       = var.openwebui_env["OAUTH_ISSUER_URL"]
      description = "OpenWebUI issuer"
    }
  }
  tags = local.tags
}

module "observability" {
  source             = "../../modules/observability"
  name               = local.name
  rds_instance_id    = module.data.db_instance_id
  alb_arn_suffix     = module.compute.alb_arn_suffix
  ecs_cluster_name   = module.compute.ecs_cluster_name
  ecs_service_name   = "${local.name}-openwebui"
  alarm_topic_arns   = var.alarm_topic_arns
  create_alarm_topic = var.create_alarm_topic
  tags               = local.tags
}
