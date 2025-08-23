param location string = resourceGroup().location

param containerAppEnvironmentId string
@secure()
param appSecret string
@secure()
param databaseConnectionString string

var containerAppName = 'ca-schouls-umami-${uniqueString(resourceGroup().id)}'
var imageName = 'ghcr.io/umami-software/umami'
var imageTag = 'postgresql-latest'

resource containerApp 'Microsoft.App/containerApps@2025-02-02-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        allowInsecure: false
        external: true
        targetPort: 3000
        targetPortHttpScheme: 'https'
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
            label: 'production'
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: containerAppName
          env: [
            {
              name: 'DATABASE_TYPE'
              value: 'postgresql'
            }
            {
              name: 'DATABASE_URL'
              value: databaseConnectionString
            }
            {
              name: 'APP_SECRET'
              value: appSecret
            }
          ]
          image: '${imageName}:${imageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
}
