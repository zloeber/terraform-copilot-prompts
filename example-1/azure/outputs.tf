# Output values for the Azure infrastructure

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = azurerm_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = azurerm_subnet.private[*].id
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "application_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.fqdn
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.wordpress.name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.wordpress.primary_blob_endpoint
}

output "storage_container_name" {
  description = "Name of the storage container"
  value       = azurerm_storage_container.wordpress_data.name
}

output "vm_names" {
  description = "Names of the virtual machines"
  value       = azurerm_linux_virtual_machine.web_servers[*].name
}

output "vm_private_ips" {
  description = "Private IP addresses of the virtual machines"
  value       = azurerm_network_interface.web_servers[*].private_ip_address
}

output "vm_zones" {
  description = "Availability zones of the virtual machines"
  value       = azurerm_linux_virtual_machine.web_servers[*].zone
}

output "vm_ids" {
  description = "IDs of the virtual machines"
  value       = azurerm_linux_virtual_machine.web_servers[*].id
}

output "network_security_group_appgw_id" {
  description = "ID of the Application Gateway network security group"
  value       = azurerm_network_security_group.app_gateway.id
}

output "network_security_group_vms_id" {
  description = "ID of the VMs network security group"
  value       = azurerm_network_security_group.vms.id
}

# Access information
output "application_url" {
  description = "URL to access the application via Application Gateway"
  value       = "http://${azurerm_public_ip.app_gateway.ip_address}"
}

output "ssh_private_key" {
  description = "SSH private key for VM access (sensitive)"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_connection_commands" {
  description = "Commands to connect to VMs via SSH (for emergency access)"
  value = {
    for i, vm in azurerm_linux_virtual_machine.web_servers : vm.name => "ssh -i private_key.pem ${var.admin_username}@${azurerm_network_interface.web_servers[i].private_ip_address}"
  }
}

output "azure_cli_vm_connect_commands" {
  description = "Commands to connect to VMs using Azure CLI"
  value = {
    for vm in azurerm_linux_virtual_machine.web_servers : vm.name => "az vm run-command invoke --resource-group ${azurerm_resource_group.main.name} --name ${vm.name} --command-id RunShellScript --scripts 'echo Connected to ${vm.name}'"
  }
}

output "bastion_connection_info" {
  description = "Information for setting up Azure Bastion (manual setup required)"
  value = {
    resource_group = azurerm_resource_group.main.name
    vnet_name      = azurerm_virtual_network.main.name
    vm_names       = azurerm_linux_virtual_machine.web_servers[*].name
    note           = "Deploy Azure Bastion to the VNet for secure VM access via Azure portal"
  }
}