resource "aws_dynamodb_table" "nist_control_map" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "control_id"
  range_key    = "check_name"

  attribute {
    name = "control_id"
    type = "S"
  }

  attribute {
    name = "check_name"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.cloudtrail_key.arn
  }

  tags = {
    Name    = "nist-control-map"
    Project = "minecraft-nist-demo"
  }
}