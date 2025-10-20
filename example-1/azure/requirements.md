# Azure WordPress Development Infrastructure Requirements

## Overview
This document outlines the comprehensive requirements for setting up a WordPress development infrastructure on Microsoft Azure using Terraform, converted from the AWS equivalent.

## Core Requirements (Translated to Azure)
- **Virtual Machines**: 4 Ubuntu Linux VMs
- **Distribution**: Spread across 2 availability zones in the same Azure region
- **Network**: Internal-only network (private subnets with no direct internet access)
- **Web Services**: nginx running on ports 80 and 443
- **VM Size**: Standard_B2s (Azure equivalent of t3.medium)
- **Region**: East US 2 (Azure equivalent of us-east-2)
- **Operating System**: Latest Ubuntu 22.04 LTS
- **Storage Requirements**:
  - OS disks: 50GB each (Premium SSD)
  - Data disks: 100GB each (mounted at /opt)
- **Load Balancing**: Azure Application Gateway for traffic distribution
- **Management Access**: Azure Bastion or Azure CLI with managed identity
- **Environment**: Development
- **Project Name**: wordpress
- **Owner**: Zach
- **Storage**: Azure Storage Account (Blob Storage) accessible by all VMs

## Azure Infrastructure Components

### Resource Organization
- **Resource Group**: Container for all WordPress infrastructure resources
- **Naming Convention**: wordpress-dev-rg

### Network Architecture
- **Virtual Network (VNet)**: Custom VNet with proper CIDR allocation
- **Availability Zones**: Zone 1 and Zone 2 in East US 2
- **Subnets**:
  - 2 Public subnets (one per AZ) for Application Gateway
  - 2 Private subnets (one per AZ) for Virtual Machines
- **NAT Gateway**: For private subnet outbound internet access
- **Public IP**: For NAT Gateway and Application Gateway

### Compute Resources
- **Virtual Machines**: 4 x Standard_B2s instances
- **VM Image**: Ubuntu 22.04 LTS (latest)
- **Distribution**: 2 VMs per availability zone
- **Managed Identity**: System-assigned identity for Azure resource access

### Storage
- **OS Disks**: 50GB Premium SSD per VM
- **Data Disks**: 100GB Premium SSD per VM (mounted at /opt)
- **Storage Account**: General Purpose v2 with blob storage
- **Access Control**: RBAC for VM managed identities

### Load Balancing
- **Application Gateway**: Layer 7 load balancer
- **Placement**: Public subnets across both availability zones
- **Backend Pool**: HTTP/HTTPS targets pointing to VMs
- **Health Probes**: HTTP health checks on nginx

### Security
- **Network Security Groups (NSGs)**:
  - Application Gateway NSG: Allow HTTP/HTTPS from internet
  - VM NSG: Allow HTTP/HTTPS from Application Gateway only
- **Storage Access**: RBAC policies for blob storage access
- **Access Management**: Azure managed identity instead of SSH keys

### Monitoring & Management
- **Azure Monitor**: VM monitoring and diagnostics
- **Log Analytics**: Centralized logging
- **Azure Bastion**: Secure VM access (alternative to SSH)

## Azure-Specific Considerations

### Availability Zones
- Azure availability zones provide similar redundancy to AWS AZs
- East US 2 supports availability zones
- VMs will be distributed across zones for high availability

### Storage Differences
- Azure Blob Storage replaces S3
- Managed disks replace EBS volumes
- Azure Files could be alternative for shared storage

### Identity and Access Management
- Azure RBAC replaces AWS IAM
- Managed Identity replaces IAM roles
- Azure Key Vault for secrets management

### Networking Differences
- Virtual Networks replace VPCs
- Network Security Groups replace Security Groups
- Application Gateway replaces Application Load Balancer

## Security & Compliance (Azure)
- **Network Isolation**: Private subnets with no direct internet access
- **Least Privilege**: RBAC with minimal required permissions
- **Encryption**: Managed disks encrypted at rest
- **Secure Access**: Azure Bastion instead of SSH
- **Network Security Groups**: Restrictive rules allowing only necessary traffic

## Best Practices Implemented
- **High Availability**: Multi-zone deployment
- **Scalability**: Virtual Machine Scale Sets ready configuration
- **Security**: Defense in depth with multiple security layers
- **Monitoring**: Azure Monitor integration
- **Cost Optimization**: Development environment optimized for cost
- **Infrastructure as Code**: Terraform for reproducible deployments

## Tags Applied to All Resources
- **Environment**: development
- **Project**: wordpress
- **Owner**: Zach
- **ManagedBy**: terraform
- **Region**: eastus2