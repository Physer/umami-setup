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
param logAnalyticsWorkspaceName string
param applicationInsightsName string
param virtualNetworkGatewayPublicIpName string
param virtualNetworkGatewayName string
param dnsPrivateResolverName string
param vpnAddressSpace string
param keyVaultName string
param keyVaultPrivateEndpointName string
param deployVpnGateway bool

// Key Vault secret names
var databaseUsernameSecretName = 'postgresDatabaseUsername'
var databasePasswordSecretName = 'postgresDatabasePassword'
var databaseConnectionStringSecretName = 'postgresDatabaseConnectionString'
var appSecretName = 'umamiAppSecret'
var pgAdminEmailAddressSecretName = 'pgAdminEmailAddress'
var pgAdminPasswordSecretName = 'pgAdminPassword'

// Role Assignment Definitions
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

// Networking
module virtualNetwork './modules/virtualNetwork.bicep' = {
  name: 'deployVirtualNetwork'
  params: {
    applicationName: virtualNetworkName
  }
}

module dnsPrivateResolver 'modules/dnsPrivateResolver.bicep' = if (deployVpnGateway) {
  name: 'deployDnsPrivateResolver'
  params: {
    dnsResolverName: dnsPrivateResolverName
    virtualNetworkName: virtualNetwork.outputs.resourceName
    inboundSubnetName: virtualNetwork.outputs.dnsPrivateResolverInboundSubnetName
    outboundSubnetName: virtualNetwork.outputs.dnsPrivateResolverOutboundSubnetName
  }
}

module virtualNetworkGatewayPublicIp 'modules/publicIp.bicep' = if (deployVpnGateway) {
  name: 'deployVpnPublicIp'
  params: {
    publicIpName: virtualNetworkGatewayPublicIpName
  }
}

module virtualNetworkGateway 'modules/virtualNetworkGateway.bicep' = if (deployVpnGateway) {
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
  params: {
    keyVaultName: keyVaultName
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    virtualNetworkName: virtualNetworkName
    subnetName: virtualNetwork.outputs.keyVaultSubnetName
  }
}

module keyVaultPrivateDns 'modules/privateDnsZone.bicep' = {
  name: 'deployKeyVaultPrivateDns'
  params: {
    privateDnsZoneFqdn: 'privatelink.vaultcore.azure.net'
    virtualNetworkName: virtualNetwork.outputs.resourceName
  }
}

module keyVaultPrivateDnsARecord 'modules/privateDnsARecord.bicep' = {
  name: 'deployKeyVaultPrivateDnsARecord'
  params: {
    privateDnsZoneFqdn: keyVaultPrivateDns.outputs.resourceName
    networkInterfaceName: keyVault.outputs.privateEndpointNetworkInterfaceName
    dnsRecordName: keyVaultName
  }
}

resource keyVaultReference 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = {
  name: keyVaultName
  dependsOn: [keyVault]
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
module postgresDatabasePrivateDns 'modules/privateDnsZone.bicep' = {
  name: 'deployPostgresDatabasePrivateDns'
  params: {
    privateDnsZoneFqdn: '${postgresServerName}.private.postgres.database.azure.com'
    virtualNetworkName: virtualNetwork.outputs.resourceName
  }
}

module postgresDatabase 'modules/postgres.bicep' = {
  name: 'deployPostgresDatabase'
  params: {
    resourceName: postgresServerName
    virtualNetworkName: virtualNetwork.outputs.resourceName
    postgresSubnetName: virtualNetwork.outputs.postgresSubnetName
    privateDnsZoneResourceId: postgresDatabasePrivateDns.outputs.resourceId
    administratorUsername: keyVaultReference.getSecret(databaseUsernameSecretName)
    administratorPassword: keyVaultReference.getSecret(databasePasswordSecretName)
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
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${databaseConnectionStringSecretName})'
      }
      {
        name: 'APP_SECRET'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${appSecretName})'
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

module pgAdminAppService 'modules/dockerAppService.bicep' = if (deployPgAdmin && !empty(pgAdminAppServiceName)) {
  name: 'deployPgAdminAppService'
  params: {
    appServiceName: pgAdminAppServiceName!
    appServicePlanId: appServicePlan.outputs.resourceId
    appSettings: [
      {
        name: 'PGADMIN_DEFAULT_EMAIL'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${pgAdminEmailAddressSecretName})'
      }
      {
        name: 'PGADMIN_DEFAULT_PASSWORD'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${pgAdminPasswordSecretName})'
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
  params: {
    keyVaultName: keyVaultName
    principalId: umamiAppService.outputs.principalId
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
  }
}

module pgAdminAppServiceKeyVaultRoleAssignment 'modules/roleAssignments/keyVaultRoleAssignment.bicep' = if (deployPgAdmin) {
  name: 'deployPgAdminAppServiceKeyVaultRoleAssignment'
  params: {
    keyVaultName: keyVaultName
    principalId: pgAdminAppService!.outputs.principalId
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
  }
}
