param nameprefix string
param location string = resourceGroup().location
param image string
param storageAccountName string
param acrServer string
param acrUser string
@secure()
param acrPassword string


// This account has been deployed by another sub deployment
resource datastorage 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
}


resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: '${nameprefix}container'
  location: location
  properties: {
    containers: [
      {
        name: 'redirector'
        properties: {
          image: image
          environmentVariables: [
            {
              'name': 'STORAGE_TABLE_NAME'
              'value': 'redirectionurls'
            }
            {
              'name': 'STORAGE_CONNECTION_STRING'
              'value': 'DefaultEndpointsProtocol=https;AccountName=${datastorage.name};AccountKey=${datastorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
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
      ]
    }
  }
}

output containerIPAddress string = containerGroup.properties.ipAddress.ip
