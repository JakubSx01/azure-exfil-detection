targetScope = 'resourceGroup'

@description('Environment name')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Storage account name suffix')
param storageNameSuffix string

@description('Admin Object ID for Key Vault')
param adminObjectId string

@description('VNet address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Trusted subnet prefix')
param trustedSubnetPrefix string = '10.0.1.0/24'

@description('Rogue subnet prefix')
param rogueSubnetPrefix string = '10.0.2.0/24'

@description('Log Analytics retention days')
param logRetentionDays int = 30

@description('Log Analytics daily cap GB')
param logDailyQuotaGb int = 1

@description('Common resource tags')
param tags object = {
  Environment: environment
  Project: 'ExfiltrationDetection'
  ManagedBy: 'Bicep'
}

// Module 1: Network
module network 'modules/network.bicep' = {
  name: 'deploy-network-${environment}'
  params: {
    environment: environment
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    trustedSubnetPrefix: trustedSubnetPrefix
    rogueSubnetPrefix: rogueSubnetPrefix
    tags: tags
  }
}

// Module 2: Storage (without CMK initially)
module storage 'modules/storage.bicep' = {
  name: 'deploy-storage-${environment}'
  params: {
    environment: environment
    location: location
    storageNameSuffix: storageNameSuffix
    subnetId: network.outputs.trustedSubnetId
    privateDnsZoneId: network.outputs.privateDnsZoneId
    enableCMK: false  // CMK added manually after KeyVault setup
    tags: tags
  }
}

// Module 3: Monitoring
module monitoring 'modules/monitoring.bicep' = {
  name: 'deploy-monitoring-${environment}'
  params: {
    environment: environment
    location: location
    storageAccountId: storage.outputs.storageAccountId
    retentionDays: logRetentionDays
    dailyQuotaGb: logDailyQuotaGb
    tags: tags
  }
}

// Module 4: Key Vault
module keyvault 'modules/keyvault.bicep' = {
  name: 'deploy-keyvault-${environment}'
  params: {
    environment: environment
    location: location
    adminObjectId: adminObjectId
    storageAccountName: storage.outputs.storageAccountName
    tags: tags
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output vnetId string = network.outputs.vnetId
output storageAccountName string = storage.outputs.storageAccountName
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId
output keyVaultName string = keyvault.outputs.keyVaultName
output cmkKeyId string = keyvault.outputs.cmkKeyId

