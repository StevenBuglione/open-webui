output "ssm_parameter_names" {
  value       = keys(aws_ssm_parameter.this)
  description = "Names of parameters managed."
}
