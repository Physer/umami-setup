targetScope = 'subscription'

param location string = deployment().location

param resourceGroupName string
param appServicePlanName string
param appServicePlanSkuTier string
param appServicePlanSkuSize string
param appServicePlanSkuFamily string
param umamiAppServiceName string
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

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'deployAppServicePlan'
  scope: resourceGroup
  params: {
    appServicePlanName: appServicePlanName
    skuFamily: appServicePlanSkuFamily
    skuSize: appServicePlanSkuSize
    skuTier: appServicePlanSkuTier
  }
}

module umamiAppService 'modules/dockerAppService.bicep' = {
  name: 'deployUmamiAppService'
  scope: resourceGroup
  params: {
    appServicePlanId: appServicePlan.outputs.resourceId
    imageName: 'ghcr.io/umami-software/umami'
    imageTag: 'postgresql-latest'
    appServiceName: umamiAppServiceName
    subnetName: virtualNetwork.outputs.appServiceSubnetName
    virtualNetworkName: virtualNetworkName
    appSettings: [
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
