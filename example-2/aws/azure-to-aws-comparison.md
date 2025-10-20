# Azure to AWS Migration Comparison

This document provides a detailed comparison between the Azure AKS infrastructure and the AWS EKS equivalent implementation.

## 🏗️ Architecture Comparison

### High-Level Architecture Mapping

| Component | Azure Implementation | AWS Implementation |
|-----------|---------------------|-------------------|
| **Kubernetes Service** | Azure Kubernetes Service (AKS) | Amazon Elastic Kubernetes Service (EKS) |
| **Container Registry** | Azure Container Registry (ACR) | Elastic Container Registry (ECR) |
| **Networking** | Azure Virtual Network (VNet) | Amazon Virtual Private Cloud (VPC) |
| **Load Balancing** | Azure Application Gateway | AWS Application Load Balancer |
| **Identity & Access** | Azure Managed Identity | AWS IAM Roles |
| **Monitoring** | Azure Monitor + Container Insights | CloudWatch + Container Insights |
| **Private Connectivity** | Private Link | VPC Endpoints |

## 📊 Resource Mapping Table

### Core Infrastructure

| Azure Resource | AWS Equivalent | Notes |
|----------------|----------------|-------|
| `azurerm_resource_group` | N/A (Region-based) | AWS uses regions instead of resource groups |
| `azurerm_virtual_network` | `aws_vpc` | Same concept, different implementation |
| `azurerm_subnet` | `aws_subnet` | Direct equivalent with AZ mapping |
| `azurerm_network_security_group` | `aws_security_group` | Similar functionality, different syntax |
| `azurerm_route_table` | `aws_route_table` | Direct equivalent |
| `azurerm_nat_gateway` | `aws_nat_gateway` | Same concept, requires Elastic IP in AWS |
| `azurerm_public_ip` | `aws_eip` | Direct equivalent for static IPs |

### Kubernetes Services

| Azure Resource | AWS Equivalent | Key Differences |
|----------------|----------------|-----------------|
| `azurerm_kubernetes_cluster` | `aws_eks_cluster` | AWS requires separate node groups |
| `azurerm_kubernetes_cluster_node_pool` | `aws_eks_node_group` | AWS has more granular control |
| N/A | `aws_eks_addon` | AWS uses managed add-ons, Azure uses built-in |

### Container Registry

| Azure Resource | AWS Equivalent | Key Differences |
|----------------|----------------|-----------------|
| `azurerm_container_registry` | `aws_ecr_repository` | Per-repository model in AWS vs single registry |
| ACR Private Endpoint | VPC Endpoints for ECR | Different private connectivity approach |

### Identity & Access Management

| Azure Resource | AWS Equivalent | Key Differences |
|----------------|----------------|-----------------|
| `azurerm_user_assigned_identity` | `aws_iam_role` | Different identity models |
| Azure RBAC | AWS IAM Policies | More granular in AWS |
| Managed Identity | IAM Roles for Service Accounts (IRSA) | AWS requires OIDC provider setup |

## 🔧 Configuration Differences

### Network Configuration

#### Azure Implementation
```hcl
# Single VNet with multiple subnets
resource "azurerm_virtual_network" "main" {
  address_space = ["10.1.0.0/16"]
}

# Simpler subnet configuration
resource "azurerm_subnet" "private" {
  address_prefixes = ["10.1.1.0/24"]
}
```

#### AWS Implementation  
```hcl
# VPC with explicit internet gateway
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Separate public and private subnets
resource "aws_subnet" "public" {
  # For NAT Gateways
}
resource "aws_subnet" "private" {
  # For EKS nodes
}
```

### Private Connectivity

#### Azure: Private Link
```hcl
# Azure uses Private Link service
resource "azurerm_private_endpoint" "acr" {
  subnet_id = azurerm_subnet.private.id
  
  private_service_connection {
    name                           = "acr-connection"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
  }
}
```

