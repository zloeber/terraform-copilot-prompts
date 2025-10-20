# User data script for Azure VMs
locals {
  cloud_init_config = base64encode(templatefile("${path.module}/cloud-init.yml", {
    storage_account_name = azurerm_storage_account.wordpress.name
    container_name       = azurerm_storage_container.wordpress_data.name
  }))
}

# Network Interfaces for VMs
resource "azurerm_network_interface" "web_servers" {
  count = length(var.availability_zones) * var.vm_count_per_zone

  name                = "${var.project_name}-vm-${count.index + 1}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private[count.index % length(var.availability_zones)].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-vm-${count.index + 1}-nic"
  })
}

# Data Disks for /opt mount
resource "azurerm_managed_disk" "data_disks" {
  count = length(var.availability_zones) * var.vm_count_per_zone

  name                 = "${var.project_name}-vm-${count.index + 1}-data-disk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  zone                 = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(var.tags, {
    Name = "${var.project_name}-vm-${count.index + 1}-data-disk"
  })
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "web_servers" {
  count = length(var.availability_zones) * var.vm_count_per_zone

  name                = "${var.project_name}-vm-${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  zone                = var.availability_zones[count.index % length(var.availability_zones)]

  # Disable password authentication
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.web_servers[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username = var.admin_username

  # SSH key (required even though we'll use managed identity)
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Custom data for initialization
  custom_data = local.cloud_init_config

  tags = merge(var.tags, {
    Name = "${var.project_name}-vm-${count.index + 1}"
    Type = "WebServer"
    Zone = var.availability_zones[count.index % length(var.availability_zones)]
  })

  depends_on = [
    azurerm_storage_account.wordpress
  ]
}

# Attach data disks to VMs
resource "azurerm_virtual_machine_data_disk_attachment" "data_disks" {
  count = length(azurerm_linux_virtual_machine.web_servers)

  managed_disk_id    = azurerm_managed_disk.data_disks[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.web_servers[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

# Generate SSH key for VMs (stored in Terraform state)
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}