resource "aws_ssm_parameter" "minecraft_server_slack" {
  name        = "/minecraft-nist/slack-webhook-url"
  type        = "SecureString"
  value       = var.webhook
  description = "Slack webhook URL for scanner notifications"

  tags = {
    Project = "minecraft-nist-demo"
  }
}

resource "aws_ssm_parameter" "minecraft_server_role" {
  name        = "/minecraft-nist/scan-role-arn"
  type        = "SecureString"
  value       = var.scan_role
  description = "IAM role ARN for VulnScanReadOnly cross-account access"

  tags = {
    Project = "minecraft-nist-demo"
  }
}

resource "aws_ssm_parameter" "aws_region" {
  name        = "/minecraft-nist/aws-region"
  type        = "String"
  value       = var.parameter_region
  description = "Target region for scanner execution"

  tags = {
    Project = "minecraft-nist-demo"
  }
}

