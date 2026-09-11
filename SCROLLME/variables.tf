variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "rds_master_password" {
  description = "Master password for RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_ips" {
  description = "List of CIDRs allowed to SSH into the EC2 instance"
  type        = list(string)
  default     = [
    "49.206.33.199/32",
    "14.99.136.186/32",
    "103.160.27.26/32",
    "59.182.63.151/32"
  ]
}

variable "rds_allowed_ips" {
  description = "List of CIDRs allowed to connect to RDS on port 5432"
  type        = list(string)
  default     = [
    "49.206.33.199/32",
    "103.160.27.36/32",
    "136.185.219.121/32"
    # NOTE: 0.0.0.0/0 has been intentionally removed — restrict to known IPs only
  ]
}
