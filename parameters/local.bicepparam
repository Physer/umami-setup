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

// Admin tools parameters
param deployPgAdmin = true
param pgAdminAppServiceName = 'app-schouls-pgadmin-${environment}'
param pgAdminEmail = 'admin@alexschouls.com'
param pgAdminPassword = 'P@ssw0rd!'

// Secure parameters
param databaseUsername = 'psqladmin'
param databasePassword = 'P@ssw0rd!'
param appSecret = 'P@ssw0rd!'
