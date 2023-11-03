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
var xAppImage = !empty(appImage) ? appImage : 'ghcr.io/yaegashi/dx2devops-redmine/redmica:v2.3.2-master'

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
    tags: union(rg.tags, dbType == 'mysql' ? mysql.outputs.tags : psql.outputs.tags)
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

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_KEY_VAULT_NAME string = kv.outputs.name
output AZURE_KEY_VAULT_URI string = kv.outputs.uri
