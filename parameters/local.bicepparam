using '../deployUmami.bicep'

// Environment definition
var environment = 'local'

// Global parameters
param umamiDatabaseName = 'umami'
param vpnAddressSpace = '172.16.0.0/24'

// Environment-specific parameters
param appServicePlanSkuTier = 'Basic'
param appServicePlanSkuSize = 'B1'
param appServicePlanSkuFamily = 'B'
param appServicePlanName = 'plan-analytics-${environment}'
param umamiAppServiceName = 'app-umami-${environment}'
param postgresServerName = 'psql-umami-${environment}'
param virtualNetworkName = 'vnet-analytics-${environment}'
param applicationInsightsName = 'appi-analytics-${environment}'
param logAnalyticsWorkspaceName = 'log-analytics-${environment}'
param virtualNetworkGatewayPublicIpName = 'pip-vpn-analytics-${environment}'
param virtualNetworkGatewayName = 'vgw-analytics-${environment}'
param dnsPrivateResolverName = 'dnspr-analytics-${environment}'
param keyVaultName = 'kv-analytics-${environment}'
param keyVaultPrivateEndpointName = 'pe-kv-analytics-${environment}'
param deployVpnGateway = false

// Admin tools parameters
param deployPgAdmin = true
param pgAdminAppServiceName = 'app-pgadmin-${environment}'
