output "alb_dns"       { value = aws_lb.main.dns_name }
output "target_groups" { value = { for k, v in aws_lb_target_group.microservices : k => v.arn } }
