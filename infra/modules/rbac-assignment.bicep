// Generic RBAC Assignment Module
// This module creates role assignments with proper scoping and can be reused across different resources

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Principal ID of the identity to assign the role to')
param principalId string

@description('Role definition ID (GUID) to assign')
param roleDefinitionId string

@description('Type of principal being assigned the role')
@allowed(['User', 'Group', 'ServicePrincipal'])
param principalType string = 'ServicePrincipal'

@description('Resource ID of the target resource to scope the role assignment')
param targetResourceId string

@description('Description of the role assignment purpose')
param roleDescription string = ''

// =========== VARIABLES ===========

// Generate a deterministic GUID for the role assignment name to avoid conflicts
var roleAssignmentName = guid(targetResourceId, principalId, roleDefinitionId)

// =========== RESOURCES ===========

// Role Assignment scoped to the resource group (caller must scope appropriately)
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
    description: roleDescription
  }
}

// =========== OUTPUTS ===========

@description('Role assignment resource ID')
output roleAssignmentId string = roleAssignment.id

@description('Role assignment name (GUID)')
output roleAssignmentName string = roleAssignment.name

@description('Principal ID that was assigned the role')
output principalId string = principalId

@description('Role definition ID that was assigned')
output roleDefinitionId string = roleDefinitionId
