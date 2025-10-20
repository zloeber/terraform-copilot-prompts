# Output values for the infrastructure

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for shared storage"
  value       = aws_s3_bucket.wordpress_storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.wordpress_storage.arn
}

output "web_server_instance_ids" {
  description = "Instance IDs of the web servers"
  value       = aws_instance.web_servers[*].id
}

output "web_server_private_ips" {
  description = "Private IP addresses of the web servers"
  value       = aws_instance.web_servers[*].private_ip
}

output "web_server_availability_zones" {
  description = "Availability zones of the web servers"
  value       = aws_instance.web_servers[*].availability_zone
}

output "security_group_alb_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "security_group_web_servers_id" {
  description = "ID of the web servers security group"
  value       = aws_security_group.web_servers.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# Access information
output "application_url" {
  description = "URL to access the application via load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ssm_connect_commands" {
  description = "Commands to connect to instances via SSM"
  value = {
    for i, instance in aws_instance.web_servers : "web-server-${i + 1}" => "aws ssm start-session --target ${instance.id} --region ${var.aws_region}"
  }
}