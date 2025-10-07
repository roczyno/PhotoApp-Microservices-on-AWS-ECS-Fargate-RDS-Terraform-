
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.cluster_name}-alb"
  }
}

# Application Load Balancer Target Groups
resource "aws_lb_target_group" "microservices" {
  for_each    = var.microservices
  name        = "${each.key}-tg"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = each.value.health_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.cluster_name}-${each.key}-tg"
    Service = each.key
  }
}

# ALB Listener Rules (API service gets default rule, others get path-based routing)
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action for API service
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservices["users-microservice"].arn
  }
}

resource "aws_lb_listener_rule" "users" {
  listener_arn = aws_lb_listener.app.arn
  priority     = 90

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservices["users-microservice"].arn
  }

  condition {
    path_pattern {
      values = ["/users*"]
    }
  }
}

resource "aws_lb_listener_rule" "worker" {
  listener_arn = aws_lb_listener.app.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservices["photo-microservice"].arn
  }

  condition {
    path_pattern {
      values = ["/albums*"]
    }
  }
}

