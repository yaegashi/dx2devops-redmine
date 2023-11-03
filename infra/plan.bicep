param planName string
param planSku string = 'B1'
param location string = resourceGroup().location

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
}

output planId string = plan.id
