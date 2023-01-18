provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name        = "${var.aks_specifics.aks_rg_name_prefix}${var.aks_name}" 
  location    = var.aks_location
  tags        = {
         "env" = var.aks_cluster_tags.env
         "purpose" = var.aks_cluster_tags.purpose
         "provider" = var.aks_cluster_tags.provider
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.aks_network.vnet_main
  address_space       = var.aks_network.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks-snet" {
  name                 = var.aks_network.snet_aks
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.aks_network.snet_aks_address_space
}

resource "azurerm_subnet" "vm-snet" {
  name                 = var.aks_network.snet_vm
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.aks_network.snet_vm_address_space
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                    = "${var.aks_specifics.aks_name_prefix}${var.aks_name}"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = "${var.aks_specifics.aks_name_prefix}${var.aks_name}"
  kubernetes_version      = var.aks_version

  role_based_access_control_enabled = var.aks_specifics.aks_enabled_rbac

  linux_profile {
    admin_username = var.linux_windows_profile.linux_user
    
    ssh_key {
      key_data = file(var.linux_windows_profile.linux_user_pub_key)
    }
  }
 
  windows_profile {
    admin_username = var.linux_windows_profile.windows_user
    admin_password = var.linux_windows_profile.windows_user_password
  }

  network_profile {
    network_plugin    = var.aks_specifics.aks_network_plugin
    load_balancer_sku = var.aks_specifics.aks_network_lb_sku
    network_policy    = var.aks_specifics.aks_network_policy
  }  
  
  default_node_pool {
    name       = var.aks_sys_nodepool_specifics.name
    node_count = var.aks_sys_nodepool_specifics.node_count
    vm_size    = var.aks_sys_nodepool_specifics.vm_size
    max_pods   = var.aks_sys_nodepool_specifics.max_pods
    type       = var.aks_sys_nodepool_specifics.type
    tags = {
      "env-vmss" = var.aks_cluster_tags.env
    }
  }

  identity {
    type = var.aks_specifics.aks_identity_type
  }

  tags = {
    "env" = var.aks_cluster_tags.env
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "aks-np" {
  name                  = var.aks_user_nodepool_specifics.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-cluster.id
  vm_size               = var.aks_user_nodepool_specifics.vm_size
  node_count            = var.aks_user_nodepool_specifics.node_count
  max_pods              = var.aks_user_nodepool_specifics.max_pods
  mode                  = var.aks_user_nodepool_specifics.mode
  node_labels           = {
    "env" = var.aks_cluster_tags.env
  }

  orchestrator_version = "1.25.4"
  os_disk_size_gb = "40"
  os_disk_type = "Ephemeral"
  os_sku = "Ubuntu"

  max_count             = 2
  min_count             = 1
  enable_auto_scaling   = "true"


  os_type = "Linux"
  priority = "Regular"
  zones = [1, 2, 3]

  tags = {
    "env-vmss" = "dev"
  }
}