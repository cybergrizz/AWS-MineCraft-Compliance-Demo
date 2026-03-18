resource "aws_cloudtrail" "minecraft_cloudtrail" {
  depends_on = [aws_s3_bucket_policy.minecraft_cloudtrail_policy]

  name                          = "minecraft_cloudtrail"
  s3_bucket_name                = aws_s3_bucket.minecraft_cloudtrail.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = true
  kms_key_id                    = aws_kms_key.cloudtrail_key.arn
}

resource "aws_kms_key" "cloudtrail_key" {
  description             = "KMS key for CloudTrail log encryption"
  deletion_window_in_days = 7

  tags = {
    Name    = "minecraft-cloudtrail-key"
    Project = "minecraft-nist-demo"
  }
}

resource "aws_kms_key_policy" "cloudtrail_key_policy" {
  key_id = aws_kms_key.cloudtrail_key.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/minecraft_cloudtrail"
          }
        }
      }
    ]
  })
}



data "aws_iam_policy_document" "minecraft_cloudtrail_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.minecraft_cloudtrail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/minecraft_cloudtrail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.minecraft_cloudtrail.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/minecraft_cloudtrail"]
    }
  }
}

resource "aws_s3_bucket_policy" "minecraft_cloudtrail_policy" {
  bucket = aws_s3_bucket.minecraft_cloudtrail.id
  policy = data.aws_iam_policy_document.minecraft_cloudtrail_policy.json
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}