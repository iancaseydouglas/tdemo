resource "azurerm_resource_group" "networking" {
  name     = "networking-rg"
  location = "eastus"
  tags = var.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "main-vnet"
  address_space       = [var.address_space]
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  tags = var.tags
}
