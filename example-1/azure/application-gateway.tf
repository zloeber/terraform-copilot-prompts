# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gateway" {
  name                = "${var.project_name}-appgw-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = merge(var.tags, {
    Name = "${var.project_name}-appgw-pip"
  })
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "${var.project_name}-appgw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  zones = var.availability_zones

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.public[0].id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    
    probe_name = "health-probe"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "https-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }

  request_routing_rule {
    name               = "https-redirect-rule"
    rule_type          = "Basic"
    http_listener_name = "https-listener"
    redirect_configuration_name = "https-redirect"
    priority           = 200
  }

  redirect_configuration {
    name                 = "https-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "http-listener"
    include_path         = true
    include_query_string = true
  }

  probe {
    name                = "health-probe"
    protocol            = "Http"
    path                = "/health"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = ["200"]
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-appgw"
  })

  depends_on = [
    azurerm_subnet_network_security_group_association.public
  ]
}

# Backend Address Pool Association
resource "azurerm_application_gateway_backend_address_pool_address" "web_servers" {
  count = length(azurerm_linux_virtual_machine.web_servers)

  name                    = "vm-${count.index + 1}"
  backend_address_pool_id = tolist(azurerm_application_gateway.main.backend_address_pool)[0].id
  ip_address              = azurerm_network_interface.web_servers[count.index].private_ip_address
}