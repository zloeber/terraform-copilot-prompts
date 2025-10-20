# Data source to get the latest Ubuntu 22.04 LTS image
data "azurerm_platform_image" "ubuntu" {
  location  = var.azure_region
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
}

# Generate a random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}