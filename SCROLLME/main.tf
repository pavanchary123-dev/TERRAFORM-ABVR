# ============================================================
# PROVIDER
# ============================================================
provider "aws" {
  region = var.aws_region
}

# ============================================================
# DATA SOURCE — Default VPC (already exists in your account)
# ============================================================
# Your current VPC is the AWS default VPC.
# We import it as a data source so Terraform manages resources
# inside it without recreating the VPC itself.
data "aws_vpc" "default" {
  default = true
}

# ============================================================
# SUBNETS — Data sources (default subnets, already exist)
# ============================================================
data "aws_subnet" "ap_south_1a" {
  filter {
    name   = "availabilityZone"
    values = ["ap-south-1a"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "ap_south_1b" {
  filter {
    name   = "availabilityZone"
    values = ["ap-south-1b"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "ap_south_1c" {
  filter {
    name   = "availabilityZone"
    values = ["ap-south-1c"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ============================================================
# SECURITY GROUP — EC2 (currently named "default")
# ============================================================
resource "aws_security_group" "ec2_sg" {
  name        = "scrollme-ec2-sg"
  description = "Security group for SCROLLME EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH — restricted to known IPs
  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "scrollme-ec2-sg"
    Project = "Scrollme"
  }
}

# ============================================================
# SECURITY GROUP — RDS
# ============================================================
resource "aws_security_group" "rds_sg" {
  name        = "RDS-SG"
  description = "Allows requests from instance only"
  vpc_id      = data.aws_vpc.default.id

  # PostgreSQL from EC2 security group (recommended)
  ingress {
    description     = "PostgreSQL from EC2 instance"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # PostgreSQL from specific known IPs
  ingress {
    description = "PostgreSQL from allowed IPs"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.rds_allowed_ips
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "RDS-SG"
    Project = "Scrollme"
  }
}

# ============================================================
# KEY PAIR
# ============================================================
# NOTE: Terraform manages the key pair reference only.
# The actual .pem private key must already exist locally.
# To import: terraform import aws_key_pair.scrollme SCROLME
resource "aws_key_pair" "scrollme" {
  key_name   = "SCROLME"
  public_key = file("~/.ssh/SCROLME.pub")   # Update path to your public key file
}

# ============================================================
# EC2 INSTANCE — SCROLLME
# ============================================================
resource "aws_instance" "scrollme" {
  ami                    = "ami-07a00cf47dbbc844c"
  instance_type          = "c7i-flex.large"
  key_name               = aws_key_pair.scrollme.key_name
  subnet_id              = data.aws_subnet.ap_south_1a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  availability_zone      = "ap-south-1a"
  tenancy                = "default"
  ebs_optimized          = true

  # Root EBS volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 15
    iops                  = 3000
    throughput            = 125
    encrypted             = false   # NOTE: Consider setting to true for security
    delete_on_termination = true
  }

  monitoring = false

  tags = {
    Name    = "SCROLLME"
    Project = "Scrollme"
  }
}

# ============================================================
# ELASTIC IP — EC2 (associated)
# ============================================================
resource "aws_eip" "scrollme_ec2" {
  domain   = "vpc"

  tags = {
    Name    = "scrollme-ec2-eip"
    Project = "Scrollme"
  }
}

resource "aws_eip_association" "scrollme_ec2" {
  instance_id   = aws_instance.scrollme.id
  allocation_id = aws_eip.scrollme_ec2.id
}

# ============================================================
# ELASTIC IP — Spare / Unassociated (3.7.14.102)
# ============================================================
# NOTE: This EIP is currently unassociated and incurring charges.
# Remove this block if you no longer need it.
resource "aws_eip" "scrollme_spare" {
  domain = "vpc"

  tags = {
    Name    = "scrollme-spare-eip"
    Project = "Scrollme"
  }
}

# ============================================================
# RDS — DB Subnet Group
# ============================================================
resource "aws_db_subnet_group" "scrollme" {
  name        = "scrollme-db-subnet-group"
  description = "Subnet group for Scrollme RDS instance"
  subnet_ids  = [
    data.aws_subnet.ap_south_1a.id,
    data.aws_subnet.ap_south_1b.id,
    data.aws_subnet.ap_south_1c.id,
  ]

  tags = {
    Name    = "scrollme-db-subnet-group"
    Project = "Scrollme"
  }
}

# ============================================================
# RDS — PostgreSQL Instance
# ============================================================
resource "aws_db_instance" "scrollme" {
  identifier              = "srcollmedb-instance"
  engine                  = "postgres"
  engine_version          = "18.3"
  instance_class          = "db.t3.micro"

  db_name                 = "Scrollme_DB"
  username                = "Scrollmeuser"
  password                = var.rds_master_password

  allocated_storage       = 20
  storage_type            = "gp2"
  storage_encrypted       = true

  multi_az                = false
  publicly_accessible     = true   # NOTE: Consider setting to false for security
  port                    = 5432

  db_subnet_group_name    = aws_db_subnet_group.scrollme.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  parameter_group_name    = "default.postgres18"

  backup_retention_period = 1
  skip_final_snapshot     = false
  final_snapshot_identifier = "srcollmedb-final-snapshot"
  deletion_protection     = true

  auto_minor_version_upgrade        = true
  performance_insights_enabled      = true
  performance_insights_retention_period = 7

  tags = {
    Name    = "srcollmedb-instance"
    Project = "Scrollme"
  }
}

# ============================================================
# S3 BUCKET — scrollme-bucket
# ============================================================
resource "aws_s3_bucket" "scrollme" {
  bucket = "scrollme-bucket"

  tags = {
    Name    = "scrollme-bucket"
    Project = "Scrollme"
  }
}

resource "aws_s3_bucket_versioning" "scrollme" {
  bucket = aws_s3_bucket.scrollme.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scrollme" {
  bucket = aws_s3_bucket.scrollme.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "scrollme" {
  bucket = aws_s3_bucket.scrollme.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
