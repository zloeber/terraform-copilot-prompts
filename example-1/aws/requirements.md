# WordPress Development Infrastructure Requirements

## Overview
This document outlines the comprehensive requirements for setting up a WordPress development infrastructure on AWS using Terraform.

## Core Requirements (User Specified)
- **Virtual Machines**: 4 Ubuntu Linux VMs
- **Distribution**: Spread across 2 availability zones in the same AWS account and region
- **Network**: Internal-only network (no direct internet access)
- **Web Services**: nginx running on ports 80 and 443
- **Instance Size**: t3.medium
- **Region**: us-east-2
- **Ubuntu Version**: Latest available Ubuntu AMI
- **Storage Requirements**:
  - Root volumes: 50GB each
  - Additional LVM volume: 100GB mounted at /opt on each VM
- **Load Balancing**: Application Load Balancer for traffic distribution
- **Management Access**: AWS Systems Manager (SSM) Session Manager
- **Environment**: Development
- **Project Name**: wordpress
- **Owner**: Zach
- **Storage**: S3 bucket accessible by all VMs for read/write operations

## Infrastructure Components (Inferred Requirements)

### Network Architecture
- **VPC**: Custom VPC with proper CIDR allocation
- **Availability Zones**: us-east-2a and us-east-2b
- **Subnets**:
  - 2 Public subnets (one per AZ) for load balancer
  - 2 Private subnets (one per AZ) for EC2 instances
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: For private subnet outbound internet access
- **Route Tables**: Proper routing for public and private subnets

### Compute Resources
- **EC2 Instances**: 4 x t3.medium instances
- **AMI**: Latest Ubuntu 22.04 LTS (ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*)
- **Distribution**: 2 instances per availability zone
- **Instance Profile**: IAM role for SSM access and S3 permissions

### Storage
- **Root Volumes**: 50GB gp3 EBS volumes per instance
- **Additional Volumes**: 100GB gp3 EBS volumes per instance (mounted at /opt)
- **S3 Bucket**: Shared storage accessible by all VMs with appropriate permissions

### Load Balancing
- **Load Balancer Type**: Application Load Balancer (ALB)
- **Placement**: Public subnets across both availability zones
- **Target Group**: HTTP/HTTPS targets pointing to EC2 instances
- **Health Checks**: HTTP health checks on nginx

### Security
- **Security Groups**:
  - ALB Security Group: Allow HTTP/HTTPS from internet
  - EC2 Security Group: Allow HTTP/HTTPS from ALB only
  - S3 Access: IAM policies for read/write access
- **Access Management**: SSM-based access (no SSH keys required)

### Monitoring & Management
- **SSM**: Systems Manager for instance management
- **Instance Metadata**: IMDSv2 enforced for security
- **Tagging**: Comprehensive tagging strategy for resource management

## Security & Compliance Considerations
- **Network Isolation**: Private subnets with no direct internet access
- **Least Privilege**: IAM roles with minimal required permissions
- **Encryption**: EBS volumes encrypted at rest
- **Secure Access**: SSM Session Manager instead of SSH
- **Security Groups**: Restrictive rules allowing only necessary traffic

## Best Practices Implemented
- **High Availability**: Multi-AZ deployment
- **Scalability**: Load balancer ready for auto-scaling if needed
- **Security**: Defense in depth with multiple security layers
- **Monitoring**: CloudWatch integration via SSM
- **Cost Optimization**: Development environment optimized for cost
- **Infrastructure as Code**: Terraform for reproducible deployments

## Tags Applied to All Resources
- **Environment**: development
- **Project**: wordpress
- **Owner**: Zach
- **ManagedBy**: terraform