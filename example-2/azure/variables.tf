# Variables for Azure Kubernetes Service Infrastructure

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "staging-k8s"

  validation {
    condition     = length(var.resource_prefix) <= 15 && can(regex("^[a-z0-9-]+$", var.resource_prefix))
    error_message = "Resource prefix must be 15 characters or less and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"

  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US",
      "West Central US", "Canada Central", "Canada East",
      "North Europe", "West Europe", "UK South", "UK West",
      "France Central", "Germany West Central", "Switzerland North",
      "Australia East", "Australia Southeast", "Japan East", "Japan West",
      "Korea Central", "Southeast Asia", "East Asia"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment   = "Staging"
    Project      = "Kubernetes Infrastructure"
    Owner        = "Platform Team"
    ManagedBy    = "Terraform"
    CostCenter   = "Engineering"
    Workload     = "Container Platform"
  }

  validation {
    condition     = contains(keys(var.tags), "Environment") && contains(keys(var.tags), "Project") && contains(keys(var.tags), "Owner")
    error_message = "Tags must include at least Environment, Project, and Owner keys."
  }
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "VNet address space must be a valid CIDR block."
  }
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS nodes subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.aks_subnet_address_prefix, 0))
    error_message = "AKS subnet address prefix must be a valid CIDR block."
  }
}

variable "pod_subnet_address_prefix" {
  description = "Address prefix for AKS pods subnet (when using advanced networking)"
  type        = string
  default     = "10.0.2.0/23"

  validation {
    condition     = can(cidrhost(var.pod_subnet_address_prefix, 0))
    error_message = "Pod subnet address prefix must be a valid CIDR block."
  }
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be a valid CIDR block."
  }
}

variable "dns_service_ip" {
  description = "IP address for DNS service within service CIDR"
  type        = string
  default     = "10.1.0.10"

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.dns_service_ip))
    error_message = "DNS service IP must be a valid IP address."
  }
}

# AKS Configuration
variable "kubernetes_version" {
  description = "Version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+", var.kubernetes_version))
    error_message = "Kubernetes version must be in format 'x.y' or 'x.y.z'."
  }
}

variable "node_vm_size" {
  description = "Size of the Virtual Machines for AKS nodes (4 vCPU, 16GB RAM)"
  type        = string
  default     = "Standard_D4s_v3"

  validation {
    condition = contains([
      "Standard_D4s_v3", "Standard_D4s_v4", "Standard_D4s_v5",
      "Standard_D4as_v4", "Standard_D4as_v5", "Standard_E4s_v3",
      "Standard_E4s_v4", "Standard_E4s_v5", "Standard_E4as_v4", "Standard_E4as_v5"
    ], var.node_vm_size)
    error_message = "Node VM size must be a valid Azure VM size with 4 vCPU and 16GB RAM."
  }
}

variable "min_node_count" {
  description = "Minimum number of nodes in the AKS cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.min_node_count >= 1 && var.min_node_count <= 10
    error_message = "Minimum node count must be between 1 and 10."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes in the AKS cluster"
  type        = number
  default     = 10

  validation {
    condition     = var.max_node_count >= 2 && var.max_node_count <= 100
    error_message = "Maximum node count must be between 2 and 100."
  }
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 30

  validation {
    condition     = var.max_pods_per_node >= 10 && var.max_pods_per_node <= 250
    error_message = "Max pods per node must be between 10 and 250."
  }
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB for AKS nodes"
  type        = number
  default     = 128

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 2048
    error_message = "OS disk size must be between 30 and 2048 GB."
  }
}

# Container Registry Configuration
variable "acr_sku" {
  description = "SKU for Azure Container Registry (Premium required for private endpoints)"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

# Log Analytics Configuration
variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics workspace"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 7 && var.log_retention_days <= 730
    error_message = "Log retention days must be between 7 and 730."
  }
}

# Security Configuration
variable "enable_private_cluster" {
  description = "Whether to enable private cluster (no public API server endpoint)"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Whether to enable Azure Policy for AKS"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Whether to enable Azure Monitor for containers"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Whether to enable Workload Identity for AKS"
  type        = bool
  default     = true
}

# Environment-specific overrides
variable "environment" {
  description = "Environment name (used for resource naming and configuration)"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}