@description('First part of the resource name')
param nameprefix string

@description('Azure region for resources')
param location string = resourceGroup().location

resource storageappdata 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: '${nameprefix}stor'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource symbolicname 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-09-01' = {
  name: '${nameprefix}stor/default/redirectionurls'
}

output storageAccountName string = storageappdata.name
