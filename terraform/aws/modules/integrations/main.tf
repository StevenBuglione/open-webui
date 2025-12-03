resource "aws_ssm_parameter" "this" {
  for_each = var.ssm_parameters

  name        = each.key
  type        = each.value.type
  value       = each.value.value
  description = try(each.value.description, null)
  tags        = var.tags
  tier        = "Standard"
  overwrite   = true
}
