targetScope = 'subscription'

param location string = deployment().location
param environment string = 'local'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-schouls-umami-${environment}'
  location: location
}

module virtualNetwork './modules/virtualNetwork.bicep' = {
  name: 'deployVirtualNetwork'
  scope: resourceGroup
}

module appService './modules/appservice.bicep' = {
  name: 'deployAppService'
  scope: resourceGroup
  params: {
    virtualNetworkName: virtualNetwork.outputs.resourceName
    subnetName: virtualNetwork.outputs.appServiceSubnetName
  }
}
