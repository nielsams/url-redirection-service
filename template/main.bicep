targetScope = 'subscription'

@minLength(1)
@maxLength(16)
@description('Prefix for all resources, i.e. {name}storage')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

param customDomain string

param containerImage string
param acrServer string
param acrUser string
@secure()
param acrPassword string

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'nielsb-redirector'
  location: location
}

module storage './resources/storage.bicep' = {
  name: '${rg.name}-storage'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
  }
}

module container './resources/container.bicep' = {
  name: '${rg.name}-container'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
    image: containerImage
    acrServer: acrServer
    acrUser: acrUser
    acrPassword: acrPassword
    storageAccountName: storage.outputs.storageAccountName
  }
}

module frontdoor './resources/frontdoor.bicep' = {
  name: '${rg.name}-frontdoor'
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
