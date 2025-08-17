param location string = resourceGroup().location
param skuName string = 'Standard_B1ms'
param skuTier string = 'Burstable'
param storageSizeInGb int = 32
param backupRetentionDays int = 7

param resourceName string
param virtualNetworkName string
param postgresSubnetName string
param privateDnsZoneResourceId string

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers@2025-01-01-preview' = {
  name: resourceName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: '15'
    administratorLogin: 'psqladmin'
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: tenant().tenantId
    }
    network: {
      delegatedSubnetResourceId: resourceId(
        'Microsoft.Network/virtualNetworks/subnets',
        virtualNetworkName,
        postgresSubnetName
      )
      privateDnsZoneArmResourceId: privateDnsZoneResourceId
      publicNetworkAccess: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    storage: {
      storageSizeGB: storageSizeInGb
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: 'Disabled'
    }
  }
}
