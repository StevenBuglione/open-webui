data "terraform_remote_state" "azure_nonprod" {
  backend = "s3"

  config = {
    bucket                      = "workspaces"
    key                         = "open-webui/azure/nonprod.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = "https://s3.oremuslabs.app" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    shared_credentials_files    = ["~/.aws/credentials"]
    profile                     = "default"
  }
}

locals {
  azure_openwebui_application   = try(data.terraform_remote_state.azure_nonprod.outputs.openwebui_application, null)
  azure_openwebui_client_id     = try(local.azure_openwebui_application.client_id, null)
  azure_openwebui_client_secret = try(local.azure_openwebui_application.client_secret, null)
}
