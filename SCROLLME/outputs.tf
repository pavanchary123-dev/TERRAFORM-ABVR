output "ec2_instance_id" {
  description = "SCROLLME EC2 Instance ID"
  value       = aws_instance.scrollme.id
}

output "ec2_public_ip" {
  description = "Elastic IP associated with SCROLLME"
  value       = aws_eip.scrollme_ec2.public_ip
}

output "ec2_private_ip" {
  description = "Private IP of SCROLLME"
  value       = aws_instance.scrollme.private_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.scrollme.endpoint
}

output "rds_db_name" {
  description = "RDS database name"
  value       = aws_db_instance.scrollme.db_name
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.scrollme.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.scrollme.arn
}

output "ec2_sg_id" {
  description = "EC2 Security Group ID"
  value       = aws_security_group.ec2_sg.id
}

output "rds_sg_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds_sg.id
}

output "vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}
