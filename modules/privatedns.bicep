param postgresDatabaseResourceName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: '${postgresDatabaseResourceName}.private.postgres.database.azure.com'
  location: 'global'
}

output resourceId string = privateDnsZone.id
output resourceName string = privateDnsZone.name
