@description('Environment name (dev, prod)')
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('VNet address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Trusted subnet prefix')
param trustedSubnetPrefix string = '10.0.1.0/24'

@description('Rogue subnet prefix')
param rogueSubnetPrefix string = '10.0.2.0/24'

@description('Resource tags')
param tags object = {}

// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-exfil-${environment}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-trusted'
        properties: {
          addressPrefix: trustedSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'snet-rogue'
        properties: {
          addressPrefix: rogueSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Private DNS Zone for Blob Storage
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${az.environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// VNet Link to Private DNS Zone
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'vnet-link-${environment}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Outputs
output vnetId string = vnet.id
output vnetName string = vnet.name
output trustedSubnetId string = vnet.properties.subnets[0].id
output rogueSubnetId string = vnet.properties.subnets[1].id
output privateDnsZoneId string = privateDnsZone.id
output privateDnsZoneName string = privateDnsZone.name
