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
