resource "aws_cloudwatch_event_rule" "scanner_schedule" {
  name                = "minecraft-nist-daily-scan"
  description         = "Triggers the NIST compliance scanner Lambda daily at 8am UTC"
  schedule_expression = "cron(0 8 * * ? *)"

  tags = {
    Name    = "minecraft-nist-daily-scan"
    Project = "minecraft-nist-demo"
  }
}

resource "aws_cloudwatch_event_target" "scanner_lambda" {
  rule      = aws_cloudwatch_event_rule.scanner_schedule.name
  target_id = "ScannerLambda"
  arn       = aws_lambda_function.scanner_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scanner_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scanner_schedule.arn
}