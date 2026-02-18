data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/upload_trigger.py"
  output_path = "${path.module}/../lambda/upload_trigger.zip"
}

locals {
  lambda_function_name = "${var.project_name}-${var.environment}-csv-uploads-trigger"
}

resource "aws_lambda_function" "csv_uploads_trigger" {
  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "upload_trigger.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      STATE_MACHINE_ARN = aws_sfn_state_machine.csv_row_counter.arn
    }
  }
}
