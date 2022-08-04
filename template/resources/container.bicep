param nameprefix string
param location string = resourceGroup().location
param image string
param storageAccountName string
param acrServer string
param acrUser string
@secure()
param acrPassword string

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: '${nameprefix}redircontainer'
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
              'value': 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName, '2021-08-01').keys[0].value}'
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
              cpu: '1'
              memoryInGB: '1.5'
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
