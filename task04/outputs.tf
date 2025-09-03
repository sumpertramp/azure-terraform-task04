output "vm_public_ip" {
  description = "VM'in Public IP adresi"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_fqdn" {
  description = "VM'in FQDN değeri"
  value       = azurerm_public_ip.pip.fqdn
}
