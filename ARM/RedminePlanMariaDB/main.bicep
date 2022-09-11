param planName string
param planSku string = 'B1'
param dbAdminUser string = 'adminuser'
@secure()
param dbAdminPass string
param dbSkuCapacity int = 1
param dbSkuName string = 'B_Gen5_1'
param dbSkuSizeMB int = 5120
param dbSkuTier string = 'Basic'
param dbSkuFamily string = 'Gen5'
param dbVersion string = '10.3'
param location string = resourceGroup().location

var templateName = 'RedminePlanPariaDB'
var dbName = '${planName}${uniqueString(templateName, planName, resourceGroup().id)}'

resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: planName
  location: location
  sku: {
    name: planSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    Template: templateName
    DB_TYPE: 'mariadb'
    DB_SERVER_FQDN: '${db.name}.mariadb.database.azure.com'
    DB_SERVER_NAME: db.name
    DB_ADMIN_USER: '${dbAdminUser}@${db.name}'
    DB_URL_FORMAT: 'mysql2://{0}%40${db.name}:{1}@${db.name}.mariadb.database.azure.com/{2}?encoding=utf8mb4&sslverify=true'
  }
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: planName
  location: location
}

var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, identity.id, contributorRoleDefinitionId)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: identity.properties.principalId
    roleDefinitionId: contributorRoleDefinitionId
  }
}

resource db 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: dbName
  location: location
  sku: {
    name: dbSkuName
    tier: dbSkuTier
    capacity: dbSkuCapacity
    size: '${dbSkuSizeMB}'
    family: dbSkuFamily
  }
  properties: {
    createMode: 'Default'
    version: dbVersion
    administratorLogin: dbAdminUser
    administratorLoginPassword: dbAdminPass
    storageProfile: {
      storageMB: dbSkuSizeMB
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
      storageAutogrow: 'Enabled'
    }
  }
  resource allowAzureRule 'firewallRules' = {
    name: 'allowAzureRule'
    properties: {
      endIpAddress: '0.0.0.0'
      startIpAddress: '0.0.0.0'
    }
  }
}
