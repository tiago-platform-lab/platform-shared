// Shared platform layer for one department and one environment.
//
// Owns the resources every app of the department reuses: Log Analytics, the
// Container Apps environment and the container registry. Apps never create these;
// they reference them as `existing` (see tmpl-webapp-bicep/infra/main.bicep).
//
// One file, many departments: each department is a pair of parameter files in
// teams/ (<team>.dev.bicepparam, <team>.prod.bicepparam), deployed into
// rg-<team>-platform-<env>.
//
// The registry exists once per department, in dev, and prod pulls the same tested
// image from it, so an image is built once and promoted rather than rebuilt.
//
// Creating the custom role below needs Owner or User Access Administrator on the
// resource group, so this layer is deployed by a more privileged identity than
// the apps are.

targetScope = 'resourceGroup'

@description('Department short name used in every resource name. Lowercase letters and digits only: it is part of the registry name.')
@minLength(2)
@maxLength(10)
param team string

@allowed(['dev', 'prod'])
param env string

param location string = resourceGroup().location

@description('Required tags. TODO(phase 0): agree one tag set (see the root README).')
param tags object

@description('Create the registry in this environment. Only dev owns it.')
param createRegistry bool = env == 'dev'

@description('Registry name, globally unique, alphanumeric only.')
param registryName string = 'cr${team}shared'

@description('Registry tier. Basic is enough for a test or a small department.')
@allowed(['Basic', 'Standard', 'Premium'])
param registrySku string = 'Standard'

@description('Log retention in days.')
param logRetentionDays int = 30

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${team}-${env}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: logRetentionDays
    features: { enableLogAccessUsingOnlyResourcePermissions: true }
  }
}

resource cae 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-${team}-${env}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
    // TODO(phase 0): VNet integration. Not needed while apps sit behind Easy Auth,
    // required if prod must reach private endpoints (see J2X for that shape).
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = if (createRegistry) {
  name: registryName
  location: location
  tags: tags
  sku: { name: registrySku }
  properties: {
    adminUserEnabled: false // pull and push by identity only
    publicNetworkAccess: 'Enabled'
  }
}

// Lets an app's deploy identity place a Container App in this environment without
// Contributor on the shared environment itself.
// platform-vending recomputes this GUID (modules/platform-access.bicep): keep the
// name expression as is.
resource caeJoinerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(resourceGroup().id, 'cae-joiner')
  properties: {
    roleName: 'Container Apps Environment Joiner (${team}-${env})'
    description: 'Deploy Container Apps and Jobs into the shared environment.'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          'Microsoft.App/managedEnvironments/read'
          'Microsoft.App/managedEnvironments/join/action'
        ]
        notActions: []
      }
    ]
    assignableScopes: [resourceGroup().id]
  }
}

output containerAppsEnvironmentName string = cae.name
output containerAppsEnvironmentId string = cae.id
output registryLoginServer string = createRegistry ? acr!.properties.loginServer : ''
output caeJoinerRoleName string = caeJoinerRole.name // a GUID; referenced with subscriptionResourceId()
