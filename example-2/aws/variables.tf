# Variables for AWS EKS Infrastructure

variable "region" {
  type        = string
  description = "AWS region where resources will be created"
  default     = "us-east-1"
  
  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region (e.g., us-east-1, eu-west-1)."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resource names"
  default     = "eks-demo"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,28}[a-zA-Z0-9]$", var.resource_prefix))
    error_message = "Resource prefix must be 3-30 characters, start with letter, end with letter/number, and contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
  default     = "dev"
  
  validation {
    condition = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, staging, prod."
  }
}

# Networking Configuration

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  
  validation {
    condition = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
  
  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
  
  validation {
    condition = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
  
  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All private subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

# EKS Cluster Configuration

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
  default     = "1.29"
  
  validation {
    condition = can(regex("^1\\.(2[4-9]|[3-9][0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.24 or higher."
  }
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Enable public API server endpoint (set to false for private clusters)"
  default     = false
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Enable private API server endpoint"
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks that can access the public API server endpoint"
  default     = []
  
  validation {
    condition = alltrue([
      for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDRs must be valid IPv4 CIDR blocks."
  }
}

# Node Group Configuration

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for EKS worker nodes"
  default     = "t3.medium"
  
  validation {
    condition = can(regex("^[a-z][0-9]+[a-z]*\\.[a-z0-9]+$", var.node_instance_type))
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "node_disk_size" {
  type        = number
  description = "Disk size in GiB for worker nodes"
  default     = 30
  
  validation {
    condition     = var.node_disk_size >= 20 && var.node_disk_size <= 16384
    error_message = "Node disk size must be between 20 and 16384 GiB."
  }
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 2
  
  validation {
    condition     = var.min_node_count >= 1 && var.min_node_count <= 100
    error_message = "Minimum node count must be between 1 and 100."
  }
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 10
  
  validation {
    condition     = var.max_node_count >= 1 && var.max_node_count <= 100
    error_message = "Maximum node count must be between 1 and 100."
  }
}

variable "desired_node_count" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
  
  validation {
    condition     = var.desired_node_count >= 1 && var.desired_node_count <= 100
    error_message = "Desired node count must be between 1 and 100."
  }
}

# Security Configuration

variable "enable_cluster_encryption" {
  type        = bool
  description = "Enable encryption for EKS cluster secrets"
  default     = true
}

variable "cluster_log_types" {
  type        = list(string)
  description = "List of EKS cluster log types to enable"
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  validation {
    condition = alltrue([
      for log_type in var.cluster_log_types : 
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Log types must be from: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain CloudWatch logs"
  default     = 30
  
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

# ECR Configuration

variable "ecr_image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the ECR repository (MUTABLE or IMMUTABLE)"
  default     = "MUTABLE"
  
  validation {
    condition = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ECR image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "ecr_scan_on_push" {
  type        = bool
  description = "Enable vulnerability scanning on image push to ECR"
  default     = true
}

variable "ecr_encryption_type" {
  type        = string
  description = "The encryption type to use for the ECR repository (AES256 or KMS)"
  default     = "AES256"
  
  validation {
    condition = contains(["AES256", "KMS"], var.ecr_encryption_type)
    error_message = "ECR encryption type must be either AES256 or KMS."
  }
}

variable "ecr_kms_key_id" {
  type        = string
  description = "The KMS key ID to use for ECR encryption (only used when encryption_type is KMS)"
  default     = null
}

# Monitoring and Logging

variable "enable_container_insights" {
  type        = bool
  description = "Enable Container Insights for the EKS cluster"
  default     = true
}

variable "enable_prometheus" {
  type        = bool
  description = "Enable Prometheus monitoring"
  default     = false
}

variable "enable_grafana" {
  type        = bool
  description = "Enable Grafana dashboard"
  default     = false
}

# Add-ons Configuration

variable "enable_aws_load_balancer_controller" {
  type        = bool
  description = "Enable AWS Load Balancer Controller add-on"
  default     = true
}

variable "enable_ebs_csi_driver" {
  type        = bool
  description = "Enable AWS EBS CSI Driver add-on"
  default     = true
}

variable "enable_efs_csi_driver" {
  type        = bool
  description = "Enable AWS EFS CSI Driver add-on"
  default     = false
}

variable "enable_cluster_autoscaler" {
  type        = bool
  description = "Enable Cluster Autoscaler"
  default     = true
}

# Tagging

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resources"
  default = {
    Project     = "EKS-Demo"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to be merged with the default tags"
  default     = {}
}

# Cost Management

variable "node_capacity_type" {
  type        = string
  description = "Type of capacity associated with the EKS Node Group (ON_DEMAND or SPOT)"
  default     = "ON_DEMAND"
  
  validation {
    condition = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Node capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "spot_instance_types" {
  type        = list(string)
  description = "List of instance types for spot instances (used when capacity_type is SPOT)"
  default     = ["t3.medium", "t3.large", "t3.xlarge"]
  
  validation {
    condition = alltrue([
      for instance_type in var.spot_instance_types : can(regex("^[a-z][0-9]+[a-z]*\\.[a-z0-9]+$", instance_type))
    ])
    error_message = "All instance types must be valid EC2 instance types."
  }
}

# Backup and Disaster Recovery

variable "enable_backup" {
  type        = bool
  description = "Enable AWS Backup for EKS cluster resources"
  default     = false
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain backups"
  default     = 30
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 2555
    error_message = "Backup retention days must be between 1 and 2555."
  }
}

# Network Security

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access the cluster"
  default     = []
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

variable "enable_vpc_flow_logs" {
  type        = bool
  description = "Enable VPC Flow Logs"
  default     = true
}

variable "vpc_flow_logs_retention" {
  type        = number
  description = "Number of days to retain VPC Flow Logs"
  default     = 14
  
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.vpc_flow_logs_retention)
    error_message = "VPC Flow Logs retention days must be a valid CloudWatch Logs retention period."
  }
}