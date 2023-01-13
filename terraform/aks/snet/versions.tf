terraform {
  required_version = ">= 1.3.7"

  required_providers {
    #kubernetes = ">= 1.11.1"
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.38.0"
    }
  }
}