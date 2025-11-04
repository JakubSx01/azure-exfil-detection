using './main.bicep'

param environment = 'dev'
param location = 'westeurope'
param storageNameSuffix = '2847'
param adminObjectId = '2e5e6c30-cd8d-4835-84e6-188b5d157c77'  // Your Object ID
param vnetAddressPrefix = '10.0.0.0/16'
param trustedSubnetPrefix = '10.0.1.0/24'
param rogueSubnetPrefix = '10.0.2.0/24'
param logRetentionDays = 30
param logDailyQuotaGb = 1
