locals {
  jb_name = format("%s-jb", var.aks_name)
}

# https://www.terraform.io/docs/providers/azurerm/r/resource_group.html
resource "azurerm_resource_group" "rg_jb" {
  name     = local.jb_name
  location = var.location
}

# https://www.terraform.io/docs/providers/azurerm/r/virtual_network.html
resource "azurerm_virtual_network" "vnet_jb" {
  name                = local.jb_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_jb.name
  address_space       = [var.jb_vnet_address_prefix]
}

# https://www.terraform.io/docs/providers/azurerm/r/subnet.html
resource "azurerm_subnet" "subnet_jb" {
  name                 = "subnet_jb"
  resource_group_name  = azurerm_resource_group.rg_jb.name
  virtual_network_name = azurerm_virtual_network.vnet_jb.name
  address_prefixes     = [var.jb_subnet_address_prefix]
}

resource "azurerm_subnet" "subnet_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg_jb.name
  virtual_network_name = azurerm_virtual_network.vnet_jb.name
  address_prefixes       = [var.bastion_subnet_address_prefix]
}

# https://www.terraform.io/docs/providers/azurerm/r/network_interface.html
resource "azurerm_network_interface" "nic_jb" {
  name                = local.jb_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_jb.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_jb.id
    private_ip_address_allocation = "Dynamic"
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/linux_virtual_machine.html
resource "azurerm_linux_virtual_machine" "vm_jb" {
  name                = local.jb_name
  resource_group_name = azurerm_resource_group.rg_jb.name
  location            = var.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.nic_jb.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/virtual_network_peering.html
resource "azurerm_virtual_network_peering" "vnet_peering_jb_aks" {
  name                      = "jumpbox-aks"
  resource_group_name       = azurerm_resource_group.rg_jb.name
  virtual_network_name      = azurerm_virtual_network.vnet_jb.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_aks.id
}

resource "azurerm_virtual_network_peering" "vnet_peering_aks_jb" {
  name                      = "aks-jumpbox"
  resource_group_name       = azurerm_resource_group.rg_aks.name
  virtual_network_name      = azurerm_virtual_network.vnet_aks.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_jb.id
}

# https://www.terraform.io/docs/providers/external/data_source.html
data "external" "get_aks_private_dns_zone_name" {
  program = ["/bin/sh", "${path.module}/getAksPrivateDnsZoneName.sh"]

  query = {
    aksNodesResourceGroup = azurerm_kubernetes_cluster.aks.node_resource_group
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/private_dns_zone_virtual_network_link.html
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_vnet_link_aks_jb" {
  name                  = local.jb_name
  resource_group_name   = azurerm_kubernetes_cluster.aks.node_resource_group
  private_dns_zone_name = data.external.get_aks_private_dns_zone_name.result.aks_private_dns_zone
  virtual_network_id    = azurerm_virtual_network.vnet_jb.id
  registration_enabled  = false
}

resource "azurerm_public_ip" "bastion_host_ip_jb" {
  name                = "bastion_host_ip_jb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_jb.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# https://www.terraform.io/docs/providers/azurerm/r/bastion_host.html
resource "azurerm_bastion_host" "bastion_host_jb" {
  name                = "bastion_host_jb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_jb.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_host_ip_jb.id
  }
}