#### AWS: VPC Endpoints
```hcl
# AWS uses VPC Endpoints (multiple required)
resource "aws_vpc_endpoint" "ecr_api" {
  service_name = "com.amazonaws.${var.region}.ecr.api"
}
resource "aws_vpc_endpoint" "ecr_dkr" {
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
}
resource "aws_vpc_endpoint" "s3" {
  service_name = "com.amazonaws.${var.region}.s3"
}
```

### Kubernetes Cluster Configuration

#### Azure AKS
```hcl
resource "azurerm_kubernetes_cluster" "main" {
  # Single resource includes:
  # - Control plane
  # - Default node pool
  # - Add-ons (built-in)
  # - Networking (Azure CNI)
  
  default_node_pool {
    # Integrated node pool
  }
  
  network_profile {
    network_plugin = "azure"  # Built-in CNI
  }
}
```

#### AWS EKS
```hcl
resource "aws_eks_cluster" "main" {
  # Control plane only
}

# Separate node groups required
resource "aws_eks_node_group" "system" {
  # Dedicated system workloads
}
resource "aws_eks_node_group" "application" {
  # Application workloads
}

# Explicit add-ons
resource "aws_eks_addon" "vpc_cni" {
  # Managed CNI add-on
}
```

## 📈 Scaling Differences

### Auto-scaling Comparison

| Feature | Azure AKS | AWS EKS |
|---------|-----------|---------|
| **Cluster Autoscaler** | Built-in option | Requires separate installation |
| **Node Pool Scaling** | Integrated in node pool | Managed by Auto Scaling Groups |
| **Pod Autoscaling** | Standard HPA/VPA | Standard HPA/VPA |
| **Scaling Metrics** | Azure Monitor | CloudWatch |

### Azure Auto-scaling
```hcl
resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  enable_auto_scaling = true
  min_count          = 2
  max_count          = 10
}
```

### AWS Auto-scaling
```hcl
resource "aws_eks_node_group" "application" {
  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 2
  }
}
```

## 🔐 Security Model Differences

### Identity Management

#### Azure Approach
- **Managed Identity**: Automatic identity assignment
- **Azure RBAC**: Integrated role-based access
- **Key Vault Integration**: Built-in secrets management

#### AWS Approach  
- **IAM Roles**: Explicit role creation and attachment
- **IRSA**: IAM Roles for Service Accounts (more complex setup)
- **AWS Secrets Manager**: Separate service integration

### Network Security

| Security Layer | Azure | AWS |
|----------------|-------|-----|
| **Network Filtering** | Network Security Groups (NSGs) | Security Groups |
| **Network Segmentation** | VNet/Subnet isolation | VPC/Subnet isolation |
| **Private API Access** | Private Link | VPC Endpoints |
| **Firewall Integration** | Azure Firewall | AWS Network Firewall |

## 💰 Cost Comparison

### Pricing Models

#### Azure AKS
- **Control Plane**: Free
- **Nodes**: Pay for VM instances
- **Storage**: Premium SSD rates
- **Networking**: Standard VNet pricing
- **Registry**: ACR tiered pricing

#### AWS EKS  
- **Control Plane**: $0.10/hour per cluster
- **Nodes**: Pay for EC2 instances
- **Storage**: EBS volume pricing
- **Networking**: VPC and data transfer costs
- **Registry**: ECR per-repository pricing

### Estimated Monthly Costs (3-node cluster)

| Component | Azure Cost | AWS Cost |
|-----------|------------|----------|
| **Control Plane** | $0 | ~$73 |
| **3 x t3.medium nodes** | ~$150 | ~$150 |
| **Storage (100GB)** | ~$20 | ~$15 |
| **Networking** | ~$10 | ~$15 |
| **Registry** | ~$5 | ~$1 |
| **Total** | **~$185** | **~$254** |

*Note: Costs are approximate and vary by region*

