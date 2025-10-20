# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.azure_region

  tags = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-vnet"
  })
}

# Public Subnets for Application Gateway
resource "azurerm_subnet" "public" {
  count = length(var.public_subnet_prefixes)

  name                 = "${var.project_name}-public-subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_prefixes[count.index]]
}

# Private Subnets for Virtual Machines
resource "azurerm_subnet" "private" {
  count = length(var.private_subnet_prefixes)

  name                 = "${var.project_name}-private-subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_prefixes[count.index]]
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway" {
  name                = "${var.project_name}-nat-gateway-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-gateway-pip"
  })
}

# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  name                = "${var.project_name}-nat-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"
  zones               = var.availability_zones

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-gateway"
  })
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

# Associate NAT Gateway with Private Subnets
resource "azurerm_subnet_nat_gateway_association" "private" {
  count = length(azurerm_subnet.private)

  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main.id
}