param location string = resourceGroup().location

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: 'id-schouls-umami-${uniqueString(resourceGroup().id)}'
  location: location
}
