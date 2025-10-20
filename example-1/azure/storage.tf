# Storage Account for shared storage
resource "azurerm_storage_account" "wordpress" {
  name                     = "${var.project_name}storage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable blob versioning
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 30
    }
  }

  # Network access rules
  network_rules {
    default_action             = "Allow"
    virtual_network_subnet_ids = azurerm_subnet.private[*].id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-storage"
  })
}

# Storage Container for WordPress files
resource "azurerm_storage_container" "wordpress_data" {
  name                 = "wordpress-data"
  storage_account_id   = azurerm_storage_account.wordpress.id
  container_access_type = "private"
}

# Role assignment for VMs to access storage
resource "azurerm_role_assignment" "vm_storage_contributor" {
  count = length(azurerm_linux_virtual_machine.web_servers)

  scope                = azurerm_storage_account.wordpress.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.web_servers[count.index].identity[0].principal_id
}