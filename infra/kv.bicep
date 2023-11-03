param kvName string
param principalId string = ''
param location string

@secure()
param dbAdminPass string
param appName string = ''
@secure()
param appSecretKeyBase string = ''
@secure()
param appDbPass string = ''

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: kvName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    accessPolicies: !empty(principalId) ? [
      {
        objectId: principalId
        permissions: { secrets: [ 'get', 'list' ] }
        tenantId: subscription().tenantId
      }
    ] : []
  }

  resource s1 'secrets' = {
    name: 'dbAdminPass'
    properties: {
      contentType: 'text/plain'
      value: dbAdminPass
    }
  }

  resource s2 'secrets' = if (!empty(appName)) {
    name: '${appName}-appSecretKeyBase'
    properties: {
      contentType: 'text/plain'
      value: appSecretKeyBase
    }
  }

  resource s3 'secrets' = if (!empty(appName)) {
    name: '${appName}-appDbPass'
    properties: {
      contentType: 'text/plain'
      value: appDbPass
    }
  }
}

output uri string = kv.properties.vaultUri
output name string = kv.name
