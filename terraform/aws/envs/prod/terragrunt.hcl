include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}//envs/prod"

  extra_arguments "env_tfvars" {
    commands  = ["plan", "apply", "destroy"]
    arguments = ["-var-file=${get_terragrunt_dir()}/prod.tfvars"]
  }
}

inputs = {
  aws_region  = include.root.locals.aws_region
  aws_profile = include.root.locals.aws_profile
}
