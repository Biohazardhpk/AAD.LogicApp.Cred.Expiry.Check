param connections_keyvault_name string
param location string = resourceGroup().location
param vaultName string
param subscriptionId string = subscription().subscriptionId

@secure()
param TenantId string
@secure()
param clientId string
@secure()
param clientSecret string


resource connections_keyvault_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_keyvault_name
  location: location
  tags: {}
  properties: {
    displayName: connections_keyvault_name
    customParameterValues: {}
    parameterValues:{
      'token:clientSecret': clientSecret
      'token:TenantId': TenantId
      'token:clientId': clientId
      'token:grantType': 'client_credentials'
      vaultName: vaultName
    }
    api: {
      name: connections_keyvault_name
      displayName: 'Azure Key Vault'
      description: 'Azure Key Vault is a service to securely store and access secrets.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1503/1.0.1503.2513/${connections_keyvault_name}/icon.png'
      brandColor: '#0079d6'
      id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${connections_keyvault_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

output keyVaultConn_id string = connections_keyvault_name_resource.properties.api.id
