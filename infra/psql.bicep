param dbName string
param dbAdminUser string = 'adminuser'
@secure()
param dbAdminPass string
param dbSkuName string = 'Standard_B1ms'
param dbSkuTier string = 'Burstable'
param dbSizeGB int = 32
param dbVersion string = '15'
param location string = resourceGroup().location

resource db 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: dbName
  location: location
  sku: {
    name: dbSkuName
    tier: dbSkuTier
  }
  properties: {
    createMode: 'Default'
    version: dbVersion
    administratorLogin: dbAdminUser
    administratorLoginPassword: dbAdminPass
    highAvailability: {
      mode: 'Disabled'
    }
    storage: {
      storageSizeGB: dbSizeGB
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

output dbId string = db.id
output tags object = {
  DB_TYPE: 'psql'
  DB_SERVER_NAME: db.name
  DB_SERVER_FQDN: db.properties.fullyQualifiedDomainName
  DB_ADMIN_USER: db.properties.administratorLogin
  DB_URL_FORMAT: 'postgresql://{0}:{1}@${db.properties.fullyQualifiedDomainName}/{2}?sslmode=require'
}
