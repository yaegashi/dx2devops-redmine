param appName string
param appImage string
param appPlanId string
param appAuthClientId string = ''
@secure()
param appSecretKeyBase string
@secure()
param appDbPass string
param location string = resourceGroup().location

var appDbName = replace(appName, '-', '_')
var appDatabaseUrl = format(resourceGroup().tags.DB_URL_FORMAT, appDbName, appDbPass, appDbName)

resource app 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|${appImage}'
      alwaysOn: true
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'true'
        }
        {
          name: 'RAILS_IN_SERVICE'
          value: 'false'
        }
        {
          name: 'RAILS_ENV'
          value: 'production'
        }
        {
          name: 'SECRET_KEY_BASE'
          value: appSecretKeyBase
        }
        {
          name: 'DATABASE_URL'
          value: appDatabaseUrl
        }
        {
          name: 'DATABASE_FLEXIBLE'
          value: 'true'
        }
      ]
    }
    serverFarmId: appPlanId
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource appConfigLogs 'config' = {
    name: 'logs'
    properties: {
      detailedErrorMessages: { enabled: true }
      failedRequestsTracing: { enabled: true }
      httpLogs: {
        fileSystem: {
          enabled: true
          retentionInDays: 7
          retentionInMb: 50
        }
      }
    }
  }

  resource appConfigAuthSettingsV2 'config' = if (appAuthClientId != '') {
    name: 'authsettingsV2'
    properties: {
      globalValidation: {
        requireAuthentication: true
        unauthenticatedClientAction: 'RedirectToLoginPage'
        redirectToProvider: 'azureActiveDirectory'
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          registration: {
            openIdIssuer: 'https://sts.windows.net/${subscription().tenantId}'
            clientId: appAuthClientId
          }
          validation: {
            allowedAudiences: [
              'api://${appAuthClientId}'
            ]
          }
        }
      }
      login: {
        tokenStore: {
          enabled: true
        }
      }
    }
  }
}

resource logAnalytics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'logAnalytics'
  scope: app
  properties: {
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true

      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    #disable-next-line use-resource-id-functions
    workspaceId: resourceGroup().tags.LOG_ANALYTICS_WORKSPACE_ID
  }
}

output appId string = app.id
