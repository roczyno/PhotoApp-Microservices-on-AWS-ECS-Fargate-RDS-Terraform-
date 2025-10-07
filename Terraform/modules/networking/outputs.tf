output "vpc_id"              { value = aws_vpc.PhotoApp_VPC.id }
output "public_subnet_ids"   { value = aws_subnet.public[*].id }
output "private_subnet_ids"  { value = aws_subnet.private[*].id }
output "alb_sg_id"           { value = aws_security_group.alb.id }
output "ecs_sg_id"           { value = aws_security_group.ecs_tasks.id }
output "rds_sg_id"           { value = aws_security_group.rds.id }
output "db_subnet_group_name" { value = aws_db_subnet_group.main.name }
