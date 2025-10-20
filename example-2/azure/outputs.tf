# Outputs for Azure Kubernetes Service Infrastructure

# Resource Group Information
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.main.location
}

# Network Information
output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID of the AKS nodes subnet"
  value       = azurerm_subnet.aks_nodes.id
}

output "pod_subnet_id" {
  description = "ID of the AKS pods subnet"
  value       = azurerm_subnet.aks_pods.id
}

# AKS Cluster Information
output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_cluster_private_fqdn" {
  description = "Private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "aks_cluster_node_resource_group" {
  description = "Name of the auto-generated resource group containing AKS cluster resources"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "aks_cluster_identity" {
  description = "Identity information of the AKS cluster"
  value = {
    type         = azurerm_kubernetes_cluster.main.identity[0].type
    principal_id = azurerm_kubernetes_cluster.main.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.main.identity[0].tenant_id
  }
}

output "aks_kubelet_identity" {
  description = "Kubelet identity information"
  value = {
    client_id                 = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].user_assigned_identity_id
  }
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for the AKS cluster (for Workload Identity)"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

# Container Registry Information
output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

# Log Analytics Information
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# Private DNS Zones
output "aks_private_dns_zone_id" {
  description = "ID of the AKS private DNS zone"
  value       = azurerm_private_dns_zone.aks.id
}

output "acr_private_dns_zone_id" {
  description = "ID of the ACR private DNS zone"
  value       = azurerm_private_dns_zone.acr.id
}

# Kubernetes Configuration (Sensitive)
output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Raw kubeconfig for the AKS cluster admin"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Structured kubeconfig for the AKS cluster"
  value = length(azurerm_kubernetes_cluster.main.kube_config) > 0 ? {
    host                   = azurerm_kubernetes_cluster.main.kube_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
    client_key            = azurerm_kubernetes_cluster.main.kube_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
    username              = azurerm_kubernetes_cluster.main.kube_config[0].username
    password              = azurerm_kubernetes_cluster.main.kube_config[0].password
  } : null
  sensitive = true
}

# Connection Information
output "connection_instructions" {
  description = "Instructions for connecting to the AKS cluster"
  value = <<-EOT
    To connect to the AKS cluster:

    1. Configure kubectl:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}

    2. Verify connection:
       kubectl get nodes

    3. Access container registry:
       az acr login --name ${azurerm_container_registry.main.name}

    4. Push/pull images:
       docker tag myapp:latest ${azurerm_container_registry.main.login_server}/myapp:latest
       docker push ${azurerm_container_registry.main.login_server}/myapp:latest

    Note: This is a private cluster. Ensure you're connected to the VNet or using a jumpbox.
  EOT
}

# Infrastructure Summary
output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    cluster_type           = "Private AKS Cluster"
    kubernetes_version     = azurerm_kubernetes_cluster.main.kubernetes_version
    node_count_range      = "${var.min_node_count}-${var.max_node_count} nodes"
    node_vm_size          = var.node_vm_size
    networking            = "Azure CNI with private endpoints"
    container_registry    = "Private ACR with Premium tier"
    monitoring            = "Azure Monitor for Containers"
    load_balancer_type    = "Internal (Private)"
    auto_scaling          = "Enabled"
    environment           = var.environment
    tags                  = var.tags
  }
}

# Security Information
output "security_features" {
  description = "Security features enabled on the cluster"
  value = {
    private_cluster           = azurerm_kubernetes_cluster.main.private_cluster_enabled
    azure_policy             = var.enable_azure_policy
    workload_identity        = var.enable_workload_identity
    oidc_issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_enabled
    rbac_enabled             = azurerm_kubernetes_cluster.main.role_based_access_control_enabled
    network_policy           = "Azure"
    private_acr              = "Enabled with private endpoint"
    managed_identity         = "User Assigned"
  }
}