@description('First part of the resource name')
param nameprefix string

@description('Azure region for resources')
param location string = resourceGroup().location

param storageAccountName string

resource datastorage 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${datastorage.name};AccountKey=${datastorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'

resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: '${nameprefix}func'
  location: location
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: functionasp.id
    clientAffinityEnabled: true
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionstorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionstorage.id, functionstorage.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionstorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionstorage.id, functionstorage.apiVersion).keys[0].value}'
        }
        {
          name: 'StorageConnection'
          value: storageConnectionString
        }
      ]
    }
  }
}

resource functionasp 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${nameprefix}asp'
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

resource functionstorage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: '${nameprefix}funcstor'
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'Storage'
  properties: {
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
  }
}

output functionUrl string = '${functionApp.name}.azurewebsites.net'
output functionName string = functionApp.name
