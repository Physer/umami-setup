param location string = resourceGroup().location

param applicationName string
param virtualNetworkName string
param containerSubnetName string

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2025-02-02-preview' = {
  name: applicationName
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
    vnetConfiguration: {
      infrastructureSubnetId: resourceId(
        'Microsoft.Network/virtualNetworks/subnets',
        virtualNetworkName,
        containerSubnetName
      )
    }
  }
}

output resourceId string = containerAppEnvironment.id
