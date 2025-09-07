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
param deployPgAdmin bool
param pgAdminAppServiceName string?
param pgAdminEmail string?
param pgAdminPassword string?
param logAnalyticsWorkspaceName string
param applicationInsightsName string
param keyVaultName string
param keyVaultPrivateEndpointName string

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

module keyVault 'modules/keyVault.bicep' = {
  name: 'deployKeyVault'
  scope: resourceGroup
  params: {
    keyVaultName: keyVaultName
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    virtualNetworkName: virtualNetworkName
    subnetName: virtualNetwork.outputs.keyVaultSubnetName
  }
}

module privateDns 'modules/privatedns.bicep' = {
  name: 'deployPrivateDns'
  scope: resourceGroup
  params: {
    postgresDatabaseResourceName: postgresServerName
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

module monitoring 'modules/monitoring.bicep' = {
  name: 'deployMonitoring'
  scope: resourceGroup
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
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
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
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
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
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
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: monitoring.outputs.applicationInsightsConnectionString
      }
      {
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~3'
      }
      {
        name: 'XDT_MicrosoftApplicationInsights_Mode'
        value: 'Recommended'
      }
    ]
  }
}

module pgAdminAppService 'modules/dockerAppService.bicep' = if (deployPgAdmin && !empty(pgAdminAppServiceName) && !empty(pgAdminEmail) && !empty(pgAdminPassword)) {
  name: 'deployPgAdminAppService'
  scope: resourceGroup
  params: {
    appServiceName: pgAdminAppServiceName!
    appServicePlanId: appServicePlan.outputs.resourceId
    appSettings: [
      {
        name: 'PGADMIN_DEFAULT_EMAIL'
        value: pgAdminEmail!
      }
      {
        name: 'PGADMIN_DEFAULT_PASSWORD'
        value: pgAdminPassword!
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: monitoring.outputs.applicationInsightsConnectionString
      }
      {
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~3'
      }
      {
        name: 'XDT_MicrosoftApplicationInsights_Mode'
        value: 'Recommended'
      }
    ]
    imageName: 'dpage/pgadmin4'
    imageTag: 'latest'
    subnetName: virtualNetwork.outputs.appServiceSubnetName
    virtualNetworkName: virtualNetworkName
  }
}
