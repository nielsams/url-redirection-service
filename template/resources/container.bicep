param nameprefix string
param location string = resourceGroup().location
param adminimage string
param storageAccountName string
param acrServer string
param acrUser string
@secure()
param acrPassword string

@secure()
param adminTenantId string
@secure()
param adminClientId string
@secure()
param adminAuthDomain string

// This account has been deployed by another sub deployment
resource datastorage 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
}

var tableName = 'redirectionurls'
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${datastorage.name};AccountKey=${datastorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'

resource adminContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: '${nameprefix}admin'
  location: location
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      secrets: [
        {
          name: 'container-registry-password'
          value: acrPassword
        }
      ]      
      registries: [
        {
          server: acrServer
          username: acrUser
          passwordSecretRef: 'container-registry-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          image: adminimage
          name: 'adminwebapp'
          env: [
            {
              name: 'RedirectTable__TableName'
              value: tableName
            }
            {
              name: 'RedirectTable__ConnectionString'
              value: storageConnectionString
            }
            {
              name: 'AzureAd__Domain'
              value: adminAuthDomain
            }
            {
              name: 'AzureAd__TenantId'
              value: adminTenantId
            }
            {
              name: 'AzureAd__ClientId'
              value: adminClientId
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}


resource containerEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: '${nameprefix}containerenv'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: la.properties.customerId
        sharedKey: la.listKeys().primarySharedKey
      }
    }
  }
}

resource la 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${nameprefix}logs' 
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

output containerUrl string = adminContainerApp.properties.configuration.ingress.fqdn
