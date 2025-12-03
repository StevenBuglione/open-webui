locals {
  aws_region    = "us-east-1"
  aws_profile   = get_env("AWS_PROFILE", "aws-login")
  state_profile = "default"

  path_from_root = path_relative_to_include()
  environment    = local.path_from_root == "." ? "root" : basename(local.path_from_root)
  state_key      = "open-webui/aws/${local.environment}.tfstate"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket                      = "workspaces"
    key                         = local.state_key
    region                      = "us-east-1"
    endpoints                   = { s3 = "https://s3.oremuslabs.app" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    shared_credentials_files    = ["~/.aws/credentials"]
    profile                     = local.state_profile
  }
}
