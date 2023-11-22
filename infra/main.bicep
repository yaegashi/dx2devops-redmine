targetScope = 'subscription'

@minLength(1)
@maxLength(64)
param envName string
param location string
param resourceGroupName string = ''
param principalId string = ''

param planSku string = 'B1'

@allowed([ 'mysql', 'psql' ])
param dbType string
param dbAdminUser string = ''
@secure()
param dbAdminPass string

param appName string = ''
param appImage string = ''
param appAuthClientId string = ''
@secure()
param appSecretKeyBase string = ''
@secure()
param appDbPass string = ''

var resourceToken = take(toLower(uniqueString(subscription().id, envName, location)), 7)
var tags = { 'azd-env-name': envName }

var xEnvName = '${envName}-${resourceToken}'
var xResourceGroupName = !empty(resourceGroupName) ? resourceGroupName : 'rg-${envName}'
var xDbAdminUser = !empty(dbAdminUser) ? dbAdminUser : 'adminuser'
var xAppName = '${xEnvName}-${appName}'
var xAppImage = !empty(appImage) ? appImage : 'ghcr.io/yaegashi/dx2devops-redmine/redmica'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: xResourceGroupName
  location: location
  tags: tags
}

module kv 'kv.bicep' = {
  scope: rg
  name: 'kv'
  params: {
    kvName: xEnvName
    principalId: principalId
    dbAdminPass: dbAdminPass
    appName: appName
    appSecretKeyBase: appSecretKeyBase
    appDbPass: appDbPass
    location: location
  }
}

module log 'log.bicep' = {
  scope: rg
  name: 'log'
  params: {
    logName: xEnvName
    location: location
  }
}

module plan 'plan.bicep' = {
  scope: rg
  name: 'plan'
  params: {
    planName: xEnvName
    planSku: planSku
    location: location
  }
}

module mysql 'mysql.bicep' = if (dbType == 'mysql') {
  scope: rg
  name: 'mysql'
  params: {
    dbName: xEnvName
    dbAdminUser: xDbAdminUser
    dbAdminPass: dbAdminPass
    location: location
  }
}

module psql 'psql.bicep' = if (dbType == 'psql') {
  scope: rg
  name: 'psql'
  params: {
    dbName: xEnvName
    dbAdminUser: xDbAdminUser
    dbAdminPass: dbAdminPass
    location: location
  }
}

module rgtags 'rgtags.bicep' = {
  name: 'rgtags'
  params: {
    name: rg.name
    location: rg.location
    tags: union(rg.tags, log.outputs.tags, dbType == 'mysql' ? mysql.outputs.tags : psql.outputs.tags)
  }
}

module app 'app.bicep' = if (!empty(appName)) {
  scope: rg
  name: 'app'
  dependsOn: [ rgtags ]
  params: {
    appName: xAppName
    appPlanId: plan.outputs.planId
    appImage: xAppImage
    appAuthClientId: appAuthClientId
    appSecretKeyBase: appSecretKeyBase
    appDbPass: appDbPass
    location: location
  }
}

var portalLink = 'https://portal.azure.com/${tenant().tenantId}'
var appId = app.outputs.appId
var dbId = dbType == 'mysql' ? mysql.outputs.dbId : psql.outputs.dbId

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_KEY_VAULT_NAME string = kv.outputs.name
output AZURE_KEY_VAULT_URI string = kv.outputs.uri
output AZURE_APP_NAME string = xAppName
output AZURE_APP_LINK string = 'https://${xAppName}.azurewebsites.net'
output AZURE_APP_RESOURCE_ID string = appId
output AZURE_APP_RESOURCE_LINK string = '${portalLink}#resource${appId}'
output AZURE_APP_CONSOLE_LINK string = 'https://${xAppName}.scm.azurewebsites.net/webssh/host'
output AZURE_DB_RESOURCE_ID string = dbId
output AZURE_DB_RESOURCE_LINK string = '${portalLink}#resource${dbId}'
output AZURE_DB_ADMIN_USER string = xDbAdminUser
output AZURE_DB_ADMIN_PASS_LINK string = '${portalLink}#asset/Microsoft_Azure_KeyVault/Secret/${kv.outputs.uri}secrets/dbAdminPass'
