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

resource "azurerm_subnet" "aks-snet" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/21"]
}

resource "azurerm_subnet" "vm-snet" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.8.0/24"]
}


resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                    = "aks-${var.aks_purpose}"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix = "aks-${var.aks_purpose}"

  kubernetes_version = "1.25.4"
  
  linux_profile {
    admin_username = "gits"
    
    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }  
  
  
  default_node_pool {
    name       = "sysnp01"
    node_count = "1"
    vm_size    = "Standard_D2_v2"
    max_pods = "30"
    type = "VirtualMachineScaleSets"
    
    tags = {
      "env-vmss" = "dev"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    "env" = "Production"
  }

}