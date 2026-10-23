# platform-shared

The resources every app of a department reuses, one set per department and
environment. One Bicep file serves every department; each department is two
parameter files.

| Resource | Name | Notes |
|---|---|---|
| Log Analytics | `log-<dept>-<env>` | 30-day retention |
| Container Apps environment | `cae-<dept>-<env>` | Consumption, no VNet (yet) |
| Container registry | `cr<dept>shared` | Dev only; prod pulls the same image. No admin user. SKU per department (`registrySku`) |

Apps never create these; they reference them as `existing`. Apps get into the
environment through the tier-0 "Container Apps Environment Joiner" role, assigned
by vending on one environment only.

## Layout

```
infra/main.bicep                    the resources (platform team owns it)
infra/teams/<dept>.dev.bicepparam   one department, development
infra/teams/<dept>.prod.bicepparam  one department, production
.github/workflows/infra.yml         what-if on PR, deploy dev on merge, prod after approval
.github/CODEOWNERS                  each department reviews its own files
```

Only the departments a change touches are deployed; a change to `main.bicep` or
to the workflow redeploys every department.

Everyone with read access sees every department's files. That is fine: they hold
names, region and tags, never secrets. What stays separate is who can deploy where.

## How departments are kept apart

| Layer | Department A cannot... | Because |
|---|---|---|
| Review | merge a change to B's files | CODEOWNERS + ruleset requiring code owner review |
| GitHub | run B's deploy job | environment `<B>-prod` has B's reviewers; `<B>-dev/-prod` deploy from `main` only |
| Azure | deploy into B's resource group | A's identity trusts only `environment:<A>-<env>` and is Contributor only on `rg-<A>-platform-<env>` |

Pull requests run what-if as `id-platform-plan` (What-If Reader): they can preview
but not change anything, and cannot read logs or images.

## Adding a department

See platform-vending's README ("Adding a department"). In this repo it is one pull
request: copy two files into `infra/teams/` (set `team`: lowercase letters and
digits, max 10), and add the department's team to CODEOWNERS.

## Repo variables

`AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_PLAN_CLIENT_ID` (tier-0 output
`platformPlanClientId`). Each environment `<dept>-<env>` holds `AZURE_CLIENT_ID`.
