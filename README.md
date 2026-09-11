# 🚀 Scrollme AWS Infrastructure — Terraform

This repository contains the complete Infrastructure as Code (IaC) for the **Scrollme** application hosted on AWS (Mumbai region — `ap-south-1`), managed using **Terraform**.

---

## 📁 Repository Structure

```text
scrollme-infra/
├── main.tf              # All AWS resources
├── variables.tf         # Input variable declarations
├── outputs.tf           # Output values after apply
├── terraform.tfvars     # Variable values (do NOT commit secrets)
├── versions.tf          # Terraform & provider version constraints
└── README.md            # This file
```

---

## ☁️ Infrastructure Overview

| Service | Resource Name | Details |
|---|---|---|
| **VPC** | Default VPC | `172.31.0.0/16` — ap-south-1 |
| **Subnets** | 3 Default Subnets | ap-south-1a / 1b / 1c — all public |
| **Internet Gateway** | `igw-02d8ecbbbc6768b97` | Attached to default VPC |
| **Route Table** | Main Route Table | `0.0.0.0/0 → IGW` |
| **EC2 Instance** | `SCROLLME` | `c7i-flex.large` — ap-south-1a |
| **AMI** | `ami-07a00cf47dbbc844c` | Ubuntu / Custom |
| **EBS Volume** | Root Volume | 15 GiB `gp3`, 3000 IOPS, 125 MB/s |
| **Key Pair** | `SCROLME` | RSA key pair |
| **Security Group (EC2)** | `scrollme-ec2-sg` | HTTP 80, HTTPS 443, SSH restricted |
| **Security Group (RDS)** | `RDS-SG` | PostgreSQL 5432 — restricted IPs only |
| **Elastic IP (EC2)** | `65.2.103.175` | Associated with SCROLLME instance |
| **Elastic IP (Spare)** | `3.7.14.102` | Unassociated — review if needed |
| **RDS** | `srcollmedb-instance` | PostgreSQL 18.3 — `db.t3.micro` |
| **S3 Bucket** | `scrollme-bucket` | Versioning + AES256 encryption enabled |

---

## 🗺️ Architecture Diagram

```text
                    Internet
                       │
                ┌──────▼──────┐
                │  Route 53   │  (if applicable)
                └──────┬──────┘
                       │
                ┌──────▼──────┐
                │  Elastic IP │  65.2.103.175
                └──────┬──────┘
                       │
          ┌────────────▼────────────┐
          │   Default VPC           │
          │   172.31.0.0/16         │
          │                         │
          │  ┌──────────────────┐   │
          │  │  ap-south-1a     │   │
          │  │  172.31.32.0/20  │   │
          │  │                  │   │
          │  │  ┌────────────┐  │   │
          │  │  │  SCROLLME  │  │   │
          │  │  │ EC2 Instance│  │   │
          │  │  │c7i-flex.large│ │   │
          │  │  └─────┬──────┘  │   │
          │  └────────┼─────────┘   │
          │           │             │
          │  ┌────────▼─────────┐   │
          │  │   RDS-SG         │   │
          │  │  srcollmedb      │   │
          │  │  PostgreSQL 18.3 │   │
          │  │  db.t3.micro     │   │
          │  └──────────────────┘   │
          │                         │
          └─────────────────────────┘
                       │
                ┌──────▼──────┐
                │  S3 Bucket  │
                │scrollme-    │
                │  bucket     │
                └─────────────┘
```

---

## ⚙️ Prerequisites

Before you begin, make sure you have the following installed:

