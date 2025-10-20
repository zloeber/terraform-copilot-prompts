# Azure Kubernetes Service (AKS) Private Cluster with Container Registry

This Terraform configuration creates a production-ready, private Azure Kubernetes Service (AKS) cluster with an integrated Azure Container Registry (ACR) for staging environments.

## 🏗️ Infrastructure Overview

### Architecture Components

1. **Private AKS Cluster**
   - Completely private cluster with no public API server endpoint
   - Private DNS zone for cluster communication
   - Auto-scaling enabled (2-10 nodes)
   - Advanced networking with Azure CNI
   - Internal load balancer for service exposure

2. **Azure Container Registry (ACR)**
   - Premium tier with private endpoint
   - Integrated with AKS using managed identity
   - Network isolation with private DNS zone
   - Zone redundancy enabled

3. **Virtual Network & Subnets**
   - Dedicated VNet with proper CIDR allocation
   - Separate subnets for AKS nodes and pods
   - Network security groups for traffic control
   - Private endpoint networking

4. **Security & Monitoring**
   - Azure Policy integration
   - Azure Monitor for containers
   - Workload Identity enabled
   - RBAC with managed identities
   - Key Vault Secrets Provider

## 📋 Requirements Captured

### Original Requirements
- **Managed Kubernetes cluster** ✅ (Azure Kubernetes Service)
- **Private network deployment** ✅ (Private cluster with private subnets)
- **Container registry access** ✅ (Private ACR with managed identity integration)
- **Load balancer for service exposure** ✅ (Internal load balancer)

### Additional Requirements Gathered
- **Cluster Size**: Start with 2 nodes, auto-scale up to 10 nodes ✅
- **Environment**: Staging environment ✅
- **Load Balancer Type**: Internal (private) load balancer ✅
- **Node Specifications**: 4 vCPU, 16GB RAM (Standard_D4s_v3) ✅
- **Region**: East US (Azure equivalent of us-east-1) ✅
- **Network Access**: Completely private access (no public API endpoint) ✅

### Inferred Best Practice Requirements
- **Security**: Private endpoints, managed identities, RBAC, network policies ✅
- **Monitoring**: Azure Monitor integration with Log Analytics ✅
- **Scalability**: Auto-scaling node pools with proper resource limits ✅
- **Networking**: Advanced CNI networking with dedicated pod subnet ✅
- **Compliance**: Azure Policy integration for governance ✅
- **High Availability**: Zone redundancy where supported ✅

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and configured
   ```bash
   az --version
   az login
   az account show
   ```

2. **Terraform** installed (>= 1.0)
   ```bash
   terraform --version
   ```

3. **Azure Subscription** with appropriate permissions:
   - Contributor or Owner role on the subscription
   - Microsoft.ContainerService resource provider registered
   - Microsoft.ContainerRegistry resource provider registered

### Deployment Steps

1. **Clone and Navigate**
   ```bash
   cd output/azure
   ```

2. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan Deployment**
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

6. **Configure kubectl**
   ```bash
   az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
   ```

## 🔧 Configuration

### Network Configuration

| Component | CIDR Block | Purpose |
|-----------|------------|---------|
| VNet | 10.0.0.0/16 | Main virtual network |
| AKS Nodes | 10.0.1.0/24 | Kubernetes node subnet |
| AKS Pods | 10.0.2.0/23 | Pod networking subnet |
| Services | 10.1.0.0/16 | Kubernetes services |

### Node Pool Configuration

- **System Pool**: 2-10 nodes, only critical add-ons
- **Application Pool**: 2-10 nodes, application workloads
- **VM Size**: Standard_D4s_v3 (4 vCPU, 16GB RAM)
- **OS Disk**: 128GB Ephemeral SSD
- **Auto-scaling**: Enabled with intelligent scaling policies

### Security Features

- ✅ Private cluster (no public API endpoint)
- ✅ Private container registry with private endpoint
- ✅ Managed identity authentication
- ✅ Network security groups and policies
- ✅ Azure Policy integration
- ✅ Workload Identity for pod authentication
- ✅ RBAC enabled
- ✅ Key Vault Secrets Provider

## 🌐 Accessing the Cluster

