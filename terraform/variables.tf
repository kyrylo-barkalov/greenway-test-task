variable "aws_region" {
  type        = string
  description = "AWS region to deploy to."
  default     = "eu-central-1"
}

variable "project_name" {
  type        = string
  description = "Prefix used for resource names."
  default     = "greenway-test-task"
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
  default     = "sandbox"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all supported resources."
  default     = {}
}

variable "s3_force_destroy" {
  type        = bool
  description = "Whether to allow deleting the bucket with objects."
  default     = false
}

variable "log_retention_in_days" {
  type        = number
  description = "CloudWatch log retention for the Lambda function."
  default     = 14
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds."
  default     = 10
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda memory size in MB."
  default     = 128
}

variable "lambda_function_name" {
  type        = string
  description = "Override Lambda function name."
  default     = null
}

variable "state_machine_name" {
  type        = string
  description = "Override Step Functions state machine name."
  default     = null
}

variable "emr_release_label" {
  type        = string
  description = "EMR Serverless release label."
  default     = "emr-6.15.0"
}
