targetScope = 'subscription'

param location string = deployment().location
param environment string
@secure()
param databaseUsername string
@secure()
param databasePassword string
@secure()
param appSecret string

var applicationName = 'analytics-${uniqueString(subscription().id)}'
var databaseResourceName = 'psql-${applicationName}'
var databaseName = 'umami'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-analytics-${environment}'
  location: location
}

module virtualNetwork './modules/virtualNetwork.bicep' = {
  name: 'deployVirtualNetwork'
  scope: resourceGroup
  params: {
    applicationName: applicationName
  }
}
module privateDns 'modules/privatedns.bicep' = {
  name: 'deployPrivateDns'
  scope: resourceGroup
  params: {
    postgresDatabaseResouceName: databaseResourceName
  }
}

module virtualNetworkLink 'modules/virtualNetworkLink.bicep' = {
  name: 'deployVirtualNetworkLink'
  scope: resourceGroup
  params: {
    privateDnsZoneName: privateDns.outputs.resourceName
    virtualNetworkId: virtualNetwork.outputs.resourceId
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

module containerAppEnvironment 'modules/containerAppEnvironment.bicep' = {
  name: 'deployContainerAppEnvironment'
  scope: resourceGroup
  params: {
    applicationName: applicationName
    virtualNetworkName: virtualNetwork.outputs.resourceName
    containerSubnetName: virtualNetwork.outputs.containerSubnetName
  }
}

module umamiContainerApp 'modules/containerApp.bicep' = {
  name: 'deployContainerApp'
  scope: resourceGroup
  params: {
    containerAppEnvironmentId: containerAppEnvironment.outputs.resourceId
    applicationName: applicationName
    imageName: 'ghcr.io/umami-software/umami'
    imageTag: 'postgresql-latest'
    targetPort: 3000
    environmentVariables: [
      {
        name: 'DATABASE_TYPE'
        value: 'postgresql'
      }
      {
        name: 'DATABASE_URL'
        value: 'postgresql://${databaseUsername}:${databasePassword}@${postgresDatabase.outputs.serverFqdn}/${databaseName}'
      }
      {
        name: 'APP_SECRET'
        value: appSecret
      }
    ]
  }
}
