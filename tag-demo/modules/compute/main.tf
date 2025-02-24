resource "azurerm_resource_group" "compute" {
  name     = "compute-rg"
  location = "eastus"
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.compute.name
  location            = azurerm_resource_group.compute.location
  size                = var.vm_size
  admin_username      = "adminuser"
  network_interface_ids = ["dummy-id"]

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa DUMMY-KEY-FOR-DEMO"
    tags = var.tags
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
  tags = var.tags
}
