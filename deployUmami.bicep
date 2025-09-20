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

// Role Assignment Definitions
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
}

// Networking
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

// Key Vault
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

// Application Insights and Azure Monitoring
module monitoring 'modules/monitoring.bicep' = {
  name: 'deployMonitoring'
  scope: resourceGroup
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
}

// Database
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

// App Services
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

// Role Assignments
module umamiAppServiceKeyVaultRoleAssignment 'modules/roleAssignments/keyVaultRoleAssignment.bicep' = {
  name: 'deployUmamiAppServiceKeyVaultRoleAssignment'
  scope: resourceGroup
  params: {
    keyVaultName: keyVaultName
    principalId: umamiAppService.outputs.principalId
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
  }
}

module pgAdminAppServiceKeyVaultRoleAssignment 'modules/roleAssignments/keyVaultRoleAssignment.bicep' = if (deployPgAdmin) {
  name: 'deployPgAdminAppServiceKeyVaultRoleAssignment'
  scope: resourceGroup
  params: {
    keyVaultName: keyVaultName
    principalId: pgAdminAppService!.outputs.principalId
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
  }
}
