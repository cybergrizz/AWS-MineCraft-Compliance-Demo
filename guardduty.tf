resource "aws_guardduty_detector" "minecraft_detector" {
  enable = true
}

resource "aws_guardduty_detector_feature" "s3_protection" {
  detector_id = aws_guardduty_detector.minecraft_detector.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}