# WordPress Development Infrastructure

This Terraform configuration creates a complete AWS infrastructure for a WordPress development environment with the following components:

## Infrastructure Overview

- **4 Ubuntu EC2 instances** (t3.medium) distributed across 2 availability zones
- **Application Load Balancer** for traffic distribution
- **VPC with public and private subnets** for network isolation
- **S3 bucket** for shared storage accessible by all instances
- **IAM roles and policies** for secure access
- **Security groups** with least privilege access
- **Systems Manager (SSM)** for instance management

## Architecture

```
Internet Gateway
       |
   Public Subnets (ALB)
       |
   Private Subnets (EC2 Instances)
       |
   NAT Gateway (for outbound traffic)
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **AWS Account** with appropriate permissions

## Required AWS Permissions

Your AWS credentials need the following permissions:
- EC2 full access (for instances, VPC, security groups)
- IAM management (for roles and policies)
- S3 management (for bucket creation)
- Application Load Balancer management

## Deployment Instructions

### 1. Clone and Navigate
```bash
cd output/
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review and Customize Variables (Optional)
Edit `variables.tf` to customize:
- AWS region (default: us-east-2)
- Instance types (default: t3.medium)
- Storage sizes (default: 50GB root, 100GB data)
- CIDR blocks for VPC and subnets

### 4. Plan the Deployment
```bash
terraform plan
```

### 5. Deploy the Infrastructure
```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

## Post-Deployment

### Access Your Application
After deployment, you can access your application using the load balancer DNS name:
```bash
# Get the application URL
terraform output application_url
```

### Connect to Instances via SSM
```bash
# Get SSM connection commands for all instances
terraform output ssm_connect_commands

# Connect to a specific instance (replace INSTANCE_ID)
aws ssm start-session --target INSTANCE_ID --region us-east-2
```

### Test S3 Access
Once connected to an instance via SSM:
```bash
# Test S3 access
sudo /opt/s3-config/test-s3-access.sh

# View S3 bucket information
sudo cat /opt/s3-config/bucket-info
```

### Verify LVM Setup
Check the additional 100GB volume mounted at /opt:
```bash
# Check mount
df -h /opt

# Check LVM configuration
sudo vgs
sudo lvs
```

## Key Features

### Security
- **No SSH keys required** - access via SSM Session Manager
- **Private instances** - no direct internet access
- **Security groups** with minimal required permissions
- **Encrypted EBS volumes**
- **IMDSv2 enforced** for instance metadata

### High Availability
- **Multi-AZ deployment** across 2 availability zones
- **Application Load Balancer** with health checks
- **2 instances per AZ** for redundancy

### Storage
- **S3 bucket** with versioning and encryption
- **100GB LVM volume** mounted at /opt on each instance
- **IAM policies** for secure S3 access

### Monitoring
- **CloudWatch agent** installed on all instances
- **Detailed monitoring** enabled
- **Health checks** via load balancer

## Customization

### Adding SSL Certificate
To add HTTPS support with a real SSL certificate:

1. Create an ACM certificate:
```bash
aws acm request-certificate --domain-name your-domain.com --validation-method DNS
```

2. Update `load-balancer.tf` to use the certificate:
```hcl
resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "arn:aws:acm:us-east-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }
}
```

### Scaling Instances
To change the number of instances:
1. Modify `instance_count_per_az` in `variables.tf`
2. Run `terraform plan` and `terraform apply`

### Adding Auto Scaling
For production workloads, consider implementing:
- Auto Scaling Groups
- Launch Templates
- CloudWatch alarms for scaling triggers

## Cost Optimization

For development environments:
- **Instance types**: Use t3.micro or t3.small for cost savings
- **EBS volumes**: Use gp3 for better price/performance
- **Scheduling**: Consider stopping instances outside business hours

## Cleanup

To destroy the infrastructure and avoid ongoing costs:
```bash
terraform destroy
```

Type `yes` when prompted to confirm destruction.

## Troubleshooting

### Instance Connection Issues
1. Verify SSM agent is running
2. Check IAM role permissions
3. Ensure instances are in private subnets with NAT Gateway access

### Load Balancer Health Check Failures
1. Check security group rules
2. Verify nginx is running on instances
3. Test health check endpoint: `curl http://INSTANCE_IP/health`

### S3 Access Issues
1. Verify IAM role and policies
2. Check S3 bucket policies
3. Test with AWS CLI: `aws s3 ls s3://BUCKET_NAME`

## Support

For issues with this infrastructure:
1. Check AWS CloudWatch logs
2. Review Terraform state and output
3. Verify AWS service limits and quotas

## Tags

All resources are tagged with:
- **Environment**: development
- **Project**: wordpress
- **Owner**: Zach
- **ManagedBy**: terraform