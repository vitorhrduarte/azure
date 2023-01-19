variable "aks_linux_username" {
  type = string
  sensitive = true  
  description = "Env Var for Linux User Name"
  }

variable "aks_linux_username_pubkey" {
  type = string
  sensitive = true
  description = "Env Var for Linux User Name Pub Key Path" 
}

variable "aks_windows_username" {
  type = string
  sensitive = true
  description = "Env Var for Windows User Name"
}

variable "aks_windows_username_password" {
  type = string
  sensitive = true
  description = "Env Var for Windows User Name Password"
}

variable "aks_location" {
  type = string
  default = "westeurope"
  description = "AKS Location" 
}

variable "aks_name" {
  type = string
  default = "change-me"
  description = "AKS Name"
}

variable "aks_version" {
  type = string
  description = "AKS Version"
}

variable "aks_sys_nodepool_specifics" {
  type = map
  default = {
    name       = "sysnp01"
    node_count = "1"
    vm_size    = "Standard_D2_v2"
    max_pods   = "30"
    type       = "VirtualMachineScaleSets" 
  }
}

variable "aks_user_nodepool_specifics" {
  type = object ({
    name = string
    vm_size = string
    node_count = string
    max_pods = string
    mode = string
    os_disk_size_gb = number
    os_disk_type = string
    os_sku = string
    max_count = number
    min_count = number
    enable_auto_scaling = bool
    os_type = string
    priority = string
    zones = list(string)
  })

  default = {
    name       = "usrnp01" 
    vm_size    = "Standard_DS2_v2" 
    node_count = "1"
    max_pods   = "30"
    mode       = "User"
    os_disk_size_gb     = 40
    os_disk_type        = "Ephemeral" 
    os_sku              = "Ubuntu"
    max_count           = 2
    min_count           = 1
    enable_auto_scaling = true
    os_type             =  "Linux"
    priority            = "Regular"
    zones               = ["1","2","3"]
  }
}

variable "aks_specifics" {
  type = map
  default = {
    aks_rg_name_prefix   = "rg-aks-"
    aks_name_prefix      = "aks-"
    aks_enabled_rbac     = "true"
    aks_network_plugin   = "azure"
    aks_network_lb_sku   = "standard"
    aks_network_policy   = "calico"
    aks_identity_type    = "SystemAssigned"
  }
}

variable "aks_cluster_tags" {
  type = map
  default = {
    env      = "dev"
    purpose  = "learn"
    provider = "terraform"
  }
}

variable "aks_network" {
  type = object ({
    vnet_main              = string
    vnet_address_space     = list(string)
    snet_aks               = string
    snet_aks_address_space = list(string)
    snet_vm                = string
    snet_vm_address_space  = list(string)
  })

  default = {
      vnet_main              = "vnet-main"
      vnet_address_space     = ["10.0.0.0/16"]
      snet_aks               = "snet-aks"
      snet_aks_address_space = ["10.0.0.0/21"]
      snet_vm                = "snet-vm"
      snet_vm_address_space  = ["10.0.8.0/24"]
  }
}
