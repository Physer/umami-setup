param postgresDatabaseResourceName string
param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: virtualNetworkName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: '${postgresDatabaseResourceName}.private.postgres.database.azure.com'
  location: 'global'
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: uniqueString(virtualNetwork.id)
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}

output resourceId string = privateDnsZone.id
output resourceName string = privateDnsZone.name
