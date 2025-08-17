targetScope = 'subscription'

param location string = deployment().location
param environment string = 'local'

@secure()
param databaseUsername string
@secure()
param databasePassword string
@secure()
param appSecret string

var databaseResourceName = 'psql-schouls-umami-${uniqueString(subscription().id)}'
var databaseName = 'umami'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-schouls-umami-${environment}'
  location: location
}

module virtualNetwork './modules/virtualNetwork.bicep' = {
  name: 'deployVirtualNetwork'
  scope: resourceGroup
}
module privateDns 'modules/privatedns.bicep' = {
  name: 'deployPrivateDns'
  scope: resourceGroup
  params: {
    postgresDatabaseResouceName: databaseResourceName
  }
}

module postgresDatabase 'modules/postgres.bicep' = {
  name: 'deployPostgresDatabase'
  scope: resourceGroup
  params: {
    resourceName: databaseResourceName
    virtualNetworkName: virtualNetwork.outputs.resourceName
    postgresSubnetName: virtualNetwork.outputs.postgresSubnetName
    privateDnsZoneResourceId: privateDns.outputs.resourceId
    administratorUsername: databaseUsername
    administratorPassword: databasePassword
    databaseName: databaseName
  }
}

module appService './modules/appservice.bicep' = {
  name: 'deployAppService'
  scope: resourceGroup
  params: {
    virtualNetworkName: virtualNetwork.outputs.resourceName
    subnetName: virtualNetwork.outputs.appServiceSubnetName
    appSecret: appSecret
    databaseConnectionString: 'postgresql://${databaseUsername}:${databasePassword}@${postgresDatabase.outputs.serverFqdn}/${databaseName}'
  }
}
