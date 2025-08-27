param location string = resourceGroup().location

param skuSize string
param skuTier string
param skuFamily string
param appServicePlanName string

resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuSize
    tier: skuTier
    size: skuSize
    family: skuFamily
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

output resourceId string = appServicePlan.id
