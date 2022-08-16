targetScope = 'subscription'

param name string
param resourceGroupName string
param location string = deployment().location
param customDomain string
param redirectorContainerImage string
param adminContainerImage string
param acrServer string
param acrUser string
@secure()
param acrPassword string
@secure()
param adminDomain string
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
    redirectorimage: redirectorContainerImage
    adminimage: adminContainerImage
    adminClientId: adminClientId
    adminDomain: adminDomain
    adminTenantId: adminTenantId
    acrServer: acrServer
    acrUser: acrUser
    acrPassword: acrPassword
    storageAccountName: storage.outputs.storageAccountName
    customDomain: customDomain
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
    customDomainName: customDomain
    containerUrl: container.outputs.containerIPAddress
  }
  dependsOn: [
    container
  ]
}

output resource_group_name string = rg.name
output frontdoor_hostname string = frontdoor.outputs.frontDoorEndpointHostName
