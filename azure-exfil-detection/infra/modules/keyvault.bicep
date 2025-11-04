@description('Environment name')
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Tenant ID')
param tenantId string = subscription().tenantId

@description('Object ID for Key Vault access (your user/SP)')
param adminObjectId string

@description('Storage Account name for CMK')
param storageAccountName string

@description('Resource tags')
param tags object = {}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-exfil-${environment}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    enableRbacAuthorization: false
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: adminObjectId
        permissions: {
          keys: [
            'get'
            'list'
            'create'
            'delete'
            'update'
            'encrypt'
            'decrypt'
            'wrapKey'
            'unwrapKey'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
          ]
        }
      }
    ]
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// CMK Key
resource cmkKey 'Microsoft.KeyVault/vaults/keys@2023-02-01' = {
  parent: keyVault
  name: 'storage-encryption-key'
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'sign'
      'verify'
      'wrapKey'
      'unwrapKey'
      'encrypt'
      'decrypt'
    ]
  }
}

// Storage Account reference
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Grant Storage Account access to Key Vault
resource storageAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: storageAccount.identity.principalId
        permissions: {
          keys: [
            'get'
            'wrapKey'
            'unwrapKey'
          ]
        }
      }
    ]
  }
}

// Outputs
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output cmkKeyId string = cmkKey.properties.keyUriWithVersion
output cmkKeyName string = cmkKey.name
