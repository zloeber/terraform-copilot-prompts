# Variables for the WordPress development infrastructure on Azure

variable "azure_region" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US 2"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "wordpress-dev-rg"
}

variable "availability_zones" {
  description = "Availability zones to use for the infrastructure"
  type        = list(string)
  default     = ["1", "2"]
}

variable "vm_size" {
  description = "Azure VM size for web servers"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_count_per_zone" {
  description = "Number of VMs per availability zone"
  type        = number
  default     = 2
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 50
}

variable "data_disk_size_gb" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 100
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_prefixes" {
  description = "Address prefixes for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_prefixes" {
  description = "Address prefixes for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
  default     = "wordpress"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "Zach"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "wordpress"
    Owner       = "Zach"
    ManagedBy   = "terraform"
    Region      = "eastus2"
  }
}