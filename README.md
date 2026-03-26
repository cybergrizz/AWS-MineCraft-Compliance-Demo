# 🧱 minecraft-nist-demo — AWS Infrastructure

> Terraform infrastructure for a Minecraft server environment mapped to the NIST AI Risk Management Framework. Built as a live compliance demo that audits its own infrastructure.

**Author:** [Kevin Douglas](https://github.com/cybergrizz) · [kdresume.link](https://kdresume.link) · Vienna, VA  
**Focus:** Cloud Security · GRC · IaC · NIST AI RMF

---

## Overview

This project provisions a Minecraft game server on AWS and uses it as a live compliance target. The infrastructure is intentionally built to pass the same security checks run by the [aws-security-audit-scripts](https://github.com/cybergrizz/AWS-Scanner_Proj) scanner — no open SSH, SSM-only access, KMS-encrypted CloudTrail logs, GuardDuty enabled, and S3 buckets with public access fully blocked.

Scanner findings are mapped to NIST AI RMF control categories (Govern / Map / Measure / Manage) stored in DynamoDB. A Lambda function runs the scanner daily via EventBridge, writes reports to S3, and sends Slack notifications with risk level and category breakdown — making this a working GRC demo rather than a static architecture diagram.

---

## Architecture

```
VPC: 10.0.0.0/16 (us-east-1a)
│
├── Public subnet: 10.0.1.0/24
│   ├── EC2: Minecraft server (t3.medium, Amazon Linux 2)
│   │   └── SG: port 25565 TCP/UDP inbound — no port 22
│   └── NAT Gateway + Elastic IP
│       └── Internet Gateway
│
└── Private subnet: 10.0.2.0/24
    └── EC2: Bastion / management node (t3.medium, Amazon Linux 2)
        └── SG: egress only — no public ingress

Orchestration
├── EventBridge (cron 0 8 * * ? *) → Lambda
│   └── Lambda → SSM Run Command → scanner.sh on EC2
│       ├── Results → S3 scan report
│       ├── Findings → DynamoDB NIST control mapping lookup
│       └── Slack notification (🟢 Low / 🟡 Medium / 🔴 High Risk)

Observability
├── CloudTrail → S3 (KMS encrypted, public access blocked)
└── GuardDuty  → S3 data event protection enabled

Secrets
└── SSM Parameter Store
    ├── /minecraft-nist/slack-webhook-url (SecureString)
    ├── /minecraft-nist/scan-role-arn     (SecureString)
    └── /minecraft-nist/aws-region        (String)
```

Both EC2 instances use AWS Systems Manager Session Manager for shell access. No key pairs are created and port 22 is intentionally absent from all security groups — the infrastructure passes its own `ec2-port22-open.sh` audit check by design.

---

## How It Works

```
EventBridge fires daily at 8am UTC
  └── Invokes Lambda (minecraft-nist-scanner-lambda)
        └── Pulls Slack webhook from Parameter Store
        └── Sends SSM Run Command to Minecraft EC2
              └── Executes: cd /home/ec2-user && sudo bash scanner.sh
                    └── Loops through checks/*.sh (18 checks)
        └── Waits for command completion
        └── Saves full output to S3 (scan-reports/scan_<timestamp>.txt)
        └── Counts ✅ / ❌ from output
        └── Posts Slack message with risk level + report location
```

---

## File Structure

```
.
├── providers.tf        # AWS provider config and Terraform version constraints
├── vpc.tf              # VPC, public and private subnets
├── gateways.tf         # Internet gateway, NAT gateway, Elastic IP
├── routes.tf           # Route tables and associations
├── sg.tf               # Security groups (Minecraft server, bastion)
├── ec2.tf              # EC2 instances, AMI data source, user_data bootstrap
├── iam.tf              # SSM instance role, policy attachment, instance profile
├── cloudtrail.tf       # CloudTrail trail, S3 bucket policy, KMS key and policy
├── guardduty.tf        # GuardDuty detector and S3 protection feature
├── s3.tf               # S3 bucket for CloudTrail logs and scan reports
├── parameter-store.tf  # SSM Parameter Store entries for secrets
├── dynamodb.tf         # NIST AI RMF control mapping table
├── lambdaiam.tf        # Lambda execution role and policy attachments
├── lambda.tf           # Lambda function and archive packaging
├── eventbridge.tf      # Scheduled rule, target, and Lambda invoke permission
├── outputs.tf          # Instance IDs and NAT gateway IP
├── var.tf              # All input variables
├── terraform.tfvars    # Secret values (gitignored — never commit)
└── lambda/
    └── scanner.py      # Lambda handler — orchestrates SSM, S3, Slack
```

---

## Resources Deployed (45 total)

### Networking

| Resource | Name | Value |
|----------|------|-------|
| VPC | `minecraft-nist-vpc` | `10.0.0.0/16` |
| Public subnet | `minecraft-public-subnet` | `10.0.1.0/24` — us-east-1a |
| Private subnet | `minecraft-private-subnet` | `10.0.2.0/24` — us-east-1a |
| Internet gateway | `minecraft-igw` | Attached to VPC |
| Elastic IP | `minecraft-nat-eip` | Allocated to NAT gateway |
| NAT gateway | `minecraft-nat-gateway` | Public subnet |
| Public route table | `minecraft-server-rtb` | `0.0.0.0/0` → IGW |
| Private route table | `minecraft-bastion-rtb` | `0.0.0.0/0` → NAT |

### Security Groups

| Group | Ingress | Egress |
|-------|---------|--------|
| `Minecraft Server SG` | Port 25565 TCP + UDP from `0.0.0.0/0` | All traffic |
| `Bastion SG` | None | All traffic |

### Compute

| Instance | ID | Type | Subnet |
|----------|----|------|--------|
| `minecraft-server` | `i-0eff1395e4a3d3816` | t3.medium | Public |
| `bastion` | `i-03e979ed2a8bcb4d9` | t3.medium | Private |

### IAM

| Resource | Purpose |
|----------|---------|
| `ssm_instance_role` | EC2 trust policy for SSM access |
| `AmazonSSMManagedInstanceCore` | Session Manager, Run Command, Parameter Store |
| `lambda_minecraft` | Lambda execution role |
| `AWSLambdaBasicExecutionRole` | CloudWatch logging |
| `AmazonSSMFullAccess` | Run Command + Parameter Store reads |
| `AmazonS3FullAccess` | Scan report writes |
| `AmazonDynamoDBReadOnlyAccess` | NIST control mapping lookups |

### Observability

| Resource | Details |
|----------|---------|
| CloudTrail | `minecraft_cloudtrail` — KMS encrypted, global events enabled |
| KMS key | `minecraft-cloudtrail-key` — customer-managed |
| S3 bucket | `minecraft-nist-cloudtrail-logs` — all public access blocked |
| GuardDuty | Enabled, S3 data event protection active |

### Secrets

| Parameter | Type | Purpose |
|-----------|------|---------|
| `/minecraft-nist/slack-webhook-url` | SecureString | Slack notification endpoint |
| `/minecraft-nist/scan-role-arn` | SecureString | VulnScanReadOnly cross-account role |
| `/minecraft-nist/aws-region` | String | Scanner target region |

### Compliance Data

| Resource | Details |
|----------|---------|
| DynamoDB table | `nist-control-map` — partition key: `control_id`, sort key: `check_name` |
| Encryption | KMS via `minecraft-cloudtrail-key` |
| PITR | Point-in-time recovery enabled |

### Orchestration

| Resource | Details |
|----------|---------|
| Lambda | `minecraft-nist-scanner-lambda` — Python 3.12, 300s timeout |
| EventBridge rule | `minecraft-nist-daily-scan` — `cron(0 8 * * ? *)` |
| EventBridge target | Routes to Lambda on schedule |
| Lambda permission | Allows EventBridge to invoke Lambda |

---

## Scanner Audit Coverage

Checks from [aws-security-audit-scripts](https://github.com/cybergrizz) and their expected result against this infrastructure:

| Check | Expected Result | Notes |
|-------|----------------|-------|
| `cloudtrail-enabled.sh` | ✅ Pass | Trail active |
| `cloudtrail-log-encryption.sh` | ✅ Pass | KMS key attached |
| `guardduty-enabled.sh` | ✅ Pass | Detector imported |
| `s3-block-public-access.sh` | ✅ Pass | All 4 settings enabled |
| `s3-bucket-encryption.sh` | ✅ Pass | SSE enabled |
| `ec2-port22-open.sh` | ✅ Pass | Port 22 intentionally absent |
| `ec2-port3389-open.sh` | ✅ Pass | Port 3389 intentionally absent |
| `iam-root-mfa.sh` | Depends on account | |
| `iam-no-mfa.sh` | Depends on account | |
| `iam-old-access-keys.sh` | Depends on account | |
| `rds-backups.sh` | ℹ️ No RDS | No instances in environment |
| `rds-encryption.sh` | ℹ️ No RDS | No instances in environment |
| `rds-public.sh` | ℹ️ No RDS | No instances in environment |
| `elb-logging.sh` | ℹ️ No ELB | No load balancers in environment |
| `elbv2-https.sh` | ℹ️ No ELBv2 | No load balancers in environment |
| `elbv2-tls-policy.sh` | ℹ️ No ELBv2 | No load balancers in environment |

---

## Prerequisites

- Terraform `>= 1.1.0`
- AWS CLI configured (`aws configure`)
- AWS provider `>= 5.40`
- Session Manager plugin installed
- IAM permissions for VPC, EC2, IAM, KMS, S3, CloudTrail, GuardDuty, Lambda, DynamoDB, SSM, EventBridge

---

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Connect to instances via SSM:

```bash
aws ssm start-session --target <instance-id> --region us-east-1
```

Trigger the scanner manually:

```bash
aws lambda invoke \
  --function-name minecraft-nist-scanner-lambda \
  --region us-east-1 \
  response.json && cat response.json
```

View scan reports in S3:

```bash
aws s3 ls s3://minecraft-nist-cloudtrail-logs/scan-reports/ --region us-east-1
```

Install Session Manager plugin (Windows):

```powershell
Invoke-WebRequest `
  -Uri "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe" `
  -OutFile "$env:TEMP\SessionManagerPluginSetup.exe"
Start-Process -FilePath "$env:TEMP\SessionManagerPluginSetup.exe" -ArgumentList "/S" -Wait
```

---

## Outputs

| Output | Value |
|--------|-------|
| `minecraft_server_id` | `i-0eff1395e4a3d3816` |
| `bastion_id` | `i-03e979ed2a8bcb4d9` |
| `nat_gateway_ip` | `54.205.75.135` |

---

## Security Notes

- `terraform.tfvars` is gitignored — never commit secrets to the repo
- All sensitive variables use `sensitive = true` — values are redacted in plan and apply output
- SSM Parameter Store SecureString parameters are KMS encrypted at rest
- No EC2 key pairs are created anywhere in this project
- Port 22 and port 3389 are absent from all security groups by design

---

## Related Project

**[aws-security-audit-scripts](https://github.com/cybergrizz/AWS-Scanner_Proj)** — the Bash-based scanner that this infrastructure executes against itself via SSM Run Command. The two repos are designed to work together: this is the target environment and the orchestration layer, the scanner is the audit engine.

---

## Author

**Kevin Douglas**  
Cloud Security Engineer · Vienna, VA  
🌐 [kdresume.link](https://kdresume.link) · 🐙 [github.com/cybergrizz](https://github.com/cybergrizz)

---

## License

MIT — use freely, contribute back if you improve it.
