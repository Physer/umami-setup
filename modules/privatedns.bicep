param postgresDatabaseResouceName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: '${postgresDatabaseResouceName}.private.postgres.database.azure.com'
  location: 'global'
}

output resourceId string = privateDnsZone.id
