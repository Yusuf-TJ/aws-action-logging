resource "aws_cloudwatch_log_subscription_filter" "lambdafunction_logfilter" {
  name            = "${var.lambda_function_name}_logfilter"
  log_group_name  = aws_cloudwatch_log_group.log_group.name
  filter_pattern  = "{ ($.eventName = \"StartInstances\") &&  ($.eventSource = \"ec2.amazonaws.com\") }"
  destination_arn = aws_lambda_function.test_lambda.arn
}

resource "aws_lambda_permission" "logging" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "logs.${var.aws_region}.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.log_group.arn}:*"
}