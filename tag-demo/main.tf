provider "azurerm" {
  features {}
}

module "networking" {
  source = "./modules/networking"
  address_space = "10.0.0.0/16"
  tags = local.tags
}

module "compute" {
  source = "./modules/compute"
  vm_size = "Standard_B2s"
  tags = local.tags
}

module "storage" {
  source = "./modules/storage"
  account_tier = "Standard"
  tags = local.tags
}
