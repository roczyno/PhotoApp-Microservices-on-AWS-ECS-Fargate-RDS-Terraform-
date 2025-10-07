# Outputs
output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = module.ecr.repositories
}



output "microservice_configs" {
  description = "Microservice configurations"
  value = var.microservices
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "service_discovery_namespace" {
  description = "Service Connect namespace"
  value       = module.ecs.cluster_name
}

output "rds_endpoints" {
  description = "Per-service RDS instance endpoints"
  value = {
    "users-microservice" = module.database_users.endpoint
    "photo-microservice" = module.database_albums.endpoint
  }
}

output "rds_ports" {
  description = "Per-service RDS instance ports"
  value = {
    "users-microservice" = module.database_users.port
    "photo-microservice" = module.database_albums.port
  }
}

output "db_names" {
  description = "Per-service database names"
  value = { for k, v in var.dbs : k => v.db_name }
}

output "database_secret_arns" {
  description = "Per-service database credentials secret ARNs"
  value = {
    "users-microservice" = module.database_users.secret_arn
    "photo-microservice" = module.database_albums.secret_arn
  }
}