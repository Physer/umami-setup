targetScope = 'subscription'

param location string = deployment().location
param deployAdminTools bool = false

param resourceGroupName string
param containerAppEnvironmentName string
param umamiContainerAppName string
param pgAdminContainerAppName string?
param postgresServerName string
param umamiDatabaseName string
param virtualNetworkName string

@secure()
param databaseUsername string
@secure()
param databasePassword string
@secure()
param appSecret string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
}

module virtualNetwork './modules/virtualNetwork.bicep' = {
  name: 'deployVirtualNetwork'
  scope: resourceGroup
  params: {
    applicationName: virtualNetworkName
  }
}
module privateDns 'modules/privatedns.bicep' = {
  name: 'deployPrivateDns'
  scope: resourceGroup
  params: {
    postgresDatabaseResouceName: postgresServerName
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
    resourceName: postgresServerName
    virtualNetworkName: virtualNetworkName
    postgresSubnetName: virtualNetwork.outputs.postgresSubnetName
    privateDnsZoneResourceId: privateDns.outputs.resourceId
    administratorUsername: databaseUsername
    administratorPassword: databasePassword
    databaseName: umamiDatabaseName
  }
}

module containerAppEnvironment 'modules/containerAppEnvironment.bicep' = {
  name: 'deployContainerAppEnvironment'
  scope: resourceGroup
  params: {
    applicationName: containerAppEnvironmentName
    virtualNetworkName: virtualNetworkName
    containerSubnetName: virtualNetwork.outputs.containerSubnetName
  }
}

module umamiContainerApp 'modules/containerApp.bicep' = {
  name: 'deployContainerApp'
  scope: resourceGroup
  params: {
    containerAppEnvironmentId: containerAppEnvironment.outputs.resourceId
    applicationName: umamiContainerAppName
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
        value: 'postgresql://${databaseUsername}:${databasePassword}@${postgresDatabase.outputs.serverFqdn}/${umamiDatabaseName}'
      }
      {
        name: 'APP_SECRET'
        value: appSecret
      }
    ]
  }
}
