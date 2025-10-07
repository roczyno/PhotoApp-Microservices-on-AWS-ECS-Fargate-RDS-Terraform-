output "ecs_cpu_alarms" { value = { for k, v in aws_cloudwatch_metric_alarm.high_cpu : k => v.arn } }
output "rds_cpu_alarms" { value = { for k, v in aws_cloudwatch_metric_alarm.rds_cpu : k => v.arn } }
