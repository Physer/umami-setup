param location string = resourceGroup().location

param applicationName string

var containerSubnetName = 'containerapp'
var postgresSubnetName = 'postgres'
var appServiceSubnetName = 'appservice'
var keyVaultSubnetName = 'keyvault'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: applicationName
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
      {
        name: appServiceSubnetName
        properties: {
          addressPrefix: '10.0.4.0/24'
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
      {
        name: keyVaultSubnetName
        properties: {
          addressPrefix: '10.0.5.0/24'
        }
      }
    ]
  }
}

output resourceId string = virtualNetwork.id
output postgresSubnetName string = postgresSubnetName
output containerSubnetName string = containerSubnetName
output appServiceSubnetName string = appServiceSubnetName
output keyVaultSubnetName string = keyVaultSubnetName
