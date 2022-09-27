@description('First part of the resource name')
param nameprefix string

@description('Azure region for resources')
param location string = resourceGroup().location
param storageAccountName string

param adminContainerImage string
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

resource datastorage 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
}

var tableName = 'redirectionurls'
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${datastorage.name};AccountKey=${datastorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'

resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: '${nameprefix}func'
  location: location
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: functionappasp.id
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

resource adminApp 'Microsoft.Web/sites@2020-06-01' = {
  name: '${nameprefix}adminapp'
  location: location
  kind: 'app,linux,container'
  properties: {
    httpsOnly: true
    serverFarmId: adminappasp.id
    clientAffinityEnabled: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${adminContainerImage}'
      alwaysOn: true
      appSettings: [
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
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: acrUser
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: acrPassword
        }
      ]
    }
  }
}

resource functionappasp 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${nameprefix}funcasp'
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

resource adminappasp 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${nameprefix}admasp'
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
output adminUrl string = '${adminApp.name}.azurewebsites.net'
