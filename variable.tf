
resource "azurerm_resource_group" "lab-resources" {
  name     = "lab-resources"
  location = "eastus"
}


resource "azurerm_virtual_network" "netlab" {
  name                = "subnetlab-network"
  address_space       = ["10.92.0.0/16"]
  location            = azurerm_resource_group.lab-resources.location
  resource_group_name = azurerm_resource_group.lab-resources.name
}

resource "azurerm_subnet" "inside_net" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.lab-resources.name
  virtual_network_name = azurerm_virtual_network.netlab.name
  address_prefixes     = ["10.92.2.0/24"]
}


resource "azurerm_public_ip" "public_ip" {
  name                = "vm_public_ip"
  resource_group_name = azurerm_resource_group.lab-resources.name
  location            = azurerm_resource_group.lab-resources.location
  allocation_method   = "Dynamic"
}




resource "azurerm_network_interface" "ipint" {
  name                = "server-nic"
  location            = azurerm_resource_group.lab-resources.location
  resource_group_name = azurerm_resource_group.lab-resources.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.inside_net.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}




resource "azurerm_windows_virtual_machine" "DC" {
  name                = "DC01"
  resource_group_name = azurerm_resource_group.lab-resources.name
  location            = azurerm_resource_group.lab-resources.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.ipint.id,
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

resource "azurerm_network_security_group" "secgrp" {
  name                = "netsecgrp"
  location            = azurerm_resource_group.lab-resources.location
  resource_group_name = azurerm_resource_group.lab-resources.name

  security_rule {
    name                   = "RDP"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = 3389
  }

}

resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.ipint.id
  network_security_group_id = azurerm_network_security_group.secgrp.id
}


resource "azurerm_public_ip_prefix" "public_ip" {
  name                = "acceptanceTestPublicIpPrefix1"
  location            = azurerm_resource_group.lab-resources.location
  resource_group_name = azurerm_resource_group.lab-resources.name
  prefix_length       = 31

  tags = {
    environment = "Production"
  }
}