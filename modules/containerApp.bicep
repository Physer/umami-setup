import { environmentVariable } from '../types/environmentVariable.bicep'

param location string = resourceGroup().location
param cpu string = '0.5'
param memory string = '1Gi'

param containerAppEnvironmentId string
param imageName string
param imageTag string
param applicationName string
param targetPort int
param environmentVariables environmentVariable[]

resource containerApp 'Microsoft.App/containerApps@2025-02-02-preview' = {
  name: applicationName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        allowInsecure: false
        external: true
        targetPort: targetPort
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
          name: applicationName
          env: environmentVariables
          image: '${imageName}:${imageTag}'
          resources: {
            cpu: json(cpu)
            memory: memory
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