## 🔄 Migration Considerations

### Data Migration
1. **Container Images**: 
   - Export from ACR using `docker pull`
   - Push to ECR using `docker push`
   - Update image references in deployments

2. **Persistent Volumes**:
   - Azure Disk → EBS volumes
   - Azure Files → EFS (if needed)
   - Backup/restore data as needed

3. **Configuration**:
   - Update service types (LoadBalancer annotations)
   - Modify ingress controllers (Azure AG → AWS ALB)
   - Adjust monitoring configs

### Network Migration
1. **IP Ranges**: Update CIDR blocks if needed
2. **DNS**: Update service discovery configurations  
3. **Load Balancers**: Reconfigure for AWS ALB/NLB
4. **SSL Certificates**: Migrate to AWS Certificate Manager

### Operational Changes
1. **Monitoring**: Azure Monitor → CloudWatch
2. **Logging**: Azure Logs → CloudWatch Logs
3. **Alerting**: Azure Alerts → CloudWatch Alarms
4. **Backup**: Azure Backup → AWS Backup

## 📋 Migration Checklist

### Pre-Migration
- [ ] Inventory current Azure resources
- [ ] Document network configurations
- [ ] Export container images from ACR
- [ ] Backup persistent data
- [ ] Plan IP addressing for AWS

### Migration Phase
- [ ] Deploy AWS infrastructure
- [ ] Configure VPC endpoints for private access
- [ ] Push images to ECR
- [ ] Deploy applications with updated configurations
- [ ] Test connectivity and functionality
- [ ] Migrate monitoring and alerting

### Post-Migration
- [ ] Validate all services are operational
- [ ] Update CI/CD pipelines
- [ ] Update documentation
- [ ] Train team on AWS-specific operations
- [ ] Decommission Azure resources

## 🚀 Advantages of Each Platform

### Azure AKS Advantages
- **Simpler Setup**: Less configuration required
- **Cost**: No control plane charges
- **Integration**: Better with Microsoft ecosystem
- **Managed Identity**: Easier identity management

### AWS EKS Advantages  
- **Flexibility**: More configuration options
- **Maturity**: Longer-established Kubernetes service
- **Ecosystem**: Larger AWS service ecosystem
- **Add-ons**: Extensive managed add-on catalog

## 🔧 Operational Differences

### Daily Operations

| Task | Azure Command | AWS Command |
|------|---------------|-------------|
| **Get Credentials** | `az aks get-credentials` | `aws eks update-kubeconfig` |
| **Scale Nodes** | `az aks scale` | `aws eks update-nodegroup-config` |
| **View Logs** | `az monitor log-analytics query` | `aws logs tail` |
| **Registry Login** | `az acr login` | `aws ecr get-login-password` |

### Troubleshooting

#### Azure Tools
- Azure Monitor workbooks
- Container Insights
- Azure CLI diagnostics
- Azure Portal visual diagnostics

#### AWS Tools  
- CloudWatch Container Insights
- AWS X-Ray tracing
- AWS CLI with enhanced debugging
- AWS Console with detailed metrics

## 📚 Learning Resources

### Azure to AWS Learning Path
1. **AWS EKS Workshop**: https://www.eksworkshop.com/
2. **AWS Container Services**: https://aws.amazon.com/containers/
3. **EKS Best Practices**: https://aws.github.io/aws-eks-best-practices/
4. **AWS Networking**: https://docs.aws.amazon.com/vpc/

### Migration Guides
- **AWS Migration Hub**: https://aws.amazon.com/migration-hub/
- **Container Migration**: https://aws.amazon.com/containers/migration/
- **Well-Architected Framework**: https://aws.amazon.com/architecture/well-architected/

---

**Document Version**: 1.0.0  
**Last Updated**: $(date)  
**Migration Complexity**: Medium to High  
**Estimated Migration Time**: 2-4 weeks (depending on application complexity)