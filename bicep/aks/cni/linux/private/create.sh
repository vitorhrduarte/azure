# Create Resource Group
az group create -l WestEurope -n rg-aks-lab01

# Deploy template with in-line parameters
az deployment group create -g rg-aks-lab01  --template-uri https://github.com/Azure/AKS-Construction/releases/download/0.8.8/main.json --parameters \
	resourceName=aks-lab01 \
	SystemPoolType=Standard \
	custom_vnet=true \
	serviceCidr=10.10.10.0/24 \
	dnsServiceIP=10.10.10.10 \
	vnetAddressPrefix=10.10.0.0/16 \
	vnetAksSubnetAddressPrefix=10.10.0.0/23 \
	availabilityZones="[\"1\",\"2\",\"3\"]" \
	enablePrivateCluster=true


