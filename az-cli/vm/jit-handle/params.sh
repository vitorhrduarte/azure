## Azure VM Settings
AZURE_VM="ljs"
AZURE_VM_LOCATION="westeurope"
AZURE_VM_JIT_CREATION_NAME="jit-vm.json"
AZURE_VM_JIT_INITIATE_NAME="jit-vm-post.json"
AZURE_VM_WINDOWS_PORT="3389"
AZURE_VM_LINUX_PORT="22"
AZURE_VM_JIT_DURATION="P1D" # 1 DAY, for hours use: PT6H


## Azure Token
AZURE_TOKEN=$(az account get-access-token --query accessToken -o tsv)

## Local Settings
MY_ISP_IP=$(curl -s https://ifconfig.io)

## Az VM Jit Policy Name
AZ_VM_JIT_POL_NAME="default"