Since this is a private cluster, you need to access it from within the Azure Virtual Network or through a connected network.

### Option 1: Azure Bastion (Recommended)
```bash
# Create a jumpbox VM in the same VNet
# Install kubectl and Azure CLI on the jumpbox
# Connect via Azure Bastion
```

### Option 2: VPN Gateway
```bash
# Set up Point-to-Site or Site-to-Site VPN
# Connect your local network to the Azure VNet
```

### Option 3: ExpressRoute
```bash
# Use ExpressRoute for dedicated connection
# Connect your on-premises network to Azure
```

## 📦 Container Registry Usage

### Login to ACR
```bash
az acr login --name <acr-name>
```

### Tag and Push Images
```bash
docker tag myapp:latest <acr-name>.azurecr.io/myapp:latest
docker push <acr-name>.azurecr.io/myapp:latest
```

### Pull Images in Kubernetes
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: <acr-name>.azurecr.io/myapp:latest
        ports:
        - containerPort: 8080
```

## 🔍 Monitoring and Observability

### Azure Monitor
- Container insights enabled
- Log Analytics workspace configured
- 30-day retention for staging environment

### Key Metrics
- Node CPU/Memory utilization
- Pod resource consumption
- Container registry pull/push metrics
- Network traffic analysis

### Log Queries
```kusto
// View container logs
ContainerLog
| where TimeGenerated > ago(1h)
| project TimeGenerated, Computer, ContainerID, LogEntry

// Monitor node health
KubeNodeInventory
| where TimeGenerated > ago(1h)
| summarize by Computer, Status
```

## 🔒 Security Considerations

### Network Security
- All traffic between pods and nodes uses private IP addresses
- Container registry accessible only via private endpoint
- Network security groups restrict traffic flow
- No public endpoints exposed

### Identity and Access
- Managed identity for AKS-ACR integration
- Workload Identity for pod-level authentication
- RBAC controls for cluster access
- Azure AD integration ready

### Compliance
- Azure Policy enforcement
- Security baseline policies
- Container image scanning (can be enabled)
- Network policy enforcement

## 🔧 Customization

### Scaling Configuration
Edit in `variables.tf`:
```hcl
variable "min_node_count" {
  default = 3  # Increase minimum nodes
}

variable "max_node_count" {
  default = 20  # Increase maximum nodes
}
```

### VM Size Adjustment
```hcl
variable "node_vm_size" {
  default = "Standard_D8s_v3"  # 8 vCPU, 32GB RAM
}
```

### Additional Node Pools
Add to `main.tf`:
```hcl
resource "azurerm_kubernetes_cluster_node_pool" "gpu_nodes" {
  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = "Standard_NC6s_v3"
  node_count           = 1
  # ... additional configuration
}
```

## 📊 Cost Optimization

### Staging Environment Features
- Ephemeral OS disks for lower storage costs
- Auto-scaling to minimize idle resources
- 30-day log retention
- Standard Load Balancer (included with AKS)

### Cost Monitoring
```bash
# Monitor costs with Azure CLI
az consumption usage list --top 10
```

## 🚨 Troubleshooting

### Common Issues

1. **Cannot connect to cluster**
   - Ensure you're on the VNet or connected via VPN
   - Check private DNS resolution
   - Verify NSG rules

2. **Container registry access denied**
   - Verify managed identity permissions
   - Check private endpoint configuration
   - Ensure network connectivity

3. **Pods cannot pull images**
   - Check ACR role assignments
   - Verify private endpoint DNS resolution
   - Review network policies

### Debug Commands
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Verify ACR integration
kubectl describe serviceaccount default

# Check DNS resolution
nslookup <acr-name>.azurecr.io
```

## 📚 Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Private AKS Clusters](https://docs.microsoft.com/en-us/azure/aks/private-clusters)
- [ACR Integration](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration)
- [Azure CNI Networking](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)

## 🤝 Support

For issues related to this Terraform configuration:
1. Check the troubleshooting section
2. Review Azure AKS documentation
3. Consult Terraform Azure provider documentation
4. Engage with the Platform Team

---

**Note**: This infrastructure is configured for a staging environment. For production deployments, consider additional security hardening, backup strategies, and disaster recovery planning.