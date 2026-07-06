# ACME ERP Local Runtime

This folder contains the first implementation slice for the local Docker Desktop Kubernetes runtime. It creates a single-node developer stack with Skaffold-built placeholder ASP.NET Core services, SQL Server, Authentik, and Gravitee configuration assets.

## Prerequisites

- .NET 10 SDK
- Docker Desktop with Kubernetes enabled
- `kubectl` configured with the `docker-desktop` context
- Skaffold
- Helm
- Optional: `sqlcmd` for manual SQL Server inspection

## Solution

All .NET projects belong to the top-level Visual Studio solution at `../Acme.Erp.slnx`. Do not create per-module solution files.

Useful checks:

```powershell
dotnet sln ..\Acme.Erp.slnx list
dotnet build ..\Acme.Erp.slnx
```

## Placeholder Services

| Service | Project | Image | Route |
|---|---|---|---|
| Sales API | `../src/Sales/Acme.Erp.Sales.Api/Acme.Erp.Sales.Api.csproj` | `acme-erp/sales-api` | `/sales/api` |
| Sales UI | `../src/Sales/Acme.Erp.Sales.Ui/Acme.Erp.Sales.Ui.csproj` | `acme-erp/sales-ui` | `/sales/ui` |
| Purchasing API | `../src/Purchasing/Acme.Erp.Purchasing.Api/Acme.Erp.Purchasing.Api.csproj` | `acme-erp/purchasing-api` | `/purchasing/api` |
| Purchasing UI | `../src/Purchasing/Acme.Erp.Purchasing.Ui/Acme.Erp.Purchasing.Ui.csproj` | `acme-erp/purchasing-ui` | `/purchasing/ui` |
| Inventory Management API | `../src/InventoryManagement/Acme.Erp.InventoryManagement.Api/Acme.Erp.InventoryManagement.Api.csproj` | `acme-erp/inventory-management-api` | `/inventory/api` |
| Inventory Management UI | `../src/InventoryManagement/Acme.Erp.InventoryManagement.Ui/Acme.Erp.InventoryManagement.Ui.csproj` | `acme-erp/inventory-management-ui` | `/inventory/ui` |
| Order Fulfilment API | `../src/OrderFulfilment/Acme.Erp.OrderFulfilment.Api/Acme.Erp.OrderFulfilment.Api.csproj` | `acme-erp/order-fulfilment-api` | `/fulfilment/api` |
| Order Fulfilment UI | `../src/OrderFulfilment/Acme.Erp.OrderFulfilment.Ui/Acme.Erp.OrderFulfilment.Ui.csproj` | `acme-erp/order-fulfilment-ui` | `/fulfilment/ui` |

Each service exposes `/healthz` and `/readyz`. API services also expose `/openapi/v1.json` and a placeholder module route.

## First-Run Bootstrap

Run this from the repository root:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build\scripts\bootstrap-local.ps1 -Profile platform
.\build\scripts\bootstrap-local.ps1 -Profile apps
```

The execution policy command affects only the current PowerShell process and is needed on machines that block local script execution by default.

Use `-Profile all` to deploy both layers in one run. Use `-SkipDeploy` to generate/apply prerequisites and secrets without invoking Skaffold or Helm.

The bootstrap script creates local secret material under `build/.local/secrets.json`, which is ignored by Git. Existing secrets are preserved by default. Use `-RotateSecrets` only when you intentionally want new local credentials.

The script automates:

- prerequisite checks for `dotnet`, Docker, `kubectl`, Skaffold, and Helm
- Docker Desktop Kubernetes context validation
- namespace creation
- local SQL Server, Authentik, Gravitee, OIDC, and service credential generation
- Kubernetes Secret creation
- Skaffold deployment for platform/app manifests
- Authentik and Gravitee Helm installation using local values files
- SQL Server bootstrap job readiness checks

Manual setup still required:

- enable Kubernetes in Docker Desktop
- install Skaffold and Helm if missing
- optionally map `erp.local.test` to `127.0.0.1` in the hosts file for browser testing

## Skaffold Profiles

```powershell
skaffold run -f .\build\skaffold.yaml -p platform
skaffold run -f .\build\skaffold.yaml -p apps
skaffold run -f .\build\skaffold.yaml -p all
```

The `platform` profile applies namespaces, SQL Server, Authentik bootstrap config, and Gravitee route config. Authentik and Gravitee Helm releases are installed by `bootstrap-local.ps1` because their chart values need generated local secrets.

The `apps` profile builds and deploys the eight placeholder ASP.NET Core images.

## Helm Local Tuning

The local Helm values are tuned for a single-node Docker Desktop cluster:

- Authentik runs one server, one worker, PostgreSQL, and Redis.
- Gravitee runs one API, gateway, portal, and UI pod.
- Gravitee's bundled Elasticsearch runs one pod for each role, disables the unavailable Bitnami `os-shell` sysctl init image, and uses zero index replicas for local single-node health.
- Gravitee's bundled MongoDB runs as a one-member replica set without an arbiter and disables strict container security contexts required by the current legacy Bitnami image.

These settings are development-only and live in `build/k8s/authentik/values.local.yaml` and `build/k8s/gravitee/values.local.yaml`.

## Validation

Run:

```powershell
.\build\scripts\validate-local.ps1
```

The validation script builds the solution, checks expected Kubernetes secrets/resources, waits for SQL Server bootstrap completion, waits for Authentik and Gravitee workloads, verifies the route ConfigMap exists, and performs in-cluster HTTP checks against the placeholder services plus Authentik and Gravitee endpoints. Gravitee route publication through the Management API is not implemented yet, so app routes are validated directly through their ClusterIP services.

For a destructive clean-slate rebuild and validation handoff, use `clean-slate-teardown-build-test-plan.md`.
