variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS region for all resources."
  type        = string
  default     = "default"
}

variable "lambda_function_name" {
  description = "Name of the lambda function"
  type        = string
  default     = "monitoringFunc"
}

variable "s3_bucket_name_base" {
  description = "Name of the trail"
  type        = string
  default     = "tf-test-trail-azs129"
}

variable "trail_name" {
  description = "Name of the trail"
  type        = string
  default     = "cloud_trail_from_terraform"
}

variable "trail_s3_prefix" {
  description = "Prefix for the S3 bucket"
  type        = string
  default     = "tf_prefix"
}

variable "slack_webhook_url" {
  description = "Webhook URL for the slack channel"
  type        = string
}
