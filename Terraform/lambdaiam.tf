# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_minecraft" {
  name               = var.lambda_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Basic Lambda logging to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_minecraft.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SSM — send Run Command and read Parameter Store
resource "aws_iam_role_policy_attachment" "lambda_ssm" {
  role       = aws_iam_role.lambda_minecraft.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# S3 — write scan reports
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_minecraft.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# DynamoDB — read NIST control mappings
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_minecraft.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}