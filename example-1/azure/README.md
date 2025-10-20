# WordPress Development Infrastructure - Azure

This Terraform configuration creates a complete Azure infrastructure for a WordPress development environment, converted from the AWS equivalent.

## Infrastructure Overview

- **4 Ubuntu Virtual Machines** (Standard_B2s) distributed across 2 availability zones
- **Azure Application Gateway** for traffic distribution and SSL termination
- **Virtual Network with public and private subnets** for network isolation
- **Azure Storage Account** with blob storage for shared data
- **Managed Identity** for secure Azure resource access
- **Network Security Groups** with least privilege access
- **Azure Monitor** integration for logging and monitoring

## Architecture

```
Internet → Application Gateway (Public Subnets)
              ↓
         Virtual Machines (Private Subnets)
              ↓
         NAT Gateway (Outbound Internet)
              ↓
         Azure Storage Account
```

## Azure Services Used

| AWS Service | Azure Equivalent | Purpose |
|-------------|------------------|---------|
| VPC | Virtual Network | Network isolation |
| EC2 | Virtual Machines | Compute instances |
| ALB | Application Gateway | Load balancing |
| S3 | Storage Account (Blob) | Shared storage |
| IAM Roles | Managed Identity | Authentication |
| Security Groups | Network Security Groups | Network security |
| SSM | Azure Bastion/CLI | VM management |

## Prerequisites

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **Azure Subscription** with appropriate permissions
4. **Azure Provider** configured in Terraform

## Required Azure Permissions

Your Azure credentials need the following roles:
- **Contributor** or **Owner** role on the subscription or resource group
- **User Access Administrator** (for role assignments)

## Setup Instructions

### 1. Login to Azure
```bash
az login
az account set --subscription "your-subscription-id"
```

### 2. Navigate to the Azure directory
```bash
cd output/azure/
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review and Customize Variables (Optional)
Edit `variables.tf` to customize:
- Azure region (default: East US 2)
- VM sizes (default: Standard_B2s)
- Storage sizes (default: 50GB OS, 100GB data)
- Address spaces for VNet and subnets

### 5. Plan the Deployment
```bash
terraform plan
```

### 6. Deploy the Infrastructure
```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

## Post-Deployment

### Access Your Application
After deployment, access your application using the Application Gateway public IP:
```bash
# Get the application URL
terraform output application_url
```

### Connect to VMs

#### Option 1: Azure Bastion (Recommended)
1. Deploy Azure Bastion to your VNet (manual step)
2. Use Azure Portal to connect to VMs via Bastion

#### Option 2: SSH via Jump Host (Emergency)
```bash
# Get the SSH private key (save to file)
terraform output -raw ssh_private_key > private_key.pem
chmod 600 private_key.pem

# Use SSH through a jump host or VPN connection
ssh -i private_key.pem azureuser@<private-ip>
```

#### Option 3: Azure CLI Run Command
```bash
# Get connection commands
terraform output azure_cli_vm_connect_commands

# Execute commands on VMs remotely
az vm run-command invoke \
  --resource-group wordpress-dev-rg \
  --name wordpress-vm-1 \
  --command-id RunShellScript \
  --scripts "df -h"
```

### Test Azure Storage Access
Connect to a VM and test storage access:
```bash
# Test storage access using managed identity
sudo /opt/azure-config/test-storage-access.sh

# View storage configuration
sudo cat /opt/azure-config/storage-info
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
- **Managed Identity** - no passwords or keys stored
- **Private VMs** - no direct internet access
- **NSGs** with minimal required permissions
- **Encrypted managed disks**
- **Azure Monitor** integration

### High Availability
- **Multi-zone deployment** across 2 availability zones
- **Application Gateway** with health probes
- **2 VMs per zone** for redundancy

### Storage
- **Azure Storage Account** with blob storage
- **100GB managed data disk** with LVM at /opt
- **RBAC** for secure storage access via managed identity

### Monitoring
- **Azure Monitor** agent integration
- **Application Gateway** health monitoring
- **Custom health endpoints** on each VM

## Customization

### Adding SSL Certificate
To add HTTPS support with a real SSL certificate:

1. Upload certificate to Azure Key Vault:
```bash
az keyvault certificate import \
  --vault-name your-keyvault \
  --name your-cert \
  --file certificate.pfx
```

2. Update `application-gateway.tf` to use the certificate:
```hcl
ssl_certificate {
  name                = "ssl-cert"
  key_vault_secret_id = "https://your-keyvault.vault.azure.net/secrets/your-cert"
}
```

### Adding Azure Bastion
To add secure VM access via Azure Bastion:

1. Create Bastion subnet:
```hcl
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.100.0/24"]
}
```

2. Deploy Azure Bastion host:
```hcl
resource "azurerm_bastion_host" "main" {
  name                = "${var.project_name}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
```

### Scaling VMs
To change the number of VMs:
1. Modify `vm_count_per_zone` in `variables.tf`
2. Run `terraform plan` and `terraform apply`

### Adding Auto Scaling
For production workloads, consider implementing:
- Azure Virtual Machine Scale Sets
- Azure Autoscale rules
- Azure Monitor alerts for scaling triggers

## Cost Optimization

For development environments:
- **VM sizes**: Use Standard_B1s or Standard_B2s for cost savings
- **Managed disks**: Use Standard SSD for non-critical workloads
- **Shutdown scheduling**: Use Azure Automation for VM scheduling
- **Reserved instances**: For long-running development environments

## Monitoring and Logging

### Azure Monitor Integration
- VM metrics automatically collected
- Custom logs from nginx
- Application Gateway metrics
- Storage account metrics

### Log Analytics Workspace
Consider adding a Log Analytics workspace for centralized logging:
```hcl
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

## Security Best Practices

### Network Security
- VMs in private subnets with no direct internet access
- NSGs with least privilege rules
- Application Gateway handles internet-facing traffic

### Identity and Access
- System-assigned managed identities for VMs
- RBAC for storage access
- No hardcoded credentials

### Data Protection
- Encryption at rest for all managed disks
- Storage account with versioning enabled
- Network access controls on storage

## Cleanup

To destroy the infrastructure and avoid ongoing costs:
```bash
terraform destroy
```

Type `yes` when prompted to confirm destruction.

**Note**: Some resources like Storage Accounts with data may require additional confirmation.

## Troubleshooting

### VM Connection Issues
1. Verify managed identity is enabled
2. Check NSG rules and routing
3. Ensure Application Gateway health probes are passing

### Application Gateway Health Check Failures
1. Check NSG rules for health probe traffic
2. Verify nginx is running and accessible on port 80
3. Test health endpoint: `curl http://VM_IP/health`

### Storage Access Issues
1. Verify managed identity has correct RBAC roles
2. Check storage account network access rules
3. Test with Azure CLI: `az storage blob list --auth-mode login`

### Azure CLI Commands for Troubleshooting
```bash
# Check VM status
az vm list --resource-group wordpress-dev-rg --output table

# Check Application Gateway backend health
az network application-gateway show-backend-health \
  --resource-group wordpress-dev-rg \
  --name wordpress-appgw

# View VM boot diagnostics
az vm boot-diagnostics get-boot-log \
  --resource-group wordpress-dev-rg \
  --name wordpress-vm-1
```

## Support and Documentation

- [Azure Virtual Machines Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/)
- [Azure Application Gateway Documentation](https://docs.microsoft.com/en-us/azure/application-gateway/)
- [Azure Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Tags

All resources are tagged with:
- **Environment**: development
- **Project**: wordpress
- **Owner**: Zach
- **ManagedBy**: terraform
- **Region**: eastus2