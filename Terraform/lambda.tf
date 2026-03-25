data "archive_file" "scanner_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/scanner.py"
  output_path = "${path.module}/lambda/scanner.zip"
}

resource "aws_lambda_function" "scanner_lambda" {
  filename         = data.archive_file.scanner_zip.output_path
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda_minecraft.arn
  handler          = "scanner.lambda_handler"
  source_code_hash = data.archive_file.scanner_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 300

  environment {
    variables = {
      INSTANCE_ID = aws_instance.minecraft_server.id
      S3_BUCKET   = aws_s3_bucket.minecraft_cloudtrail.id
      TABLE_NAME  = var.table_name
    }
  }

  tags = {
    Name    = "minecraft-nist-scanner"
    Project = "minecraft-nist-demo"
  }
}