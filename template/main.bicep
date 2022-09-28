targetScope = 'subscription'

param name string
param resourceGroupName string
param location string = deployment().location
param customDomain string
param adminDomain string
param adminContainerImage string
param acrServer string
param acrUser string
@secure()
param acrPassword string
@secure()
param adminAuthDomain string
@secure()
param adminTenantId string
@secure()
param adminClientId string


resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupName
  location: location
}

module storage './resources/storage.bicep' = {
  name: '${name}-storage'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
  }
}

module container './resources/container.bicep' = {
  name: '${name}-container'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
    adminimage: adminContainerImage
    adminClientId: adminClientId
    adminAuthDomain: adminAuthDomain
    adminTenantId: adminTenantId
    acrServer: acrServer
    acrUser: acrUser
    acrPassword: acrPassword
    storageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [
    storage
  ]
}

module webapps './resources/webapps.bicep' = {
  name: '${name}-webapps'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
    storageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [
    storage
  ]
}

module frontdoor './resources/frontdoor.bicep' = {
  name: '${name}-frontdoor'
  scope: rg
  params: {
    nameprefix: toLower(name)
    redirCustomDomainName: customDomain
    adminCustomDomainName: adminDomain
    redirUrl: webapps.outputs.functionUrl
    adminUrl: container.outputs.containerUrl
  }
  dependsOn: [
    container
    webapps
  ]
}

output resource_group_name string = rg.name
output function_name string = webapps.outputs.functionName
output frontdoor_hostname string = frontdoor.outputs.frontDoorEndpointHostName
