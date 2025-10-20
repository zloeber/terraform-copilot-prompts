# Outputs for AWS EKS Infrastructure

# Cluster Information
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.main.status
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_service_cidr" {
  description = "The CIDR block used by Kubernetes services"
  value       = aws_eks_cluster.main.kubernetes_network_config[0].service_ipv4_cidr
}

# OIDC Provider Information
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Node Group Information
output "system_node_group_arn" {
  description = "System node group ARN"
  value       = aws_eks_node_group.system.arn
}

output "system_node_group_status" {
  description = "System node group status"
  value       = aws_eks_node_group.system.status
}

output "application_node_group_arn" {
  description = "Application node group ARN"
  value       = aws_eks_node_group.application.arn
}

output "application_node_group_status" {
  description = "Application node group status"
  value       = aws_eks_node_group.application.status
}

output "system_node_group_capacity_type" {
  description = "Type of capacity associated with the system EKS Node Group"
  value       = aws_eks_node_group.system.capacity_type
}

output "application_node_group_capacity_type" {
  description = "Type of capacity associated with the application EKS Node Group"
  value       = aws_eks_node_group.application.capacity_type
}

# IAM Role Information
output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.eks_node_group.arn
}

output "node_group_iam_role_name" {
  description = "IAM role name of the EKS node group"
  value       = aws_iam_role.eks_node_group.name
}

# Network Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Security Group Information
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

# ECR Information
output "ecr_repository_arn" {
  description = "Full ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_registry_id" {
  description = "Registry ID where the ECR repository was created"
  value       = aws_ecr_repository.main.registry_id
}

# VPC Endpoint Information
output "vpc_endpoint_eks_id" {
  description = "ID of the EKS VPC endpoint"
  value       = aws_vpc_endpoint.eks.id
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of the ECR Docker VPC endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_cloudwatch_id" {
  description = "ID of the CloudWatch VPC endpoint"
  value       = aws_vpc_endpoint.cloudwatch.id
}

output "vpc_endpoint_logs_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = aws_vpc_endpoint.logs.id
}

# CloudWatch Log Group Information
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}

# Add-ons Information
output "aws_load_balancer_controller_addon_arn" {
  description = "Amazon EKS add-on ARN for AWS Load Balancer Controller"
  value       = aws_eks_addon.aws_load_balancer_controller.arn
}

output "vpc_cni_addon_arn" {
  description = "Amazon EKS add-on ARN for VPC CNI"
  value       = aws_eks_addon.vpc_cni.arn
}

output "coredns_addon_arn" {
  description = "Amazon EKS add-on ARN for CoreDNS"
  value       = aws_eks_addon.coredns.arn
}

output "kube_proxy_addon_arn" {
  description = "Amazon EKS add-on ARN for Kube Proxy"
  value       = aws_eks_addon.kube_proxy.arn
}

output "ebs_csi_addon_arn" {
  description = "Amazon EKS add-on ARN for EBS CSI Driver"
  value       = aws_eks_addon.ebs_csi.arn
}

# Random Suffix for Reference
output "resource_suffix" {
  description = "Random suffix used for resource naming"
  value       = random_string.suffix.result
}

# Connection Information
output "cluster_connection_info" {
  description = "Complete connection information for the EKS cluster"
  value = {
    cluster_name     = aws_eks_cluster.main.name
    cluster_endpoint = aws_eks_cluster.main.endpoint
    cluster_arn      = aws_eks_cluster.main.arn
    region          = var.region
    aws_auth_config_map = "kubectl apply -f aws-auth-configmap.yaml"
    kubectl_config      = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}"
  }
  sensitive = true
}

# Resource Summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    vpc = {
      id         = aws_vpc.main.id
      cidr_block = aws_vpc.main.cidr_block
    }
    cluster = {
      name     = aws_eks_cluster.main.name
      arn      = aws_eks_cluster.main.arn
      version  = aws_eks_cluster.main.version
      endpoint = aws_eks_cluster.main.endpoint
    }
    node_groups = {
      system = {
        name   = aws_eks_node_group.system.node_group_name
        status = aws_eks_node_group.system.status
      }
      application = {
        name   = aws_eks_node_group.application.node_group_name
        status = aws_eks_node_group.application.status
      }
    }
    ecr = {
      name = aws_ecr_repository.main.name
      url  = aws_ecr_repository.main.repository_url
    }
    monitoring = {
      log_group = aws_cloudwatch_log_group.eks_cluster.name
    }
  }
}

# Kubectl Commands
output "kubectl_commands" {
  description = "Useful kubectl commands for cluster management"
  value = {
    update_kubeconfig = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}"
    get_nodes        = "kubectl get nodes"
    get_pods         = "kubectl get pods --all-namespaces"
    get_services     = "kubectl get services --all-namespaces"
    cluster_info     = "kubectl cluster-info"
    get_configmap    = "kubectl get configmap aws-auth -n kube-system -o yaml"
  }
}