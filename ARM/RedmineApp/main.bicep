param appName string
param appImage string = 'ghcr.io/yaegashi/dx2devops-redmine/redmica:v2.1.0-master'
param appPlanId string
param appAuthClientId string = ''
param identity object
param location string = resourceGroup().location

resource app 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|${appImage}'
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
          value: ''
        }
        {
          name: 'DATABASE_URL'
          value: ''
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
      detailedErrorMessages: {
        enabled: true }
      failedRequestsTracing: {
        enabled: true }
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

resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: appName
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.39.0'
    arguments: '${app.name} ${app.id}'
    scriptContent: loadTextContent('deploymentScript.sh')
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}
