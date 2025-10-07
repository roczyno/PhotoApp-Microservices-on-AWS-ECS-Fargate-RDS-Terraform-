output "cluster_name" { value = aws_ecs_cluster.main.name }
output "services"     { value = { for k, v in aws_ecs_service.microservices : k => v.name } }
