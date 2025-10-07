# CloudWatch Log Groups used by ECS tasks and Service Connect
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.cluster_name}-logs"
  }
}

resource "aws_cloudwatch_log_group" "service_connect" {
  name              = "/aws/ecs/service-connect/${var.cluster_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.cluster_name}-service-connect-logs"
  }
}

# ECS Cluster with Service Connect
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs.name
      }
    }
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.service_connect.arn
  }

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


# Service Connect Namespace
resource "aws_service_discovery_http_namespace" "service_connect" {
  name        = var.cluster_name
  description = "Service Connect namespace for ${var.cluster_name}"

  tags = {
    Name = "${var.cluster_name}-service-connect-namespace"
  }
}

# IAM Roles
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for ECS task execution role to access Secrets Manager
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.cluster_name}-ecs-task-execution-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = values(var.db_secret_arns)
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-ecs-task-role"
  }
}

# ECS Task Definitions for Microservices
resource "aws_ecs_task_definition" "microservices" {
  for_each                 = var.microservices
  family                   = "${var.cluster_name}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = each.key
      image = "${var.ecr_repository_urls[each.key]}:latest"
      
      portMappings = [
        {
          name          = each.key
          containerPort = each.value.port
          protocol      = "tcp"
        }
      ]

     # In the container_definitions environment section
environment = concat([
  {
    name  = "HOST_NAME"
    value = var.db_endpoints[each.key]
  },
  {
    name  = "DATABASE_PORT"
    value = tostring(var.db_ports[each.key])
  },
  {
    name  = "DATABASE_NAME"
    value = var.db_names[each.key]
  },
  {
    name  = "spring.profiles.active"
    value = "prod"
  }
], each.key == "users-microservice" ? [
  {
    name  = "albums.url"
    value = "http://photo-microservice:8080/albums"
  }
] : [])


      secrets = [
  {
    name      = "DATABASE_USER_PASSWORD"
    valueFrom = "${var.db_secret_arns[each.key]}:password::"
  },
  {
    name      = "DATABASE_USER_NAME"
    valueFrom = "${var.db_secret_arns[each.key]}:username::"
  }
]


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = "eu-west-1"
          awslogs-stream-prefix = each.key
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${each.value.port}${each.value.health_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name    = "${var.cluster_name}-${each.key}-task"
    Service = each.key
  }
}

# ECS Services with Service Connect
resource "aws_ecs_service" "microservices" {
  for_each        = var.microservices
  name            = "${var.cluster_name}-${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_sg_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  # Load balancer configuration (only for services that need external access)
  dynamic "load_balancer" {
    for_each = contains(keys(var.alb_target_group_arns), each.key) ? [1] : []
    content {
      target_group_arn = var.alb_target_group_arns[each.key]
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  # Service Connect Configuration
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.service_connect.arn

    service {
      port_name      = each.key
      discovery_name = each.key
      client_alias {
        port     = each.value.port
        dns_name = each.key
      }
    }

    # Service Connect logging
    log_configuration {
      log_driver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.service_connect.name
        awslogs-region        = "eu-west-1"
        awslogs-stream-prefix = "service-connect-${each.key}"
      }
    }
  }

  depends_on = []

  tags = {
    Name    = "${var.cluster_name}-${each.key}-service"
    Service = each.key
  }
}

# Auto Scaling for Microservices
resource "aws_appautoscaling_target" "ecs_targets" {
  for_each           = var.microservices
  max_capacity       = each.value.desired_count   # Scale up to 5x the desired count
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.microservices[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  for_each           = var.microservices
  name               = "${var.cluster_name}-${each.key}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_targets[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_targets[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_targets[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_out_cooldown = 300
    scale_in_cooldown  = 300
  }
}
