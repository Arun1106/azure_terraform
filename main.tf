# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}
# creating resource group
resource "azurerm_resource_group" "myrg" {
  name     = "arunrg1"
  location = "West Europe"
}
# creating virtual network
resource "azurerm_virtual_network" "myvnet" {
  name                = "firstvnet"
  address_space       = ["192.0.0.0/16"]
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}
# creating subnet1
resource "azurerm_subnet" "subnet1" {
  name                 = "internal1"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["192.0.0.0/17"]
}
# creating subnet2
resource "azurerm_subnet" "subnet2" {
  name                 = "internal2"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["192.0.128.0/17"]
}
# creating public ip address
resource "azurerm_public_ip" "newpublicip" {
    name                         = "newpublicip"
    location                     = azurerm_resource_group.myrg.location
    resource_group_name          = azurerm_resource_group.myrg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}
# creating network_security_group
resource "azurerm_network_security_group" "newnsg" {
    name                = "newnsg"
    location            = azurerm_resource_group.myrg.location
    resource_group_name = azurerm_resource_group.myrg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
	security_rule {
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}
# Create network interface
resource "azurerm_network_interface" "newnic" {
    name                      = "myNIC"
    location                  = azurerm_resource_group.myrg.location
    resource_group_name       = azurerm_resource_group.myrg.name

    ip_configuration {
        name                          = "nicconfig"
        subnet_id                     = azurerm_subnet.subnet1.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.newpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}
# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.newnic.id
    network_security_group_id = azurerm_network_security_group.newnsg.id
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "myvm" {
    name                  = "mynewvm"
    location              = azurerm_resource_group.myrg.location
    resource_group_name   = azurerm_resource_group.myrg.name
    network_interface_ids = [azurerm_network_interface.newnic.id]
    size                  = "Standard_B2s"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     =file("~/.ssh/id_rsa.pub")
    }


    tags = {
        environment = "Terraform Demo"
    }
	

}
