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

resource adminContainerApp 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'redirectadmin'
  location: location
  kind: 'containerapp'
  properties: {
    kubeEnvironmentId: containerEnv.id
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
          name: 'webappContainer'
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


resource containerEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' = {
  name: '${nameprefix}containerenv'
  location: location
  properties: {
    // not recognized but type is required
    type: 'managed'
    internalLoadBalancerEnabled:false
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

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: '${nameprefix}container'
  location: location
  properties: {
    containers: [
      {
        name: 'redirectadmin'
        properties: {
          image: adminimage
          environmentVariables: [
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
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
        }
      }
    ]
    imageRegistryCredentials: [
      {
        password: acrPassword
        server: acrServer
        username: acrUser
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
    }
  }
}

output containerIPAddress string = containerGroup.properties.ipAddress.ip
output containerUrl string = adminContainerApp.properties.configuration.ingress.fqdn
