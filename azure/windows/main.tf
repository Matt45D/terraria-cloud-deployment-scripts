locals {
  file_name             = "terraria-config.ps1"
  file_destination      = "C:/Terraria/terraria-config.ps1"
  powershell_parameters = ""
  powershell_command    = "powershell.exe -ExecutionPolicy Unrestricted -File ${local.file_name}${local.powershell_parameters}"
}

resource "azurerm_resource_group" "windows" {
  name     = var.resource_group_name
  location = var.location
}

data "http" "myip" {
  url = "https://ipinfo.io/ip"
}

data "template_file" "terraria-config-script" {
    template = file("${path.module}/terraria-config.ps1")
}

resource "azurerm_virtual_network" "windows" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["168.63.129.16", "10.0.1.4"]
  depends_on          = ["azurerm_resource_group.windows"]
}

resource "azurerm_subnet" "windows" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefix       = "10.0.1.0/24"
  depends_on           = ["azurerm_resource_group.windows", "azurerm_virtual_network.windows"]
}

resource "azurerm_public_ip" "windows" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  depends_on          = ["azurerm_resource_group.windows"]
}

resource "azurerm_network_interface" "windows" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "terraria-ip-configurations"
    subnet_id                     = azurerm_subnet.windows.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.windows.id
  }
  depends_on = ["azurerm_public_ip.windows"]
}

resource "azurerm_network_security_group" "windows" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowTerraria"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "7777"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = chomp(data.http.myip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWinRM"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = chomp(data.http.myip.body)
    destination_address_prefix = "*"
  }
  depends_on = ["azurerm_resource_group.windows"]
}

resource "azurerm_subnet_network_security_group_association" "windows" {
  subnet_id                 = azurerm_subnet.windows.id
  network_security_group_id = azurerm_network_security_group.windows.id
}

resource "azurerm_storage_account" "windows" {
  name                     = "terrariastorageaccount"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on               = ["azurerm_resource_group.windows"]
}

resource "azurerm_storage_container" "windows" {
  name                  = "content"
  storage_account_name  = azurerm_storage_account.windows.name
  container_access_type = "blob"
  depends_on               = ["azurerm_storage_account.windows"]
}

resource "azurerm_storage_blob" "windows" {
  name                   = "terraria-config.ps1"
  storage_account_name   = azurerm_storage_account.windows.name
  storage_container_name = azurerm_storage_container.windows.name
  type                   = "Block"
  source                 = "terraria-config.ps1"
  depends_on             = ["azurerm_storage_container.windows"]
}

resource "azurerm_windows_virtual_machine" "windows" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.vm_admin_name
  admin_password      = var.vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.windows.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "execute-terraria-config" {
  name                 = "terraria-config-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
  {
    "fileUris": ["${azurerm_storage_blob.windows.url}"]
  }
SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
  {
    "commandToExecute": "\"${local.powershell_command}\""
  }
PROTECTED_SETTINGS
}