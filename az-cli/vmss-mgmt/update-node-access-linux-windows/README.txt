Needed Vars:
ADMIN_USERNAME_SSH_KEYS_PUB
[Need to have full path to the *.pub part of the SSH key pair]



Hardcoded values:
In this command:
az vmss run-command invoke --command-id RunPowerShellScript --name aksnpwin --resource-group $AKS_RG_NPOOL \
        --scripts '$sp = ConvertTo-SecureString "P@ssword!123" -AsPlainText -Force; New-LocalUser -Password $sp -Name "tmp-gits"; Add-LocalGroupMember -Group Administrators -Member "tmp-gits"' \
        --instance-id $i

ConvertTo-SecureString "P@ssword!123"
-Name "tmp-gits"


Notes:
In a linux node, if no user/access was defined a default user named azureuser is created.
Need to adapt:
VMSS_SSH_SUDO_USER=$GENERIC_ADMIN_USERNAME
