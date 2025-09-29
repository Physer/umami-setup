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
param virtualNetworkGatewayPublicIpName string
param virtualNetworkGatewayName string
param dnsPrivateResolverName string
param vpnAddressSpace string
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

// Networking
module virtualNetwork './modules/virtualNetwork.bicep' = {
  name: 'deployVirtualNetwork'
  params: {
    applicationName: virtualNetworkName
  }
}

module privateDns 'modules/privateDnsZone.bicep' = {
  name: 'deployPrivateDns'
  params: {
    postgresDatabaseResourceName: postgresServerName
    virtualNetworkName: virtualNetwork.outputs.resourceName
  }
}

module dnsPrivateResolver 'modules/dnsPrivateResolver.bicep' = {
  name: 'deployDnsPrivateResolver'
  params: {
    dnsResolverName: dnsPrivateResolverName
    virtualNetworkName: virtualNetwork.outputs.resourceName
    inboundSubnetName: virtualNetwork.outputs.dnsPrivateResolverInboundSubnetName
    outboundSubnetName: virtualNetwork.outputs.dnsPrivateResolverOutboundSubnetName
  }
}

module virtualNetworkGatewayPublicIp 'modules/publicIp.bicep' = {
  name: 'deployVpnPublicIp'
  params: {
    publicIpName: virtualNetworkGatewayPublicIpName
  }
}

module virtualNetworkGateway 'modules/virtualNetworkGateway.bicep' = {
  name: 'deployVpnGateway'
  params: {
    virtualNetworkName: virtualNetwork.outputs.resourceName
    subnetName: virtualNetwork.outputs.vpnSubnetName
    publicIpName: virtualNetworkGatewayPublicIpName
    virtualNetworkGatewayName: virtualNetworkGatewayName
    vpnAddressSpace: vpnAddressSpace
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
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
}

// Database
module postgresDatabase 'modules/postgres.bicep' = {
  name: 'deployPostgresDatabase'
  params: {
    resourceName: postgresServerName
    virtualNetworkName: virtualNetwork.outputs.resourceName
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
  params: {
    appServicePlanId: appServicePlan.outputs.resourceId
    imageName: 'ghcr.io/umami-software/umami'
    imageTag: 'postgresql-latest'
    appServiceName: umamiAppServiceName
    subnetName: virtualNetwork.outputs.appServiceSubnetName
    virtualNetworkName: virtualNetwork.outputs.resourceName
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
    virtualNetworkName: virtualNetwork.outputs.resourceName
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
