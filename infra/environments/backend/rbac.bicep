// RBAC Assignment Module for Backend Environment
// This module creates role assignments for the Function App managed identity
// 
// ADE Requirement: All modules must be in the same folder as the main template
// Azure Deployment Environments operates at the folder level, meaning all dependencies
// (modules, templates, etc.) must be co-located with the main template for proper
// packaging and deployment. This ensures ADE can discover and deploy all required
// components together without external dependencies.

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Principal ID of the managed identity')
param principalId string

@description('Role definition ID for the assignment')
param roleDefinitionId string

@description('Resource ID of the target resource')
param targetResourceId string

@description('Principal type (ServicePrincipal, User, Group)')
param principalType string = 'ServicePrincipal'

// =========== ROLE ASSIGNMENT ===========

// Create role assignment for the specified principal
// Using guid() with additional uniqueness factor to ensure unique, deterministic names and avoid conflicts
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, roleDefinitionId, targetResourceId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

// =========== OUTPUTS ===========

@description('Role assignment ID')
output roleAssignmentId string = roleAssignment.id

@description('Role assignment name')
output roleAssignmentName string = roleAssignment.name
