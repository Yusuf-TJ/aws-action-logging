resource "random_string" "rando" {
  length  = 6     # Length of the random string
  special = false # Include special characters (e.g., !@#$%) in the random string
  upper   = false
}

locals {
  s3_bucket_name = "${var.s3_bucket_name_base}-${random_string.rando.result}"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "log-group-${var.trail_name}"
}

resource "aws_iam_role" "policy" {
  name = "CloudTrailRoleForCloudWatchLogs_${var.trail_name}"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AWSCloudTrailAssumeRole"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AWSCloudTrailCreateLogStream2014110",
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream"
          ],
          "Resource" : [
            "${aws_cloudwatch_log_group.log_group.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${var.aws_region}*"
          ]
        },
        {
          "Sid" : "AWSCloudTrailPutLogEvents20141101",
          "Effect" : "Allow",
          "Action" : [
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "${aws_cloudwatch_log_group.log_group.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${var.aws_region}*"
          ]
        }
      ]
    })
  }
}

resource "aws_cloudtrail" "example" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.example.id
  s3_key_prefix                 = var.trail_s3_prefix
  include_global_service_events = false
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.log_group.arn}:*" # CloudTrail requires the Log Stream wildcard
  cloud_watch_logs_role_arn     = aws_iam_role.policy.arn
  depends_on                    = [aws_s3_bucket_policy.example]
}

resource "aws_s3_bucket" "example" {
  bucket        = local.s3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.policy0.json
}

data "aws_iam_policy_document" "policy0" {
  statement {
    sid    = "AWSCloudTrailAclCheck20150319"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.example.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite20150319"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.example.arn}/${var.trail_s3_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"]
    }
  }
}