using './main.bicep'

param environment = 'prod'
param location = 'westeurope'
param storageNameSuffix = '7491'  // Nowy suffix dla prod
param adminObjectId = '0f847f91-cabe-4dd1-9aba-c1fd3058813e'
param vnetAddressPrefix = '10.1.0.0/16'  // Inna przestrzeń
param trustedSubnetPrefix = '10.1.1.0/24'
param rogueSubnetPrefix = '10.1.2.0/24'
param logRetentionDays = 90  // Dłużej w prod
param logDailyQuotaGb = 5
