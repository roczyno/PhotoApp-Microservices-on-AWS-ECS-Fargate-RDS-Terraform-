output "cluster_name" { value = aws_ecs_cluster.main.name }
output "services"     { value = { for k, v in aws_ecs_service.microservices : k => v.name } }
output "task_execution_role_arn" { value = aws_iam_role.ecs_task_execution_role.arn }
output "task_role_arn" { value = aws_iam_role.ecs_task_role.arn }
