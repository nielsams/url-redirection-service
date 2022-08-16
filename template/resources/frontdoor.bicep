@description('First part of the resource name')
param nameprefix string

@description('The base URL of the container, without https://')
param containerUrl string

param customDomainName string

resource frontdoor 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: '${nameprefix}afd'
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}



resource afdendpoint 'Microsoft.Cdn/profiles/afdendpoints@2021-06-01' = {
  parent: frontdoor
  name: '${nameprefix}fd'
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
    
  }
}

resource customDomain 'Microsoft.Cdn/profiles/customDomains@2021-06-01' = {
  parent: frontdoor
  name: 'customdomain'
  properties: {
    hostName: customDomainName
  }
}

resource afdorigingroup_redir 'Microsoft.Cdn/profiles/origingroups@2021-06-01' = {
  parent: frontdoor
  name: 'origingroup-redir'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    sessionAffinityState: 'Disabled'
  }
}

resource afdorigin_redir 'Microsoft.Cdn/profiles/origingroups/origins@2021-06-01' = {
  parent: afdorigingroup_redir
  name: 'origin-redir'
  properties: {
    hostName: containerUrl
    httpPort: 8080
    httpsPort: 443
    originHostHeader: containerUrl
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: false
  }
}

resource afdroute_api 'Microsoft.Cdn/profiles/afdendpoints/routes@2021-06-01' = {
  parent: afdendpoint
  name: 'route-redir'
  properties: {
    originGroup: {
      id: afdorigingroup_redir.id
    }
    customDomains: [
      {
        id: customDomain.id
      }
    ]
    ruleSets: []
    supportedProtocols: [
      'Https'
      'Http'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}

resource afdorigingroup_admin 'Microsoft.Cdn/profiles/origingroups@2021-06-01' = {
  parent: frontdoor
  name: 'origingroup-admin'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    sessionAffinityState: 'Disabled'
  }
}

resource afdorigin_admin 'Microsoft.Cdn/profiles/origingroups/origins@2021-06-01' = {
  parent: afdorigingroup_admin
  name: 'origin-admin'
  properties: {
    hostName: containerUrl
    httpPort: 80
    httpsPort: 443
    originHostHeader: customDomainName
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: false
  }
}

resource afdroute_admin 'Microsoft.Cdn/profiles/afdendpoints/routes@2021-06-01' = {
  parent: afdendpoint
  name: 'route-admin'
  properties: {
    originGroup: {
      id: afdorigingroup_admin.id
    }
    customDomains: [
      {
        id: customDomain.id
      }
    ]
    ruleSets: []
    supportedProtocols: [
      'Https'
      'Http'
    ]
    patternsToMatch: [
      '/admin'
      '/admin/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}

output frontDoorEndpointHostName string = afdendpoint.properties.hostName
