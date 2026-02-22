variable "aws_region" {
  type        = string
  description = "AWS region to deploy to."
}

variable "project_name" {
  type        = string
  description = "Prefix used for resource names."
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all supported resources."
}

variable "s3_force_destroy" {
  type        = bool
  description = "Whether to allow deleting the bucket with objects."
}

variable "log_retention_in_days" {
  type        = number
  description = "CloudWatch log retention for the Lambda function."
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds."
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda memory size in MB."
}

variable "lambda_function_name" {
  type        = string
  description = "Override Lambda function name."
}

variable "state_machine_name" {
  type        = string
  description = "Override Step Functions state machine name."
}

variable "emr_release_label" {
  type        = string
  description = "EMR Serverless release label."
}
