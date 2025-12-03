include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  enable_cloudflare_dns = true
  cloudflare_zone_id    = "54e6b3c156fa928a6c7d73025408e845"
  cloudflare_record_name = "owui-nonprod"
  cloudflare_token      = get_env("CLOUDFLARE_API_TOKEN", "")
}

skip = !local.enable_cloudflare_dns

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
  zone_id      = local.cloudflare_zone_id
  record_name  = local.cloudflare_record_name
  record_value = dependency.aws_stack.outputs.alb_dns_name
  proxied      = false
}

dependencies {
  paths = [".."]
}
