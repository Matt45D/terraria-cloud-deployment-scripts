output "terraria-server-public-ip" {
  value = azurerm_public_ip.windows.ip_address
}