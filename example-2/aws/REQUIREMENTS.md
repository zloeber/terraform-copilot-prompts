# AWS EKS Infrastructure Requirements

## 📋 System Requirements

### Local Development Environment

| Tool | Minimum Version | Recommended Version | Purpose |
|------|----------------|-------------------|---------|
| **Terraform** | 1.0.0 | 1.6.0+ | Infrastructure provisioning |
| **AWS CLI** | 2.0.0 | 2.15.0+ | AWS service interaction |
| **kubectl** | 1.24.0 | 1.29.0+ | Kubernetes cluster management |
| **Docker** | 20.10.0 | 24.0.0+ | Container operations |
| **jq** | 1.6 | 1.7+ | JSON processing (optional) |

### Installation Commands

#### macOS (Homebrew)
```bash
# Install Terraform
brew install terraform

# Install AWS CLI
brew install awscli

# Install kubectl
brew install kubectl

# Install Docker Desktop
brew install --cask docker

# Install jq
brew install jq
```

#### Ubuntu/Debian
```bash
# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
sudo snap install kubectl --classic

# Install Docker
sudo apt update
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Install jq
sudo apt install jq
```

## ☁️ AWS Requirements

### Account Prerequisites

| Requirement | Description | Validation |
|-------------|-------------|------------|
| **AWS Account** | Active AWS account with billing enabled | `aws sts get-caller-identity` |
| **Admin Access** | IAM user/role with administrative permissions | See [IAM Permissions](#iam-permissions) |
| **Region Support** | Target region supports EKS and ECR | Check [AWS Regional Services](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/) |
| **Service Quotas** | Sufficient service limits | See [Service Quotas](#service-quotas) |

### AWS CLI Configuration

```bash
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity
aws eks list-clusters --region us-east-1
```

#### Environment Variables (Alternative)
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## 🔐 IAM Permissions

### Required IAM Policies

The deploying user/role needs these managed policies:

- `AmazonEKSClusterPolicy`
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`
- `CloudWatchAgentServerPolicy`

### Custom IAM Policy

<details>
<summary>Terraform Deployment Policy (Click to expand)</summary>

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EKSPermissions",
            "Effect": "Allow",
            "Action": [
                "eks:CreateCluster",
                "eks:DeleteCluster",
                "eks:DescribeCluster",
                "eks:ListClusters",
                "eks:UpdateClusterConfig",
                "eks:UpdateClusterVersion",
                "eks:CreateNodegroup",
                "eks:DeleteNodegroup",
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:UpdateNodegroupConfig",
                "eks:UpdateNodegroupVersion",
                "eks:CreateAddon",
                "eks:DeleteAddon",
                "eks:DescribeAddon",
                "eks:ListAddons",
                "eks:UpdateAddon",
                "eks:TagResource",
                "eks:UntagResource",
                "eks:ListTagsForResource"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2Permissions",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVpc",
                "ec2:DeleteVpc",
                "ec2:DescribeVpcs",
                "ec2:ModifyVpcAttribute",
                "ec2:CreateSubnet",
                "ec2:DeleteSubnet",
                "ec2:DescribeSubnets",
                "ec2:ModifySubnetAttribute",
                "ec2:CreateRouteTable",
                "ec2:DeleteRouteTable",
                "ec2:DescribeRouteTables",
                "ec2:AssociateRouteTable",
                "ec2:DisassociateRouteTable",
                "ec2:CreateRoute",
                "ec2:DeleteRoute",
                "ec2:CreateInternetGateway",
                "ec2:DeleteInternetGateway",
                "ec2:AttachInternetGateway",
                "ec2:DetachInternetGateway",
                "ec2:DescribeInternetGateways",
                "ec2:CreateNatGateway",
                "ec2:DeleteNatGateway",
                "ec2:DescribeNatGateways",
                "ec2:AllocateAddress",
                "ec2:ReleaseAddress",
                "ec2:DescribeAddresses",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:CreateVpcEndpoint",
                "ec2:DeleteVpcEndpoint",
                "ec2:DescribeVpcEndpoints",
                "ec2:ModifyVpcEndpoint",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMPermissions",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:ListRoles",
                "iam:PassRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicyVersions",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicyVersion",
                "iam:PutRolePolicy",
                "iam:GetRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:ListRolePolicies",
                "iam:TagRole",
                "iam:UntagRole",
                "iam:ListInstanceProfilesForRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ECRPermissions",
            "Effect": "Allow",
            "Action": [
                "ecr:CreateRepository",
                "ecr:DeleteRepository",
                "ecr:DescribeRepositories",
                "ecr:ListRepositories",
                "ecr:PutRepositoryPolicy",
                "ecr:GetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy",
                "ecr:PutLifecyclePolicy",
                "ecr:GetLifecyclePolicy",
                "ecr:DeleteLifecyclePolicy",
                "ecr:TagResource",
                "ecr:UntagResource",
                "ecr:ListTagsForResource",
                "ecr:PutImageScanningConfiguration",
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchPermissions",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:DeleteLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy",
                "logs:TagLogGroup",
                "logs:UntagLogGroup",
                "logs:ListTagsLogGroup",
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        },
        {
            "Sid": "STSPermissions",
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity",
                "sts:AssumeRole",
                "sts:TagSession"
            ],
            "Resource": "*"
        }
    ]
}
```

</details>

### IAM Role Trust Policy (for EC2/CodeBuild)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com",
                    "codebuild.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

## 📊 Service Quotas

### EKS Service Limits

| Resource | Default Limit | Recommended | Adjustable |
|----------|---------------|-------------|------------|
| **Clusters per Region** | 100 | 10+ | Yes |
| **Nodes per Cluster** | 450 | 100+ | No |
| **Pods per Node** | 110 (depends on instance type) | - | No |
| **Node Groups per Cluster** | 30 | 10+ | Yes |

### EC2 Service Limits

| Resource | Default Limit | Recommended | Adjustable |
|----------|---------------|-------------|------------|
| **VPCs per Region** | 5 | 10+ | Yes |
| **Subnets per VPC** | 200 | 50+ | Yes |
| **Security Groups per VPC** | 2,500 | 100+ | Yes |
| **NAT Gateways per AZ** | 5 | 3+ | Yes |
| **Elastic IPs** | 5 | 10+ | Yes |
| **VPC Endpoints per VPC** | 255 | 50+ | Yes |

### ECR Service Limits

| Resource | Default Limit | Recommended | Adjustable |
|----------|---------------|-------------|------------|
| **Repositories per Region** | 10,000 | 100+ | Yes |
| **Images per Repository** | 10,000 | 1,000+ | No |
| **Repository Size** | 10 TB | 100 GB+ | No |

### Check Current Quotas

```bash
# Check EKS quotas
aws service-quotas get-service-quota \
  --service-code eks \
  --quota-code L-1194D53C

# Check EC2 quotas
aws service-quotas list-service-quotas \
  --service-code ec2 \
  --query 'Quotas[?QuotaName==`Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances`]'

# Check ECR quotas
aws service-quotas list-service-quotas \
  --service-code ecr
```

### Request Quota Increases

```bash
# Request EKS cluster quota increase
aws service-quotas request-service-quota-increase \
  --service-code eks \
  --quota-code L-1194D53C \
  --desired-value 50

# Request EC2 instance quota increase
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 100
```

## 🌍 Regional Requirements

### Supported Regions

EKS is available in the following regions:
- **US East**: us-east-1, us-east-2
- **US West**: us-west-1, us-west-2
- **Europe**: eu-central-1, eu-west-1, eu-west-2, eu-west-3, eu-north-1
- **Asia Pacific**: ap-southeast-1, ap-southeast-2, ap-northeast-1, ap-northeast-2, ap-south-1
- **Canada**: ca-central-1
- **South America**: sa-east-1

### Regional Considerations

| Region | Considerations | Latency | Cost |
|--------|----------------|---------|------|
| **us-east-1** | Largest service selection, most AZs | Lowest for US East Coast | Baseline |
| **us-west-2** | Full service availability | Lowest for US West Coast | ~5% higher |
| **eu-west-1** | Full service availability | Lowest for Europe | ~10% higher |
| **ap-southeast-1** | Good for APAC | Lowest for Southeast Asia | ~15% higher |

### Availability Zone Requirements

- **Minimum**: 2 AZs (for high availability)
- **Recommended**: 3+ AZs (for fault tolerance)
- **Maximum**: All available AZs in region

```bash
# Check available AZs
aws ec2 describe-availability-zones \
  --region us-east-1 \
  --query 'AvailabilityZones[?State==`available`].ZoneName'
```

## 💾 Storage Requirements

### EBS Volume Types

| Volume Type | Use Case | IOPS | Throughput | Cost |
|-------------|----------|------|------------|------|
| **gp3** | General purpose (recommended) | 3,000-16,000 | 125-1,000 MB/s | Low |
| **gp2** | General purpose (legacy) | 100-16,000 | Up to 250 MB/s | Low |
| **io2** | High performance databases | 100-256,000 | Up to 4,000 MB/s | High |
| **st1** | Big data workloads | - | Up to 500 MB/s | Very Low |

### Node Storage Requirements

| Node Type | Disk Size | Volume Type | IOPS | Use Case |
|-----------|-----------|-------------|------|----------|
| **t3.medium** | 30 GB | gp3 | 3,000 | Development |
| **c5.large** | 50 GB | gp3 | 3,000 | Production |
| **m5.xlarge** | 100 GB | gp3 | 6,000 | High-performance |

## 🔧 Validation Scripts

### Pre-deployment Validation

```bash
#!/bin/bash
# validate-prerequisites.sh

echo "🔍 Validating prerequisites..."

# Check Terraform version
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    exit 1
fi

TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
echo "✅ Terraform version: $TERRAFORM_VERSION"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    exit 1
fi

AWS_VERSION=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
echo "✅ AWS CLI version: $AWS_VERSION"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account: $AWS_ACCOUNT"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

KUBECTL_VERSION=$(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')
echo "✅ kubectl version: $KUBECTL_VERSION"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi

DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
echo "✅ Docker version: $DOCKER_VERSION"

echo "🎉 All prerequisites validated successfully!"
```

### Post-deployment Validation

```bash
#!/bin/bash
# validate-deployment.sh

CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(terraform output -raw region || echo "us-east-1")

echo "🔍 Validating EKS deployment..."

# Check cluster status
CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.status' --output text)
if [ "$CLUSTER_STATUS" != "ACTIVE" ]; then
    echo "❌ Cluster is not active: $CLUSTER_STATUS"
    exit 1
fi
echo "✅ Cluster is active"

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Check nodes
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
if [ $NODE_COUNT -eq 0 ]; then
    echo "❌ No nodes found"
    exit 1
fi
echo "✅ Found $NODE_COUNT nodes"

# Check system pods
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers | wc -l)
echo "✅ System pods running: $SYSTEM_PODS"

# Check ECR repository
ECR_REPO=$(terraform output -raw ecr_repository_name)
if ! aws ecr describe-repositories --repository-names $ECR_REPO --region $REGION &> /dev/null; then
    echo "❌ ECR repository not found"
    exit 1
fi
echo "✅ ECR repository is available"

echo "🎉 Deployment validation successful!"
```

Make these scripts executable:
```bash
chmod +x validate-prerequisites.sh validate-deployment.sh
```

## 🚨 Common Issues

### Issue: Insufficient IAM Permissions
**Symptoms**: Terraform fails with "AccessDenied" errors
**Solution**: Ensure all required IAM policies are attached

### Issue: Service Quota Exceeded
**Symptoms**: "LimitExceeded" errors during resource creation
**Solution**: Request quota increases or deploy to different region

### Issue: Availability Zone Issues
**Symptoms**: Subnet creation fails
**Solution**: Verify AZ availability and adjust subnet configuration

### Issue: VPC Endpoint Issues
**Symptoms**: Pods can't access AWS services
**Solution**: Verify VPC endpoint configuration and security groups

### Issue: Node Group Launch Failures
**Symptoms**: Nodes fail to join cluster
**Solution**: Check IAM roles, security groups, and subnet routing

## 📞 Support Resources

- **AWS Support**: For quota increases and AWS-specific issues
- **Terraform Documentation**: [terraform.io](https://terraform.io)
- **EKS Best Practices**: [aws.github.io/aws-eks-best-practices](https://aws.github.io/aws-eks-best-practices)
- **Kubernetes Documentation**: [kubernetes.io](https://kubernetes.io)

---

**Last Updated**: $(date)  
**Document Version**: 1.0.0