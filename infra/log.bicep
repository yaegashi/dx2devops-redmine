param logName string
param location string = resourceGroup().location

resource log 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

output tags object = {
  LOG_ANALYTICS_WORKSPACE_ID: log.id
}
