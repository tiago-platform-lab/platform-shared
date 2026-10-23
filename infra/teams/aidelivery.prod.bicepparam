using '../main.bicep'

// Department "aidelivery", production. Deployed into rg-aidelivery-platform-prod.
// No registry here: prod pulls the image built and tested in dev.
param team = 'aidelivery'
param env = 'prod'
param location = 'swedencentral'
param tags = {
  dept: 'aidelivery'
  project: 'platform'
  env: 'prod'
  owner: 'tiagomccoutinho@hotmail.com'
  'cost-centre': 'lab'
}
