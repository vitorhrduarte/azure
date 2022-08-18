param location string
param clusterName string

param nodeCount int = 3
param vmSize string = 'standard_d2s_v3'

resource aks 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: '${clusterName}snp01'
        count: nodeCount
        vmSize: vmSize
        mode: 'System'
      }
    ]
  }
}
