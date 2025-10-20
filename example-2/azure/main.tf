# Azure Kubernetes Service with Private Networking and Container Registry
# This configuration creates a private AKS cluster with ACR integration

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Data source to get current Azure client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_prefix}-rg-${random_string.suffix.result}"
  location = var.location

  tags = var.tags
}

# User Assigned Managed Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.resource_prefix}-aks-identity-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_prefix}-vnet-${random_string.suffix.result}"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Subnet for AKS nodes
resource "azurerm_subnet" "aks_nodes" {
  name                 = "aks-nodes-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_address_prefix]

  # Required for private AKS clusters
  private_endpoint_network_policies = "Disabled"
}

# Subnet for AKS pods (when using advanced networking)
resource "azurerm_subnet" "aks_pods" {
  name                 = "aks-pods-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.pod_subnet_address_prefix]

  delegation {
    name = "Microsoft.ContainerService.managedClusters"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Private DNS Zone for AKS
resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Link private DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "aks-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = var.tags
}

# Role assignment for AKS identity to manage private DNS zone
resource "azurerm_role_assignment" "aks_dns_contributor" {
  scope                = azurerm_private_dns_zone.aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Role assignment for AKS identity to manage network resources
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${var.resource_prefix}acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Premium" # Premium required for private endpoints
  admin_enabled       = false     # Use managed identity instead

  # Enable private networking
  public_network_access_enabled = false

  # Premium features
  zone_redundancy_enabled = true

  # Network rules to allow AKS subnet access
  network_rule_set {
    default_action = "Deny"
    
    # Allow access from AKS subnet
    ip_rule {
      action   = "Allow"
      ip_range = var.aks_subnet_address_prefix
    }
  }

  tags = var.tags
}

# Private endpoint for ACR
resource "azurerm_private_endpoint" "acr" {
  name                = "${var.resource_prefix}-acr-pe-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.aks_nodes.id

  private_service_connection {
    name                           = "acr-private-connection"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  tags = var.tags
}

# Private DNS Zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Link ACR private DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = var.tags
}

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.resource_prefix}-aks-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.resource_prefix}-aks-${random_string.suffix.result}"
  kubernetes_version  = var.kubernetes_version

  # Private cluster configuration
  private_cluster_enabled = true
  private_dns_zone_id     = azurerm_private_dns_zone.aks.id

  # Managed identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Default node pool configuration
  default_node_pool {
    name                 = "default"
    vm_size              = var.node_vm_size
    node_count           = var.min_node_count
    auto_scaling_enabled = true
    min_count            = var.min_node_count
    max_count            = var.max_node_count
    max_pods             = var.max_pods_per_node
    os_disk_size_gb      = var.os_disk_size_gb
    os_disk_type         = "Ephemeral"
    
    # Network configuration
    vnet_subnet_id = azurerm_subnet.aks_nodes.id
    pod_subnet_id  = azurerm_subnet.aks_pods.id

    # Enable only critical addons on system node pool
    only_critical_addons_enabled = true

    # Upgrade settings for minimal disruption
    upgrade_settings {
      max_surge                     = "1"
      drain_timeout_in_minutes      = 10
      node_soak_duration_in_minutes = 5
    }

    tags = var.tags
  }

  # Network profile for advanced networking
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
    
    # Use internal load balancer
    load_balancer_profile {
      outbound_ip_address_ids = []
    }
  }

  # Enable auto-scaling
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay          = "10s"
    scale_down_delay_after_add      = "10m"
    scale_down_delay_after_delete   = "20s"
    scale_down_delay_after_failure  = "3m"
    scan_interval                   = "10s"
    scale_down_unneeded             = "10m"
    scale_down_unready              = "20m"
    scale_down_utilization_threshold = 0.5
  }

  # Enable Azure Monitor for containers
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.main.id
    msi_auth_for_monitoring_enabled = true
  }

  # Enable Azure Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Enable Azure Policy
  azure_policy_enabled = true

  # Security and compliance features
  role_based_access_control_enabled = true
  local_account_disabled            = false # Keep enabled for staging
  
  # Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = merge(var.tags, {
    "aks-managed-cluster-name" = "${var.resource_prefix}-aks-${random_string.suffix.result}"
  })

  # Ensure proper dependency order
  depends_on = [
    azurerm_role_assignment.aks_dns_contributor,
    azurerm_role_assignment.aks_network_contributor,
    azurerm_private_dns_zone_virtual_network_link.aks
  ]
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.resource_prefix}-log-analytics-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # Appropriate for staging environment

  tags = var.tags
}

# Application node pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "application" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.node_vm_size
  node_count            = var.min_node_count
  auto_scaling_enabled  = true
  min_count             = var.min_node_count
  max_count             = var.max_node_count

  # Network configuration
  vnet_subnet_id = azurerm_subnet.aks_nodes.id
  pod_subnet_id  = azurerm_subnet.aks_pods.id

  # Node configuration
  max_pods        = var.max_pods_per_node
  os_disk_size_gb = var.os_disk_size_gb
  os_disk_type    = "Ephemeral"

  # Taints for application workloads
  node_taints = ["workload=apps:NoSchedule"]

  # Node labels
  node_labels = {
    "workload" = "applications"
    "tier"     = "standard"
  }

  # Upgrade settings
  upgrade_settings {
    max_surge                     = "1"
    drain_timeout_in_minutes      = 10
    node_soak_duration_in_minutes = 5
  }

  tags = var.tags

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Network Security Group for AKS subnet
resource "azurerm_network_security_group" "aks" {
  name                = "${var.resource_prefix}-aks-nsg-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow internal AKS communication
  security_rule {
    name                       = "AllowAKSInternal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.aks_subnet_address_prefix
    destination_address_prefix = var.aks_subnet_address_prefix
  }

  # Allow HTTPS from pods subnet
  security_rule {
    name                       = "AllowHTTPSFromPods"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.pod_subnet_address_prefix
    destination_address_prefix = var.aks_subnet_address_prefix
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with AKS subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks_nodes.id
  network_security_group_id = azurerm_network_security_group.aks.id
}