output "endpoint" {

  value = aws_db_instance.postgres.endpoint
}

output "database" {

  value = aws_db_instance.postgres.db_name
}

output "username" {

  value = aws_db_instance.postgres.username
}