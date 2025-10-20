# Network Security Group for Application Gateway
resource "azurerm_network_security_group" "app_gateway" {
  name                = "${var.project_name}-appgw-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # HTTP access from Internet
  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS access from Internet
  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Application Gateway infrastructure ports
  security_rule {
    name                       = "AppGwInfra"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-appgw-nsg"
  })
}

# Network Security Group for Virtual Machines
resource "azurerm_network_security_group" "vms" {
  name                = "${var.project_name}-vm-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # HTTP access from Application Gateway subnet
  security_rule {
    name                       = "HTTP_from_AppGW"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = var.public_subnet_prefixes
    destination_address_prefix = "*"
  }

  # HTTPS access from Application Gateway subnet
  security_rule {
    name                       = "HTTPS_from_AppGW"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.public_subnet_prefixes
    destination_address_prefix = "*"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-vm-nsg"
  })
}

# Associate NSG with Public Subnets
resource "azurerm_subnet_network_security_group_association" "public" {
  count = length(azurerm_subnet.public)

  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.app_gateway.id
}

# Associate NSG with Private Subnets
resource "azurerm_subnet_network_security_group_association" "private" {
  count = length(azurerm_subnet.private)

  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.vms.id
}