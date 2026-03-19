# minecraft-nist-demo — AWS Infrastructure

> Terraform infrastructure for a Minecraft server environment mapped to the NIST AI Risk Management Framework. Built as a live compliance demo that audits its own infrastructure.

**Author:** [Kevin Douglas](https://github.com/cybergrizz) · [kdresume.link](https://kdresume.link) · Vienna, VA  
**Focus:** Cloud Security · GRC · IaC · NIST AI RMF

> **Status:** In progress — networking, compute, observability, and storage layers deployed. SSM Parameter Store, Lambda scanner, DynamoDB NIST mapping, and EventBridge trigger coming next.

---

## Overview

This project provisions a Minecraft game server on AWS and uses it as a live compliance target. The infrastructure is intentionally built to pass the same security checks run by the [aws-security-audit-scripts](https://github.com/cybergrizz/AWS-Scanner_Proj) scanner — no open SSH, SSM-only access, KMS-encrypted CloudTrail logs, GuardDuty enabled, and S3 buckets with public access fully blocked.

The end state ties scanner findings to NIST AI RMF control categories (Govern / Map / Measure / Manage) stored in DynamoDB, making this a working GRC demo rather than a static architecture diagram.

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

Observability
├── CloudTrail → S3 (KMS encrypted, public access blocked)
└── GuardDuty  → S3 data event protection enabled
```

Both EC2 instances use AWS Systems Manager Session Manager for shell access. No key pairs are created and port 22 is intentionally absent from all security groups — the infrastructure passes its own `ec2-port22-open.sh` audit check by design.

---

## File Structure

```
.
├── providers.tf    # AWS provider config and Terraform version constraints
├── vpc.tf          # VPC, public and private subnets
├── gateways.tf     # Internet gateway, NAT gateway, Elastic IP
├── routes.tf       # Route tables and associations (public → IGW, private → NAT)
├── sg.tf           # Security groups (Minecraft server, bastion)
├── ec2.tf          # EC2 instances and AMI data source
├── iam.tf          # SSM instance role, policy attachment, instance profile
├── cloudtrail.tf   # CloudTrail trail, S3 bucket policy, KMS key and policy
├── guardduty.tf    # GuardDuty detector and S3 protection feature
├── s3.tf           # S3 bucket for CloudTrail logs, public access block
├── outputs.tf      # Instance IDs and NAT gateway IP
├── data.tf         # Data Resources
└── var.tf          # All input variables
```

---

## Resources Deployed

### Networking — `vpc.tf` / `gateways.tf` / `routes.tf`

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

DNS support and DNS hostnames are both enabled on the VPC — required for SSM agent endpoint resolution.

### Security Groups — `sg.tf`

| Group | Ingress | Egress |
|-------|---------|--------|
| `Minecraft Server SG` | Port 25565 TCP + UDP from `0.0.0.0/0` | All traffic |
| `Bastion SG` | None | All traffic |

Port 22 is intentionally absent. The `ec2-port22-open.sh` scanner check passes by design.

### Compute — `ec2.tf`

AMI is resolved dynamically via data source — always the latest Amazon Linux 2 HVM x86_64 image.

| Instance | ID | Type | Subnet |
|----------|----|------|--------|
| `minecraft-server` | `i-0eff1395e4a3d3816` | t3.medium | Public |
| `bastion` | `i-03e979ed2a8bcb4d9` | t3.medium | Private |

### IAM — `iam.tf`

| Resource | Purpose |
|----------|---------|
| `aws_iam_role.ssm_instance_role` | EC2 trust policy for SSM access |
| `aws_iam_role_policy_attachment.ssm_core` | Attaches `AmazonSSMManagedInstanceCore` |
| `aws_iam_instance_profile.ssm_profile` | Binds role to both EC2 instances |

### Observability — `cloudtrail.tf` / `guardduty.tf` / `s3.tf`

| Resource | Details |
|----------|---------|
| CloudTrail | `minecraft_cloudtrail` — logs to S3, KMS encrypted, global service events enabled |
| KMS key | `minecraft-cloudtrail-key` — customer-managed, CloudTrail encrypt/describe permissions |
| S3 bucket | `minecraft-nist-cloudtrail-logs` — CloudTrail log storage |
| S3 public access block | All four block settings enabled |
| S3 bucket policy | Least-privilege CloudTrail write access with source ARN conditions |
| GuardDuty detector | Enabled in us-east-1, imported from existing account detector |
| GuardDuty S3 protection | `S3_DATA_EVENTS` feature enabled |

These resources are the direct targets of the following scanner checks — all expected to pass:
- `cloudtrail-enabled.sh`
- `cloudtrail-log-encryption.sh`
- `guardduty-enabled.sh`
- `s3-block-public-access.sh`
- `s3-bucket-encryption.sh`

---

## Prerequisites

- Terraform `>= 1.1.0`
- AWS CLI configured (`aws configure`)
- AWS provider `>= 5.40`
- Session Manager plugin installed (required for SSM shell access)
- IAM permissions to create VPC, EC2, IAM, KMS, S3, CloudTrail, and GuardDuty resources

---

## Usage

```bash
terraform init
terraform plan
terraform apply
```

View deployed resource IDs:

```bash
terraform output
```

Connect to instances via SSM (no SSH required):

```bash
aws ssm start-session --target <instance-id> --region us-east-1
```

Install the Session Manager plugin if not already installed (Windows):

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

## Scanner Audit Coverage

Checks from [aws-security-audit-scripts](https://github.com/cybergrizz/AWS-Scanner_Proj) and their expected result against this infrastructure:

| Check | Expected Result |
|-------|----------------|
| `cloudtrail-enabled.sh` | ✅ Pass |
| `cloudtrail-log-encryption.sh` | ✅ Pass |
| `guardduty-enabled.sh` | ✅ Pass |
| `s3-block-public-access.sh` | ✅ Pass |
| `s3-bucket-encryption.sh` | ✅ Pass |
| `ec2-port22-open.sh` | ✅ Pass |
| `ec2-port3389-open.sh` | ✅ Pass |
| `iam-root-mfa.sh` | Depends on account config |
| `iam-no-mfa.sh` | Depends on account config |
| `iam-old-access-keys.sh` | Depends on account config |

---

## What's Coming Next

- SSM Parameter Store (Slack webhook, scan credentials)
- Lambda function wrapping `scanner.sh`
- EventBridge scheduled scan trigger
- DynamoDB table for NIST AI RMF control mappings
- Full NIST AI RMF control coverage map (Govern / Map / Measure / Manage)
- VPC endpoints for SSM (keep SSM traffic off the public internet)

---

## Related Project

**[aws-security-audit-scripts](https://github.com/cybergrizz/AWS-Scanner_Proj)** — the Bash-based scanner that audits this infrastructure across IAM, S3, EC2, RDS, ELB, CloudTrail, and GuardDuty. The two repos are designed to work together: this is the target environment, the scanner is the audit engine.

---

## Author

**Kevin Douglas**  
Cloud Security Engineer · Vienna, VA  
🌐 [kdresume.link](https://kdresume.link) · 🐙 [github.com/cybergrizz](https://github.com/cybergrizz)

---

## License

MIT — use freely, contribute back if you improve it.
