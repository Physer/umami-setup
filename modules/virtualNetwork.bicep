param location string = resourceGroup().location

var appServiceSubnetName = 'appservice'

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
        name: appServiceSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

output resourceName string = virtualNetwork.name
output appServiceSubnetName string = appServiceSubnetName
