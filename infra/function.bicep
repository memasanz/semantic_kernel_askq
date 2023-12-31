param functionAppName string
param storageAccountName string
param cognitiveServicesAccountName string
param openAiEndpoint string
param openAiKey string
param rawBlobContainerName string
param extractedBlobContainerName string
param openAIChatModel string = 'gpt-4-32k'
param openAIEmbeddingModel string = 'text-embedding-ada-002'
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource cognitiveServicesAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: cognitiveServicesAccountName
}
var storageAccountConnection = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'


resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: '${functionAppName}-asp'
  location: location
  kind: 'app'
  sku:{
    name: 'Y1'
    tier: 'Dynamic'
  }
}


resource functionAppConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  name : 'web'
  kind: 'string'
  parent: functionApp
  properties: {
    cors: {
      allowedOrigins: [
        'https://portal.azure.com'
      ]
      supportCredentials: true
    }
  }
  
}
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccountConnection
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccountConnection
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: functionAppName
        }
        {
          name: 'DocumentIntelligenceSubscriptionKey'
          value: cognitiveServicesAccount.listKeys().key1
        }
        {
          name: 'DocumentIntelligenceEndpoint'
          value: cognitiveServicesAccount.properties.endpoint
        }
        {
          name: 'ContainerName'
          value: rawBlobContainerName
        }
        {
          name: 'ExtractedContainerName'
          value: extractedBlobContainerName
        }
        {
          name: 'OpenAIChatModel'
          value: openAIChatModel
        }
        {
          name: 'OpenAIEmbeddingModel'
          value: openAIEmbeddingModel
        }
        {
          name: 'OpenAIKey'
          value: openAiKey
        }
        {
          name: 'OpenAIEndpoint'
          value: openAiEndpoint
        }
        {
          name : 'RawStorageConnectionString'
          value: storageAccountConnection
        } 
        {
          name : 'StorageConnectionString'
          value: storageAccountConnection
        }
        {
          name: 'StorageAccount'
          value: storageAccountName
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
      ]
    }
  }
}
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: '${functionAppName}-insights'
  location: location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    // circular dependency means we can't reference functionApp directly  /subscriptions/<subscriptionId>/resourceGroups/<rg-name>/providers/Microsoft.Web/sites/<appName>"
     'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${functionAppName}': 'Resource'
  }
}





output functionAppId string = functionApp.identity.principalId
