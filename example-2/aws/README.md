# AWS EKS Private Cluster with ECR

This Terraform configuration creates a private Amazon Elastic Kubernetes Service (EKS) cluster with Elastic Container Registry (ECR) integration, designed for secure, production-ready workloads.

## 🏗️ Architecture Overview

This infrastructure creates:

- **Private EKS Cluster**: Kubernetes control plane with private API endpoint
- **VPC with Private Networking**: Custom VPC with public and private subnets across multiple AZs
- **ECR Integration**: Fully managed container registry with vulnerability scanning
- **VPC Endpoints**: Private connectivity to AWS services (EKS, ECR, S3, CloudWatch)
- **Managed Node Groups**: Auto-scaling worker nodes with separate system and application pools
- **Security Groups**: Network security with least privilege access
- **CloudWatch Logging**: Comprehensive cluster and application monitoring

### Network Architecture

```
┌─────────────────── VPC (10.0.0.0/16) ──────────────────┐
│                                                         │
│  ┌── Public Subnets ──┐    ┌── Private Subnets ──┐     │
│  │  - NAT Gateways    │    │  - EKS Nodes        │     │
│  │  - Load Balancers  │    │  - VPC Endpoints    │     │
│  │  - Bastion Hosts   │    │  - Application Pods │     │
│  └────────────────────┘    └─────────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- **Terraform**: Version >= 1.0
- **AWS CLI**: Version >= 2.0, configured with appropriate credentials
- **kubectl**: For cluster management
- **AWS IAM Permissions**: See [Required Permissions](#required-permissions) section

## 🚀 Quick Start

### 1. Clone and Navigate
```bash
cd path/to/aws-infrastructure
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Plan Deployment
```bash
terraform plan
```

### 4. Deploy Infrastructure
```bash
terraform apply
```

### 5. Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name $(terraform output -raw cluster_name)
```

### 6. Verify Cluster
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## ⚙️ Configuration

### Key Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `region` | AWS region | `us-east-1` | No |
| `resource_prefix` | Prefix for resource names | `eks-demo` | No |
| `environment` | Environment name | `dev` | No |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | No |
| `kubernetes_version` | EKS cluster version | `1.29` | No |
| `node_instance_type` | EC2 instance type for nodes | `t3.medium` | No |
| `min_node_count` | Minimum number of nodes | `2` | No |
| `max_node_count` | Maximum number of nodes | `10` | No |

### Customization Examples

#### Development Environment
```hcl
# terraform.tfvars
environment = "dev"
node_instance_type = "t3.small"
min_node_count = 1
max_node_count = 3
enable_container_insights = false
```

#### Production Environment
```hcl
# terraform.tfvars
environment = "prod"
node_instance_type = "c5.large"
min_node_count = 3
max_node_count = 20
node_capacity_type = "ON_DEMAND"
enable_container_insights = true
cluster_endpoint_public_access = false
```

## 🔐 Security Features

### Network Security
- **Private API Server**: Cluster API endpoint is private-only
- **VPC Endpoints**: Private connectivity to AWS services
- **Security Groups**: Least privilege network access
- **Private Subnets**: Worker nodes isolated from internet

### Identity & Access Management
- **IAM Roles**: Dedicated roles for cluster and node groups
- **Service Accounts**: IRSA (IAM Roles for Service Accounts) ready
- **ECR Policies**: Secure container image access

### Monitoring & Compliance
- **CloudWatch Logs**: All cluster logs centralized
- **Container Insights**: Pod and node metrics
- **VPC Flow Logs**: Network traffic monitoring
- **ECR Scanning**: Vulnerability assessment on push

## 📊 Monitoring

### CloudWatch Integration
The cluster automatically sends logs to CloudWatch:
- **API Server Logs**: API request/response logging
- **Audit Logs**: Security and compliance auditing
- **Authenticator Logs**: Authentication events
- **Controller Manager**: Cluster controller activity
- **Scheduler**: Pod scheduling decisions

### Access Logs
```bash
# View cluster logs
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/"

# Stream live logs
aws logs tail /aws/eks/eks-demo-eks-*/cluster --follow
```

### Metrics Dashboard
Enable Container Insights for detailed metrics:
- Pod CPU/Memory utilization
- Node resource usage
- Network performance
- Storage metrics

## 🔧 Operations

### Scaling Operations
```bash
# Scale node group
aws eks update-nodegroup-config \
  --cluster-name $(terraform output -raw cluster_name) \
  --nodegroup-name application \
  --scaling-config minSize=3,maxSize=15,desiredSize=5
```

### ECR Operations
```bash
# Get ECR login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url)

# Push image
docker tag my-app:latest $(terraform output -raw ecr_repository_url):latest
docker push $(terraform output -raw ecr_repository_url):latest
```

### Troubleshooting
```bash
# Check cluster status
kubectl get nodes -o wide
kubectl get pods --all-namespaces
kubectl describe nodes

# View cluster events
kubectl get events --all-namespaces --sort-by='.firstTimestamp'

# Check EKS cluster logs
aws eks describe-cluster --name $(terraform output -raw cluster_name)
```

## 🔌 Add-ons & Extensions

### Included Add-ons
- **AWS Load Balancer Controller**: Application Load Balancer integration
- **VPC CNI**: Advanced VPC networking
- **CoreDNS**: Cluster DNS resolution
- **Kube-proxy**: Network proxy
- **EBS CSI Driver**: Persistent volume support

### Optional Add-ons
Configure these through variables:
- **EFS CSI Driver**: Shared file systems
- **Cluster Autoscaler**: Automatic node scaling
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization

## 🏷️ Resource Tagging

All resources are automatically tagged with:
- **Project**: Identifies the project
- **Environment**: Environment designation
- **ManagedBy**: Terraform identifier
- **Owner**: Resource ownership

Additional tags can be added via the `additional_tags` variable.

## 💰 Cost Optimization

### Instance Types
- **Development**: `t3.small` or `t3.medium`
- **Production**: `c5.large` or `m5.large`
- **Cost-Sensitive**: Use `SPOT` instances for non-critical workloads

### Resource Optimization
- Set appropriate node group scaling limits
- Use ECR lifecycle policies for image cleanup
- Configure log retention periods
- Enable Container Insights selectively

## 📚 Additional Resources

### AWS Documentation
- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- [VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)

### Kubernetes Resources
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Security Best Practices
- [EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

## 🗑️ Cleanup

To destroy the infrastructure:

```bash
# Delete any deployed applications first
kubectl delete all --all --all-namespaces

# Destroy Terraform resources
terraform destroy
```

**Warning**: This will permanently delete all resources. Ensure you have backups of any important data.

## Required Permissions

The AWS user/role running Terraform needs these IAM permissions:

<details>
<summary>Click to expand IAM policy</summary>

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "eks:*",
                "ecr:*",
                "iam:*",
                "logs:*",
                "cloudwatch:*",
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

</details>

## 📞 Support

For issues and questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review AWS CloudWatch logs
3. Consult AWS EKS documentation
4. Open an issue in the project repository

---

**Generated by**: Terraform AWS EKS Module  
**Last Updated**: $(date)  
**Version**: 1.0.0