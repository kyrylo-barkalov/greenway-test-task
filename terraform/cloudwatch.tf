resource "aws_cloudwatch_log_group" "csv_uploads_trigger" {
  name              = "/aws/lambda/${aws_lambda_function.csv_uploads_trigger.function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_cloudwatch_log_group" "emr_serverless" {
  name              = "/aws/emr-serverless/${local.emr_application_name}"
  retention_in_days = var.log_retention_in_days
}
