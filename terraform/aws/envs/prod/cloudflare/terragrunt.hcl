include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg          = read_tfvars_file("../prod.tfvars")
  cloudflare_token = get_env("CLOUDFLARE_API_TOKEN", "")
}

skip = !local.env_cfg.enable_cloudflare_dns

dependency "aws_stack" {
  config_path = ".."
  mock_outputs = {
    alb_dns_name = "alb.example.com"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "${get_parent_terragrunt_dir()}//modules/cloudflare_dns"
}

generate "provider_cloudflare" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "cloudflare" {
  api_token = "${local.cloudflare_token}"
}
EOF
}

inputs = {
  zone_id      = local.env_cfg.cloudflare_zone_id
  record_name  = local.env_cfg.cloudflare_record_name
  record_value = dependency.aws_stack.outputs.alb_dns_name
  proxied      = true
}

dependencies {
  paths = [".."]
}
