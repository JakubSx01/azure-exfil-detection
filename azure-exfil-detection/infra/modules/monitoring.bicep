@description('Environment name')
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Storage Account ID for diagnostics')
param storageAccountId string

@description('Log retention days')
param retentionDays int = 30

@description('Daily cap in GB')
param dailyQuotaGb int = 1

@description('Resource tags')
param tags object = {}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-exfil-${environment}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Reference to existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: split(storageAccountId, '/')[8]
  
  resource blobService 'blobServices@2023-01-01' existing = {
    name: 'default'
  }
}

// Diagnostic Settings for Blob Service
resource blobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: storageAccount::blobService
  name: 'diag-blob-to-law'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

// Saved Query: Basic Storage Logs
resource savedQuery1 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalytics
  name: 'BasicStorageLogs'
  properties: {
    category: 'Exfiltration Detection'
    displayName: 'Basic Storage Logs'
    query: '''
StorageBlobLogs
| where TimeGenerated > ago(1h)
| project TimeGenerated, OperationName, CallerIpAddress, Uri, ResponseBodySize
| order by TimeGenerated desc
'''
    version: 1
  }
}

// Saved Query: Excessive Egress
resource savedQuery2 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalytics
  name: 'ExcessiveEgress'
  properties: {
    category: 'Exfiltration Detection'
    displayName: 'Excessive Data Egress'
    query: '''
let threshold = 100 * 1024 * 1024;
StorageBlobLogs
| where TimeGenerated > ago(15m)
| where OperationName == "GetBlob"
| summarize TotalBytes = sum(ResponseBodySize), RequestCount = count() 
  by CallerIpAddress, AccountName
| where TotalBytes > threshold
| extend ThreatLevel = "High", BytesMB = round(TotalBytes / 1024.0 / 1024.0, 2)
| project TimeDetected = now(), CallerIpAddress, AccountName, ThreatLevel, BytesMB, RequestCount
'''
    version: 1
  }
}

// Saved Query: Unknown IP Access
resource savedQuery3 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalytics
  name: 'UnknownIPAccess'
  properties: {
    category: 'Exfiltration Detection'
    displayName: 'Unknown IP Access Detection'
    query: '''
let lookbackPeriod = 7d;
let detectionWindow = 15m;
let knownIPs = StorageBlobLogs
    | where TimeGenerated between (ago(lookbackPeriod) .. ago(detectionWindow))
    | distinct CallerIpAddress;
StorageBlobLogs
| where TimeGenerated > ago(detectionWindow)
| where CallerIpAddress !in (knownIPs)
| summarize FirstSeen = min(TimeGenerated), RequestCount = count(), 
    Operations = make_set(OperationName)
  by CallerIpAddress, AccountName
| extend ThreatLevel = "Medium"
| project TimeDetected = now(), CallerIpAddress, AccountName, ThreatLevel, 
    FirstSeen, RequestCount, Operations
'''
    version: 1
  }
}

// Outputs
output logAnalyticsId string = logAnalytics.id
output logAnalyticsName string = logAnalytics.name
output workspaceId string = logAnalytics.properties.customerId
