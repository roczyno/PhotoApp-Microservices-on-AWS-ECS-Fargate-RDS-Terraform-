output "rds_id"        { value = aws_db_instance.postgres.id }
output "endpoint"      { value = aws_db_instance.postgres.endpoint }
output "address"       { value = aws_db_instance.postgres.address }
output "port"          { value = aws_db_instance.postgres.port }
output "secret_arn"    { value = aws_secretsmanager_secret.db_credentials.arn }
