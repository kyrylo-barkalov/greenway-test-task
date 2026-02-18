output "s3_bucket_name" {
  value       = aws_s3_bucket.csv_uploads.id
  description = "Upload bucket name."
}

output "lambda_function_name" {
  value       = aws_lambda_function.csv_uploads_trigger.function_name
  description = "Lambda function name."
}

output "state_machine_arn" {
  value       = aws_sfn_state_machine.csv_row_counter.arn
  description = "Step Functions state machine ARN."
}

output "emr_serverless_application_id" {
  value       = aws_emrserverless_application.csv_row_counter.id
  description = "EMR Serverless application ID."
}

output "emr_serverless_log_group" {
  value       = aws_cloudwatch_log_group.emr_serverless.name
  description = "EMR Serverless CloudWatch log group name."
}
