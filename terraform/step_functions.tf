locals {
  state_machine_name = coalesce(
    var.state_machine_name,
    "${var.project_name}-${var.environment}-csv-row-counter"
  )
}

resource "aws_sfn_state_machine" "csv_row_counter" {
  name     = local.state_machine_name
  role_arn = aws_iam_role.sfn_exec.arn

  definition = jsonencode({
    Comment = "Start an EMR Serverless job that counts CSV rows."
    StartAt = "RunEmrServerlessJob"
    States = {
      RunEmrServerlessJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::emr-serverless:startJobRun.sync"
        Parameters = {
          ApplicationId    = aws_emrserverless_application.csv_row_counter.id
          ExecutionRoleArn = aws_iam_role.emr_serverless_exec.arn
          JobDriver = {
            SparkSubmit = {
              EntryPoint              = "s3://${aws_s3_bucket.csv_uploads.bucket}/${aws_s3_object.emr_count_csv_rows.key}"
              "EntryPointArguments.$" = "States.Array(States.Format('s3://{}/{}', $.bucket, $.key))"
            }
          }
          ConfigurationOverrides = {
            MonitoringConfiguration = {
              CloudWatchLoggingConfiguration = {
                Enabled             = true
                LogGroupName        = aws_cloudwatch_log_group.emr_serverless.name
                LogStreamNamePrefix = "csv-row-counter"
              }
            }
          }
        }
        End = true
      }
    }
  })
}
