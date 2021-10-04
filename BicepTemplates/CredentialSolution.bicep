//THESE PARAMSARE REQUIRED AS INPUT
@description('Name of the Solution LogicApp')
param workflows_AD_Check string
@description('Resource group for the AKV resource, required for creating the connection ID')
param kvResourceGroup string
@description('AKV name')
param kvName string
@description('Email account for the Office365 APi Connection. Should be the email of the person creating the deployment')
param email string
@description('Future time in days before Secret/Certificate expiries')
param FutureTime int
@description('Tenant ID of the target Tenant, this should reference an AKV Secret')
param TenantId string
@description('Client Secret of the application used to check AD, this should reference an AKV Secret')
param clientSecret string
@description('Client ID of the application used to check AD, this should reference an AKV Secret')
param clientId string
@description('Name of the AKV connection')
param keyVaultConn string = 'keyvault'
@description('Name of the O365 connection')
param o365Conn string = 'office365'
//THESE PARAMS ARE AUTOMATIC
@description('Subscription of the AKV resource, required for creating the connection ID')
param subscriptionId string = subscription().subscriptionId
@description('Resource group of the LogicApp and API connectors')
param solRg string = resourceGroup().name

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
  scope: resourceGroup(subscriptionId, kvResourceGroup)
}

module AKVAPI './AKVAPIConnection.bicep' = {
  name: 'AKVAPI'
  dependsOn: [
    kv
  ] 
  scope: resourceGroup(subscriptionId, solRg)
  params: {
    connections_keyvault_name: 'keyvault'
    vaultName: kvName
    TenantId: kv.getSecret(TenantId)
    clientSecret: kv.getSecret(clientSecret)
    clientId: kv.getSecret(clientId)
  }
}

module O365C './EmailConnection.bicep' = {
  name: 'O365C'
  dependsOn: [
    kv
  ] 
  scope: resourceGroup(subscriptionId, solRg)
  params: {
    connections_office365_name: 'office365'
    email: email
  }
}

module LogicBicep './LogicBicep.bicep' = {
  name: 'LogicBicep'
  dependsOn: [
    AKVAPI
    O365C
  ]  
  scope: resourceGroup(subscriptionId, solRg)
  params: {
    email: email
    FutureTime: FutureTime
    workflows_AD_Check: workflows_AD_Check
    keyVaultConn: keyVaultConn
    keyVaultConn_id: AKVAPI.outputs.keyVaultConn_id
    o365Conn: o365Conn
    o365Conn_id: O365C.outputs.o365Conn_id

  }
}
