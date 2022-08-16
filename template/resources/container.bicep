param nameprefix string
param location string = resourceGroup().location
param redirectorimage string
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
param adminDomain string


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
        name: 'redirector'
        properties: {
          image: redirectorimage
          environmentVariables: [
            {
              'name': 'STORAGE_TABLE_NAME'
              'value': tableName
            }
            {
              'name': 'STORAGE_CONNECTION_STRING'
              'value': storageConnectionString
            }

          ]
          ports: [
            {
              port: 8080
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
      {
        name: 'redirectadmin'
        properties: {
          image: adminimage
          environmentVariables: [
            {
              'name': 'RedirectTable:TableName'
              'value': tableName
            }
            {
              'name': 'RedirectTable:ConnectionString'
              'value': storageConnectionString
            }
            {
              'name': 'AzureAd:Domain'
              'value': adminDomain
            }
            {
              'name': 'AzureAd:TenantId'
              'value': adminTenantId
            }
            {
              'name': 'AzureAd:ClientId'
              'value': adminClientId
            }
            
          ]
          ports: [
            {
              port: 8088
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
          port: 8080
          protocol: 'TCP'
        }
        {
          port: 8088
          protocol: 'TCP'
        }
      ]
    }
  }
}

output containerIPAddress string = containerGroup.properties.ipAddress.ip
