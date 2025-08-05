// Azure Cognitive Search Module
// This module creates an Azure Cognitive Search service using Azure Verified Modules (AVM)
// Provides a search service for the application
// Uses AVM-compatible parameter names and outputs

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Name of the Azure Cognitive Search service')
param searchServiceName string

@description('Azure region for the search service')
param location string = resourceGroup().location

@description('SKU of the Azure Cognitive Search service')
@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param skuName string = 'basic'

@description('Number of replicas for the search service')
@minValue(1)
@maxValue(12)
param replicaCount int = 1

@description('Number of partitions for the search service')
@minValue(1)
@maxValue(12)
param partitionCount int = 1

@description('Tags to apply to the search service')
param tags object = {}

// =========== AZURE COGNITIVE SEARCH SERVICE (AVM) ===========

// Azure Cognitive Search Service using Azure Verified Module
module searchService 'br/public:avm/res/search/search-service:0.11.0' = {
  name: 'search-service'
  params: {
    name: searchServiceName
    location: location
    sku: skuName
    replicaCount: replicaCount
    partitionCount: partitionCount
    tags: tags
  }
}

// =========== OUTPUTS ===========

@description('Resource ID of the Azure Cognitive Search service')
output searchServiceId string = searchService.outputs.resourceId

@description('Name of the Azure Cognitive Search service')
output searchServiceName string = searchService.outputs.name

@description('Resource group name containing the search service')
output resourceGroupName string = resourceGroup().name

@description('Location of the Azure Cognitive Search service')
output location string = location

@description('SKU of the Azure Cognitive Search service')
output skuName string = skuName

@description('Replica count of the Azure Cognitive Search service')
output replicaCount int = replicaCount

@description('Partition count of the Azure Cognitive Search service')
output partitionCount int = partitionCount
