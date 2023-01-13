variable "aks_location" {
  default = "westeurope"
}

variable "rg_name" {
  default = "rg-aks-"
}

variable "aks_purpose" {
  default = "evangelion"
}

variable "ssh_public_key" {
  default = "/Users/vitor.duarte/.ssh/id_rsa.pub"
}