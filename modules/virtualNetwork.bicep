param location string = resourceGroup().location

var containerSubnetName = 'containerapp'
var postgresSubnetName = 'postgres'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'vnet-schouls-umami-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'postgres'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'postgresDelegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
      {
        name: containerSubnetName
        properties: {
          addressPrefix: '10.0.2.0/23'
        }
      }
    ]
  }
}

output resourceId string = virtualNetwork.id
output resourceName string = virtualNetwork.name
output postgresSubnetName string = postgresSubnetName
output containerSubnetName string = containerSubnetName
