variable "resource_group_name" {
  type = "string"
  description = "Name of the resource group which will contain all deployments"
  default = "terraria-RG"
}

variable "location" {
  type = "string"
  description = "Name of the location of the deployment"
  default = "eastus"
}

variable "vnet_name" {
  type = "string"
  description = "Name of the virtual network"
  default = "terraria-VNET"
}

variable "subnet_name" {
  type = "string"
  description = "Name of the sub network"
  default = "terraria-SUBNET"
}

variable "vm_name" {
  type = "string"
  description = "Name of the terraria server (maximum 15 characters)"
  default = "terraria-VM"
}

variable "vm_size" {
  type = "string"
  description = "Size of the virtual machine used to deploy the terraria server (default meets minimum requirements to host large worl)"
  default = "Standard_B1ms"
}

variable "vm_admin_name" {
  type = "string"
  description = "Login name of the admin user for the virtual machine"
  default = "adminTerraria"
}

variable "vm_admin_password" {
  type = "string"
  description = "Password of the admin user for the virtual machine"
  default = "sTroNg1357pAsSwOrD"
}

variable "nic_name" {
  type = "string"
  description = "Name of the network integrated card"
  default = "terraria-NIC"
}

variable "nsg_name" {
  type = "string"
  description = "Name of the network security group"
  default = "terraria-NSG"
}


variable "public_ip_name" {
  type = "string"
  description = "Name of the public ip address"
  default = "terraria-public-IP"
}











