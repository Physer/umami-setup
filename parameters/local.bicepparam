using '../deployUmami.bicep'

// Environment definition
var environment = 'local'

// Global parameters
param appServicePlanSkuTier = 'Basic'
param appServicePlanSkuSize = 'B1'
param appServicePlanSkuFamily = 'B'
param umamiDatabaseName = 'umami'

// Environment-specific parameters
param resourceGroupName = 'rg-schouls-analytics-${environment}'
param appServicePlanName = 'plan-schouls-analytics-${environment}'
param umamiAppServiceName = 'app-schouls-umami-${environment}'
param postgresServerName = 'psql-schouls-umami-${environment}'
param virtualNetworkName = 'vnet-schouls-analytics-${environment}'

// Secure parameters
param databaseUsername = 'psqladmin'
param databasePassword = 'P@ssw0rd!'
param appSecret = 'P@ssw0rd!'
