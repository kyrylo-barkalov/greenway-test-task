resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_s3_read" {
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.csv_uploads.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_s3_read" {
  name   = "${var.project_name}-lambda-s3-read"
  policy = data.aws_iam_policy_document.lambda_s3_read.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_read" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_read.arn
}

data "aws_iam_policy_document" "lambda_sfn_start" {
  statement {
    actions = ["states:StartExecution"]
    resources = [
      aws_sfn_state_machine.csv_row_counter.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_sfn_start" {
  name   = "${var.project_name}-lambda-sfn-start"
  policy = data.aws_iam_policy_document.lambda_sfn_start.json
}

resource "aws_iam_role_policy_attachment" "lambda_sfn_start" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sfn_start.arn
}

resource "aws_iam_role" "sfn_exec" {
  name = "${var.project_name}-sfn-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "sfn_emr_start" {
  statement {
    actions = [
      "emr-serverless:StartJobRun",
      "emr-serverless:GetJobRun"
    ]
    resources = [
      aws_emrserverless_application.csv_row_counter.arn,
      "${aws_emrserverless_application.csv_row_counter.arn}/jobruns/*"
    ]
  }

  statement {
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.emr_serverless_exec.arn
    ]
  }

  statement {
    actions = [
      "events:PutRule",
      "events:PutTargets",
      "events:DescribeRule",
      "events:DeleteRule",
      "events:RemoveTargets",
      "events:ListTargetsByRule"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sfn_emr_start" {
  name   = "${var.project_name}-sfn-emr-start"
  policy = data.aws_iam_policy_document.sfn_emr_start.json
}

resource "aws_iam_role_policy_attachment" "sfn_emr_start" {
  role       = aws_iam_role.sfn_exec.name
  policy_arn = aws_iam_policy.sfn_emr_start.arn
}

resource "aws_iam_role" "emr_serverless_exec" {
  name = "${var.project_name}-emr-serverless-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "emr-serverless.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "emr_serverless_exec" {
  statement {
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      aws_cloudwatch_log_group.emr_serverless.arn,
      "${aws_cloudwatch_log_group.emr_serverless.arn}:*"
    ]
  }

  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.csv_uploads.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "emr_serverless_exec" {
  name   = "${var.project_name}-emr-serverless-exec"
  policy = data.aws_iam_policy_document.emr_serverless_exec.json
}

resource "aws_iam_role_policy_attachment" "emr_serverless_exec" {
  role       = aws_iam_role.emr_serverless_exec.name
  policy_arn = aws_iam_policy.emr_serverless_exec.arn
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_uploads_trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.csv_uploads.arn
}
