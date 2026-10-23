using '../main.bicep'

// Department "aidelivery", development. Deployed into rg-aidelivery-platform-dev.
param team = 'aidelivery'
param env = 'dev'
param location = 'swedencentral'
// Test account: Basic is enough and keeps cost low.
param registrySku = 'Basic'
param tags = {
  dept: 'aidelivery'
  project: 'platform'
  env: 'dev'
  owner: 'tiagomccoutinho@hotmail.com'
  'cost-centre': 'lab'
}
