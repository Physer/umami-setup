using '../deployUmami.bicep'

// Environment definition
var environment = 'local'

// Global parameters
param appServicePlanSkuTier = 'Basic'
param appServicePlanSkuSize = 'B1'
param appServicePlanSkuFamily = 'B'
param umamiDatabaseName = 'umami'

// Environment-specific parameters
param appServicePlanName = 'plan-analytics-${environment}'
param umamiAppServiceName = 'app-umami-${environment}'
param postgresServerName = 'psql-umami-${environment}'
param virtualNetworkName = 'vnet-analytics-${environment}'
param applicationInsightsName = 'appi-analytics-${environment}'
param logAnalyticsWorkspaceName = 'log-analytics-${environment}'
param virtualNetworkGatewayPublicIpName = 'pip-vpn-analytics-${environment}'
param virtualNetworkGatewayName = 'vgw-analytics-${environment}'
param dnsPrivateResolverName = 'dnspr-analytics-${environment}'

// Admin tools parameters
param deployPgAdmin = true
param pgAdminAppServiceName = 'app-pgadmin-${environment}'
param pgAdminEmail = 'admin@local-analytics.com'
param pgAdminPassword = 'g4MdT24B?HB)A1&b6r8n4Gi4'

// Secure parameters
param databaseUsername = 'psqladmin'
param databasePassword = 'No%5`RB1vu,R3RM~OsN;24Sa'
param appSecret = 'CxpBgns+9<S63&0@6}l@28<M'
