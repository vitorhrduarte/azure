provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name = "${var.rg_name}${var.aks_purpose}"
  location = var.aks_location
  tags = {
    "env" = "dev"
    "purpose" = "learn"
    "provider" = "terraform"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-main"
  address_space       = ["10.0.0.0/16"]
  location            =  var.aks_location
  resource_group_name =  azurerm_resource_group.rg.name
}