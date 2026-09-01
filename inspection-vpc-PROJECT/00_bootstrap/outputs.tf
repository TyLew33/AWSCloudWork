output "state_bucket" {
  description = "S3 bucket name used by every later stage's backend.tf"
  value       = aws_s3_bucket.state.bucket
}

output "state_lock_table" {
  description = "DynamoDB table name used by every later stage's backend.tf"
  value       = aws_dynamodb_table.lock.name
}
