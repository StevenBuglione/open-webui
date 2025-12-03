output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "rds_endpoint" {
  value = module.data.db_endpoint
}

output "ecs_cluster_name" {
  value = module.compute.ecs_cluster_name
}
