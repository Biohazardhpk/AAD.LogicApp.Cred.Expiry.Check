param connections_office365_name string
param location string = resourceGroup().location
param subscriptionId string = subscription().subscriptionId
param o365resourceGroup string = resourceGroup().name
param email string 

resource connections_office365_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_office365_name
  location: location

  properties: {
    displayName: email
    customParameterValues: {}
    nonSecretParameterValues: {}
    api: {
      name: connections_office365_name
      displayName: 'Office 365 Outlook'
      description: 'Microsoft Office 365 is a cloud-based service that is designed to help meet your organization\'s needs for robust security, reliability, and user productivity.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1507/1.0.1507.2528/${connections_office365_name}/icon.png'
      brandColor: '#0078D4'
      id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${connections_office365_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: [
      {
        requestUri: 'https://management.azure.com:443/subscriptions/${subscriptionId}/resourceGroups/${o365resourceGroup}/providers/Microsoft.Web/connections/${connections_office365_name}/extensions/proxy/testconnection?api-version=2016-06-01'
        method: 'get'
      }
    ]
  }
}

output o365Conn_id string = connections_office365_name_resource.properties.api.id

