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
