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

  api_server_authorized_ip_ranges = var.aks_local_pip

  role_based_access_control_enabled = var.aks_specifics.aks_enabled_rbac

  linux_profile {
    admin_username = var.aks_linux_username
    
    ssh_key {
      key_data = file(var.aks_linux_username_pubkey)
    }
  }
  windows_profile {
    admin_username = var.aks_windows_username
    admin_password = var.aks_windows_username_password
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

  orchestrator_version = var.aks_version
  os_disk_size_gb      = var.aks_user_nodepool_specifics.os_disk_size_gb
  os_disk_type         = var.aks_user_nodepool_specifics.os_disk_type
  os_sku               = var.aks_user_nodepool_specifics.os_sku

  max_count            = var.aks_user_nodepool_specifics.max_count 
  min_count            = var.aks_user_nodepool_specifics.min_count
  enable_auto_scaling  = var.aks_user_nodepool_specifics.enable_auto_scaling

  os_type              = var.aks_user_nodepool_specifics.os_type
  priority             = var.aks_user_nodepool_specifics.priority
  zones                = var.aks_user_nodepool_specifics.zones

  tags = {
    "env-vmss" = "dev"
  }
}