 

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  for_each            = var.microservices
  alarm_name          = "${var.cluster_name}-${each.key}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ${each.key} service cpu utilization"

  dimensions = {
    ServiceName = var.ecs_service_names[each.key]
    ClusterName = var.ecs_cluster_name
  }

  tags = {
    Name    = "${var.cluster_name}-${each.key}-high-cpu-alarm"
    Service = each.key
  }
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  for_each            = var.rds_instance_ids
  alarm_name          = "${var.cluster_name}-${each.key}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization for ${each.key}"

  dimensions = {
    DBInstanceIdentifier = each.value
  }

  tags = {
    Name    = "${var.cluster_name}-${each.key}-rds-cpu-alarm"
    Service = each.key
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  for_each            = var.rds_instance_ids
  alarm_name          = "${var.cluster_name}-${each.key}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors RDS connection count for ${each.key}"

  dimensions = {
    DBInstanceIdentifier = each.value
  }

  tags = {
    Name    = "${var.cluster_name}-${each.key}-rds-connections-alarm"
    Service = each.key
  }
}