resource "azurerm_resource_group" "storage" {
  name     = "storage-rg"
  location = "eastus"
  tags = var.tags
}

resource "azurerm_storage_account" "example" {
  name                     = "demostorageaccount"
  resource_group_name      = azurerm_resource_group.storage.name
  location                 = azurerm_resource_group.storage.location
  account_tier             = var.account_tier
  account_replication_type = "LRS"
  tags = var.tags
}
