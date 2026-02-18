data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.project_name}-${var.environment}-csv-uploads"
}

resource "aws_s3_bucket" "csv_uploads" {
  bucket        = local.bucket_name
  force_destroy = var.s3_force_destroy
}

resource "aws_s3_bucket_notification" "csv_uploads_trigger" {
  bucket = aws_s3_bucket.csv_uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.csv_uploads_trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_s3_object" "emr_count_csv_rows" {
  bucket = aws_s3_bucket.csv_uploads.id
  key    = "emr/count_csv_rows.py"
  source = "${path.module}/../emr/count_csv_rows.py"
  etag   = filemd5("${path.module}/../emr/count_csv_rows.py")
}
