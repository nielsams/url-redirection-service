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
param customDomain string


// This account has been deployed by another sub deployment
resource datastorage 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
}

var tableName = 'redirectionurls'
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${datastorage.name};AccountKey=${datastorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
var azureAdRedirectUri = 'https://${customDomain}/admin/signin-oidc'


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
              name: 'STORAGE_TABLE_NAME'
              value: tableName
            }
            {
              name: 'STORAGE_CONNECTION_STRING'
              value: storageConnectionString
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
              name: 'RedirectTable__TableName'
              value: tableName
            }
            {
              name: 'RedirectTable__ConnectionString'
              value: storageConnectionString
            }
            {
              name: 'AzureAd__Domain'
              value: adminDomain
            }
            {
              name: 'AzureAd__TenantId'
              value: adminTenantId
            }
            {
              name: 'AzureAd__ClientId'
              value: adminClientId
            }
            {
              name: 'AzureAd__RedirectUri'
              value: azureAdRedirectUri
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
          port: 8080
          protocol: 'TCP'
        }
        {
          port: 80
          protocol: 'TCP'
        }
      ]
    }
  }
}

output containerIPAddress string = containerGroup.properties.ipAddress.ip
