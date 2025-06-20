// RBAC Assignment Module
// This module creates a role assignment at resource group scope

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
