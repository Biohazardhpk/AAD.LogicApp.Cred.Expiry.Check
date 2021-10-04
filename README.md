# Azure.ADApplication.SecretExpiryNotice
Logic app that checks secrets and certificates expiration dates for all azure AD apps

Are you constantly challenged with keeping up with all your Azure Active Directory Enterprise Application client secrets and certificates and their associated expiration dates? 
There are various solutions out there, however the most interesting I have found is: https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/use-power-automate-to-notify-of-upcoming-azure-ad-app-client/ba-p/2406145

This repo intends to build on the great solution already there and provide a scalable and rapid method of deployment based on Azure Bicep Templates.

_# Disclaimer: This repo does not intend to be a complete guide on how to use and setup Azure Bicep or AzureDevOps pipelines_
# Prerequsites
The following are considered  components are:
 1. Create (or use an existing) Azure AD app registration that has ONE of the following Microsoft Graph Permissions (Application.Read.All, Directory.Read.All)
 2. Grant permissions to the Azure AD app to an Azure KeyVault 
 3. Store: AADAppSecretsnCertsExpirationNotification-Client-id, AADAppSecretsnCertsExpirationNotification-Tenant-id, AADAppSecretsnCertsExpirationNotification-Client-secret (details for the APP created at point 1)
 4. Have Az CLI and Bicep installed

# Deployment
The complete perspective can be found at: https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/use-power-automate-to-notify-of-upcoming-azure-ad-app-client/ba-p/2406145
## Solution Diagram (CI/CD)

![image](./out/AzureAD-DeleteUsers/AzureAD-DeleteUsers.png)


 # HOW TO USE (local deployment)
 1. From a powershell console "az login" and set the desired
    1. az login
    2. az account set --subscription 'TARGET_SUBSCRIPTION'
1. Run the following AZ script:
 ```
az deployment group create -g 'LOGAPP-TARGET-RG' --template-file './BicepTemplates/CredentialSolution.bicep' --parameters `
workflows_AD_Check='LOGIC_APP_NAME' `
email='EMAIL_FOR_O365_CONNECTION' `
FutureTime=30 `
kvResourceGroup='EG_OF_AKV' `
kvName='AKV_NAME' `
TenantId='NAME_OF_SECRET_FROM_AKV' `
clientSecret='NAME_OF_SECRET_FROM_AKV' `
clientId='NAME_OF_SECRET_FROM_AKV' 
 ```
# Notes
1. Currently Azure does not support authentication with a managed identity for Outlook connection: https://docs.microsoft.com/en-us/azure/logic-apps/create-managed-service-identity
2. To preserve the scaleble deployment method and mitigate the above limitation after creating the Outlook connaction from the Bicep template we must Authorize it manually.
![image](./Images/outlook%20connection.png)