# Minecraft-NIST-Demo — AWS Infrastructure

> Terraform infrastructure for a Minecraft server environment mapped to the NIST AI Risk Management Framework. Built as a live compliance demo that audits its own infrastructure.

**Author:** [Kevin Douglas](https://github.com/cybergrizz) · [kdresume.link](https://kdresume.link) · Vienna, VA  
**Focus:** Cloud Security · GRC · IaC · NIST AI RMF

> ⚠️ **Status:** In progress — networking and compute layer active. SSM integration, DynamoDB, EventBridge, and scanner wiring coming next.

---

## Overview

This project provisions a Minecraft game server on AWS and uses it as a live compliance target. The infrastructure is intentionally built to pass the same security checks run by the [aws-security-audit-scripts](https://github.com/cybergrizz) scanner — no open SSH, SSM-only access, locked-down security groups, and consistent resource tagging throughout.

The end state ties scanner findings to NIST AI RMF control categories (Govern / Map / Measure / Manage) stored in DynamoDB, making this a working GRC demo rather than a static architecture diagram.

---

## Architecture

```
VPC: 10.0.0.0/16 (us-east-1a)
│
├── Public subnet: 10.0.1.0/24
│   └── EC2: Minecraft server (t3.medium, Amazon Linux 2)
│       └── SG: port 25565 TCP/UDP inbound — no port 22
│
└── Private subnet: 10.0.2.0/24
    └── EC2: Bastion / management node (t3.medium, Amazon Linux 2)
        └── SG: egress only — no public ingress
```

Both EC2 instances use AWS Systems Manager Session Manager for shell access. No key pairs are created, and port 22 is intentionally absent from all security groups — the infrastructure passes its own `ec2-port22-open.sh` audit check by design.

---

## File Structure

```
.
├── providers.tf   # AWS provider config and Terraform version constraints
├── vpc.tf         # VPC, public subnet, private subnet
├── sg.tf          # Security groups (Minecraft server, bastion)
├── ec2.tf         # EC2 instances and AMI data source
├── iam.tf         # SSM instance role, policy attachment, instance profile
└── var.tf         # All input variables
```

---

## Resources Built

### Networking — `vpc.tf`

| Resource | Name | Value |
|----------|------|-------|
| VPC | `minecraft-nist-vpc` | `10.0.0.0/16` |
| Public subnet | `minecraft-public-subnet` | `10.0.1.0/24` — us-east-1a |
| Private subnet | `minecraft-private-subnet` | `10.0.2.0/24` — us-east-1a |

DNS support and DNS hostnames are both enabled on the VPC — required for SSM agent endpoint resolution. Without these, instances silently fail to register with Systems Manager.

### Security Groups — `sg.tf`

| Group | Ingress | Egress |
|-------|---------|--------|
| `minecraft-server-sg` | Port 25565 TCP + UDP from `0.0.0.0/0` | All traffic |
| `bastion-sg` | None | All traffic |

The absence of port 22 ingress on both groups is intentional. The `aws-security-audit-scripts` scanner flags any security group with SSH open to the world — this infrastructure is built to pass that check.

### Compute — `ec2.tf`

Both instances resolve their AMI dynamically via a `data` source filtering for the latest Amazon Linux 2 HVM x86_64 image, so the AMI ID never goes stale across regions or over time.

| Instance | Resource Name | Type | Subnet |
|----------|--------------|------|--------|
| Minecraft server | `minecrafte_server` | t3.medium | Public |
| Bastion | `bastion` | t3.medium | Private |

Both instances are assigned the SSM instance profile, enabling Session Manager access without opening any inbound ports.

### IAM — `iam.tf`

| Resource | Purpose |
|----------|---------|
| `aws_iam_role.ssm_instance_role` | EC2 trust policy allowing SSM access |
| `aws_iam_role_policy_attachment.ssm_core` | Attaches `AmazonSSMManagedInstanceCore` managed policy |
| `aws_iam_instance_profile.ssm_profile` | Binds the role to EC2 instances |

`AmazonSSMManagedInstanceCore` is the minimum permission set for Session Manager, Run Command, and Parameter Store read access.

---

## Prerequisites

- Terraform `>= 1.1.0`
- AWS CLI configured (`aws configure`)
- AWS provider `>= 5.40`
- IAM permissions to create VPC, EC2, IAM, and SSM resources

---

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Connecting to instances via SSM (no SSH required):

```bash
# Get instance IDs after apply
terraform output

# Start a session
aws ssm start-session --target <instance-id> --region us-east-1
```

---

## What's Coming Next

- Internet gateway, route tables, NAT gateway
- VPC endpoints for SSM (keeps SSM traffic off the public internet)
- SSM Parameter Store (Slack webhook, scan credentials)
- Lambda function wrapping `scanner.sh`
- EventBridge scheduled scan trigger
- DynamoDB table for NIST AI RMF control mappings
- CloudTrail and GuardDuty enablement
- S3 bucket for scan report storage
- Full NIST AI RMF control coverage map

---

## Related Project

**[aws-security-audit-scripts](https://github.com/cybergrizz)** — the Bash-based scanner that audits this infrastructure across IAM, S3, EC2, RDS, ELB, CloudTrail, and GuardDuty. The two repos are designed to work together: this is the target environment, the scanner is the audit engine.

---

## Author

**Kevin Douglas**  
Cloud Security Engineer · Vienna, VA  
🌐 [kdresume.link](https://kdresume.link) · 🐙 [github.com/cybergrizz](https://github.com/cybergrizz)

---

## License

MIT — use freely, contribute back if you improve it.
