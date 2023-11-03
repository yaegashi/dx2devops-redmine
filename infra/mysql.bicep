param dbName string
param dbAdminUser string = 'adminuser'
@secure()
param dbAdminPass string
param dbSkuName string = 'Standard_B1s'
param dbSkuTier string = 'Burstable'
param dbSizeGB int = 20
param dbVersion string = '8.0.21'
param location string = resourceGroup().location

resource db 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
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

output tags object = {
  DB_TYPE: 'mysql'
  DB_SERVER_NAME: db.name
  DB_SERVER_FQDN: db.properties.fullyQualifiedDomainName
  DB_ADMIN_USER: db.properties.administratorLogin
  DB_URL_FORMAT: 'mysql2://{0}:{1}@${db.properties.fullyQualifiedDomainName}/{2}?encoding=utf8mb4&sslverify=true'
}
