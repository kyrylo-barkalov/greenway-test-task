locals {
  emr_application_name = "${var.project_name}-${var.environment}-emr-serverless"
}

resource "aws_emrserverless_application" "csv_row_counter" {
  name          = local.emr_application_name
  release_label = var.emr_release_label
  type          = "SPARK"
}