| Tool | Version | Install |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.5.0 | `brew install terraform` |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | >= 2.x | `brew install awscli` |
| [Git](https://git-scm.com/) | Any | `brew install git` |

---

## 🔐 AWS Authentication

Configure your AWS credentials before running Terraform:

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `ap-south-1`
- Default output format: `json`

Or use an AWS profile:
```bash
export AWS_PROFILE=your-profile-name
```

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/scrollme-infra.git
cd scrollme-infra
```

### 2. Set Your Variables
Copy the example configuration and populate your secrets:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region          = "ap-south-1"
rds_master_password = "YOUR_STRONG_PASSWORD_HERE"
```

> ⚠️ **Warning:** Never commit `terraform.tfvars` to Git. It is already included in `.gitignore`.

### 3. Add Your SSH Public Key
Update the `public_key` path in `main.tf` under `aws_key_pair.scrollme`:
```hcl
public_key = file("~/.ssh/SCROLME.pub")
```

### 4. Initialize Terraform
```bash
terraform init
```

### 5. Import Existing AWS Resources
Since this infrastructure already exists in AWS, import it into the Terraform state:
```bash
terraform import aws_key_pair.scrollme SCROLME
terraform import aws_instance.scrollme i-0002540b4287f2927
terraform import aws_eip.scrollme_ec2 eipalloc-0f17c944c9c48feff
terraform import aws_eip.scrollme_spare eipalloc-0110e13fda51b72aa
terraform import aws_security_group.ec2_sg sg-07ef16b4413f4aa35
terraform import aws_security_group.rds_sg sg-0bb3c1f5f660ea5b5
terraform import aws_db_instance.scrollme srcollmedb-instance
terraform import aws_s3_bucket.scrollme scrollme-bucket
```

### 6. Plan — Review Changes
```bash
terraform plan
```
Review the output carefully. There should be no destructive changes if the import was successful.

### 7. Apply
```bash
terraform apply
```
Type `yes` when prompted.

---

## 📤 Outputs

After a successful `terraform apply`, the following values are printed:

| Output | Description |
|---|---|
| `ec2_instance_id` | SCROLLME EC2 Instance ID |
| `ec2_public_ip` | Elastic IP associated with SCROLLME |
| `ec2_private_ip` | Private IP of SCROLLME |
| `rds_endpoint` | RDS PostgreSQL connection endpoint |
| `rds_db_name` | RDS database name |
| `s3_bucket_name` | S3 bucket name |
| `s3_bucket_arn` | S3 bucket ARN |
| `ec2_sg_id` | EC2 Security Group ID |
| `rds_sg_id` | RDS Security Group ID |
| `vpc_id` | Default VPC ID |

---

## 🔒 Security Notes

| # | Finding | Status |
|---|---|---|
| 1 | RDS `0.0.0.0/0` on port 5432 | ✅ Removed in Terraform — restricted to known IPs + EC2 SG |
| 2 | SSH access on EC2 | ✅ Restricted to 4 specific IP addresses |
| 3 | RDS storage encryption | ✅ Enabled |
| 4 | S3 public access block | ✅ Enabled — all public access blocked |
| 5 | S3 server-side encryption | ✅ AES256 enabled |
| 6 | S3 versioning | ✅ Enabled |
| 7 | EBS root volume encryption | ⚠️ Currently disabled — consider enabling |
| 8 | Spare Elastic IP (`3.7.14.102`) | ⚠️ Unassociated — incurring charges, review if needed |
| 9 | RDS publicly accessible | ⚠️ Set to `true` — consider setting to `false` |
| 10 | RDS backup retention | ⚠️ Only 1 day — consider increasing to 7+ days |

---

## 🗂️ Resource Details

### EC2 Instance — SCROLLME
| Property | Value |
|---|---|
| **Instance ID** | `i-0002540b4287f2927` |
| **Instance Type** | `c7i-flex.large` |
| **AMI** | `ami-07a00cf47dbbc844c` |
| **Availability Zone** | `ap-south-1a` |
| **Public IP (EIP)** | `65.2.103.175` |
| **Private IP** | `172.31.39.205` |
| **Key Pair** | `SCROLME` |
| **EBS Volume** | 15 GiB gp3 — 3000 IOPS — 125 MB/s |

### RDS — srcollmedb-instance
| Property | Value |
|---|---|
| **Engine** | PostgreSQL 18.3 |
| **Instance Class** | `db.t3.micro` |
| **Database Name** | `Scrollme_DB` |
| **Master Username** | `Scrollmeuser` |
| **Storage** | 20 GiB gp2 |
| **Encrypted** | Yes |
| **Multi-AZ** | No |
| **Deletion Protection**| Yes |
| **Endpoint** | `srcollmedb-instance.ctisscwoc8yb.ap-south-1.rds.amazonaws.com:5432` |

### S3 Bucket — scrollme-bucket
| Property | Value |
|---|---|
| **Bucket Name** | `scrollme-bucket` |
| **Region** | `ap-south-1` |
| **Versioning** | Enabled |
| **Encryption** | AES256 (SSE-S3) |
| **Public Access** | Fully blocked |

---

## 🧹 Destroying Infrastructure

> ⚠️ **WARNING:** This will permanently delete all resources. Use with extreme caution.

```bash
terraform destroy
```

> **Note:** RDS has `deletion_protection = true` — you must disable it first before destroy will succeed:

```bash
# Temporarily disable deletion protection
terraform apply -var="deletion_protection=false"
terraform destroy
```

---

## 📦 .gitignore

Make sure your `.gitignore` includes:

```gitignore
# Terraform state files — never commit these
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl

# Variable files with secrets
terraform.tfvars
*.auto.tfvars

# SSH keys
*.pem
*.pub
```

---

## 🤝 Contributing

1. Create a new branch: `git checkout -b feature/your-change`
2. Make your changes
3. Run `terraform fmt` to format code
4. Run `terraform validate` to validate syntax
5. Run `terraform plan` to preview changes
6. Open a Pull Request

---

## 📞 Support

For infrastructure issues, check:
- [AWS Console — Mumbai](https://ap-south-1.console.aws.amazon.com/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Health Dashboard / Status](https://health.aws.amazon.com/)

---
*Infrastructure managed with ❤️ using Terraform — AWS Mumbai (`ap-south-1`)*
