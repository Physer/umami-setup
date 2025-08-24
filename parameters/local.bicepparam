using '../deployUmami.bicep'

var environment = 'local'

param resourceGroupName = 'rg-schouls-analytics-${environment}'
param containerAppEnvironmentName = 'cae-schouls-analytics-${environment}'
param umamiContainerAppName = 'ca-schouls-umami-${environment}'
param pgAdminContainerAppName = 'ca-schouls-pgadmin-${environment}'
param postgresServerName = 'psql-schouls-umami-${environment}'
param umamiDatabaseName = 'umami'
param virtualNetworkName = 'vnet-schouls-analytics-${environment}'

param databaseUsername = 'psqladmin'
param databasePassword = 'P@ssw0rd!'
param appSecret = 'P@ssw0rd!'
