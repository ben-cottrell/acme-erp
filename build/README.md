# ACME ERP Local Runtime

This folder contains the local Docker Desktop Kubernetes runtime. It creates a single-node developer stack with Skaffold-built domain APIs, application API/UI pairs, SQL Server, Authentik, and Gravitee configuration assets.

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

## Services

| Service | Project | Image | Route |
|---|---|---|---|
| Sales API | `../src/Domain/Sales/Acme.Erp.Sales.Api/Acme.Erp.Sales.Api.csproj` | `acme-erp/sales-api` | `/domain/sales/api` |
| Purchasing API | `../src/Domain/Purchasing/Acme.Erp.Purchasing.Api/Acme.Erp.Purchasing.Api.csproj` | `acme-erp/purchasing-api` | `/domain/purchasing/api` |
| Inventory Management API | `../src/Domain/InventoryManagement/Acme.Erp.InventoryManagement.Api/Acme.Erp.InventoryManagement.Api.csproj` | `acme-erp/inventory-management-api` | `/domain/inventory/api` |
| Order Fulfilment API | `../src/Domain/OrderFulfilment/Acme.Erp.OrderFulfilment.Api/Acme.Erp.OrderFulfilment.Api.csproj` | `acme-erp/order-fulfilment-api` | `/domain/fulfilment/api` |
| Sales Assistant API/UI | `../src/Applications/SalesAssistant/` | `acme-erp/sales-assistant-api`, `acme-erp/sales-assistant-ui` | `/apps/sales-assistant/api`, `/apps/sales-assistant/ui` |
| Customer Ordering API/UI | `../src/Applications/CustomerOrdering/` | `acme-erp/customer-ordering-api`, `acme-erp/customer-ordering-ui` | `/apps/customer-ordering/api`, `/apps/customer-ordering/ui` |
| Buyer API/UI | `../src/Applications/Buyer/` | `acme-erp/buyer-api`, `acme-erp/buyer-ui` | `/apps/buyer/api`, `/apps/buyer/ui` |
| Warehouse Operator API/UI | `../src/Applications/WarehouseOperator/` | `acme-erp/warehouse-operator-api`, `acme-erp/warehouse-operator-ui` | `/apps/warehouse-operator/api`, `/apps/warehouse-operator/ui` |
| Fulfilment Operator API/UI | `../src/Applications/FulfilmentOperator/` | `acme-erp/fulfilment-operator-api`, `acme-erp/fulfilment-operator-ui` | `/apps/fulfilment-operator/api`, `/apps/fulfilment-operator/ui` |
| Inventory Supervisor API/UI | `../src/Applications/InventorySupervisor/` | `acme-erp/inventory-supervisor-api`, `acme-erp/inventory-supervisor-ui` | `/apps/inventory-supervisor/api`, `/apps/inventory-supervisor/ui` |
| Fulfilment Supervisor API/UI | `../src/Applications/FulfilmentSupervisor/` | `acme-erp/fulfilment-supervisor-api`, `acme-erp/fulfilment-supervisor-ui` | `/apps/fulfilment-supervisor/api`, `/apps/fulfilment-supervisor/ui` |
| Security Administration API/UI | `../src/Applications/SecurityAdministration/` | `acme-erp/security-administration-api`, `acme-erp/security-administration-ui` | `/apps/security-administration/api`, `/apps/security-administration/ui` |
| Audit Reporting API/UI | `../src/Applications/AuditReporting/` | `acme-erp/audit-reporting-api`, `acme-erp/audit-reporting-ui` | `/apps/audit-reporting/api`, `/apps/audit-reporting/ui` |

Each service exposes `/healthz` and `/readyz`. API services also expose `/openapi/v1.json`. Domain APIs own SQL Server connection string configuration. Application APIs and UIs do not own database configuration.

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

The `apps` profile builds and deploys the 22 ASP.NET Core service images.

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

The validation script builds the solution, checks expected Kubernetes secrets/resources, waits for SQL Server bootstrap completion, waits for Authentik and Gravitee workloads, verifies the route ConfigMap exists, and performs in-cluster HTTP checks against all domain APIs, application APIs, application UIs, Authentik, and Gravitee endpoints. Gravitee route publication through the Management API is not implemented yet, so app routes are validated directly through their ClusterIP services.

For a destructive clean-slate rebuild and validation handoff, use `clean-slate-teardown-build-test-plan.md`.
