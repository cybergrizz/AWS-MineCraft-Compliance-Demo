resource "aws_s3_bucket" "minecraft_cloudtrail" {
  bucket = var.bucket_name

  tags = {
    Name        = "Minecraft CloudTrail"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "minecraft_clodtrail_block" {
  bucket = aws_s3_bucket.minecraft_cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}