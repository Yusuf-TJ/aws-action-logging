
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_logging_policy_doc" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_function_name}:*"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name                = "${var.lambda_function_name}-role-xkz"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.lambda_logging_policy.arn]
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "AWSLambdaBasicExecutionRolefor${var.lambda_function_name}"
  description = "A policy for lambda"
  policy      = data.aws_iam_policy_document.lambda_logging_policy_doc.json
}

data "archive_file" "lambda_func_zip" {
  type        = "zip"
  source_dir  = "lambda_function"
  output_path = "${var.lambda_function_name}_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = data.archive_file.lambda_func_zip.output_path
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  environment {
    variables = { "SLACK_WEBHOOK_URL" : var.slack_webhook_url }
  }
}
