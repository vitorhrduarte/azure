targetScope = 'subscription'

param location string = 'westeurope'
param resourceSufix string = 'bicep'

var resourceGroupName = 'rg-aks-${resourceSufix}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module aks './aks-cluster.bicep' = {
  name: 'aks-${resourceSufix}'
  scope: rg
  params: {
    location: location
    clusterName: resourceSufix
  }
}
