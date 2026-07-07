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

Each service exposes `/healthz` and `/readyz`. API services also expose `/openapi/v1.json`. Domain APIs own SQL Server connection string configuration. Application APIs and UIs do not own database configuration.

## First-Run Bootstrap

Run this from the repository root:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build\scripts\bootstrap-local.ps1 -DeploymentScope platform
.\build\scripts\bootstrap-local.ps1 -DeploymentScope apps
```

The execution policy command affects only the current PowerShell process and is needed on machines that block local script execution by default.

Use `-DeploymentScope all` to deploy both layers in one run. Use `-SkipDeploy` to generate/apply prerequisites, secrets, and generated local values without invoking Skaffold.

The bootstrap script creates local secret material under `build/.local/secrets.json`, which is ignored by Git. Existing secrets are preserved by default. Use `-RotateSecrets` only when you intentionally want new local credentials.

The script automates:

- prerequisite checks for `dotnet`, Docker, `kubectl`, Skaffold, and Helm
- Docker Desktop Kubernetes context validation
- namespace creation
- local SQL Server, Authentik, and service credential generation
- Kubernetes Secret creation for SQL Server and service connection strings
- generated Authentik Helm values creation under `build/.local/`
- Skaffold deployment for platform/app manifests, including local Helm chart rendering
- SQL Server bootstrap job readiness checks

Manual setup still required:

- enable Kubernetes in Docker Desktop
- install Skaffold and Helm if missing
- wait for the Docker Desktop LoadBalancer endpoint before browser testing or external UI validation

## Skaffold Profiles

```powershell
skaffold run -f .\build\skaffold.yaml -p platform
skaffold run -f .\build\skaffold.yaml -p apps
```

The `platform` profile applies namespaces, SQL Server, the Authentik bootstrap ConfigMap, Gravitee route ConfigMaps, and Skaffold-rendered Authentik and Gravitee Helm charts. `bootstrap-local.ps1` prepares the generated Authentik values file before invoking Skaffold.

The `apps` profile builds and deploys the 18 ASP.NET Core service images and includes the Gravitee route ConfigMaps so app deployments keep route ownership declarative.

Use `bootstrap-local.ps1 -DeploymentScope all` when platform and apps should be deployed together; the script runs the profiles in dependency order.

## Helm Local Tuning

The local Helm values are tuned for a single-node Docker Desktop cluster:

- Authentik runs one server, one worker, PostgreSQL, and Redis.
- Gravitee runs in database-less gateway-only mode for local development.
- Gravitee Management API, portal, UI, MongoDB, and Elasticsearch are not deployed locally.
- Gravitee route definitions are synchronized from Kubernetes ConfigMaps in `build/k8s/gravitee/routes/*.yaml`.

The Gravitee gateway service is configured as a local Docker Desktop `LoadBalancer` on port `8082`, giving the workstation the canonical gateway URL `http://localhost:8082` without DNS or HOSTS changes. These settings are development-only and live in `build/k8s/authentik/values.local.yaml` and `build/k8s/gravitee/values.local.yaml`.

## Validation

Run:

```powershell
.\build\scripts\validate-local.ps1
```

The validation script builds the solution, checks expected Kubernetes secrets/resources, waits for SQL Server bootstrap completion, waits for Authentik and the Gravitee gateway workload, verifies the Gravitee route ConfigMaps exist, and performs in-cluster HTTP checks against all domain APIs, application APIs, application UIs, Authentik, and Gravitee endpoints through the Kubernetes service proxy. It does not create validation pods or gateway exposure.

To confirm Gravitee is exposed to the developer workstation through Docker Desktop, run:

```powershell
kubectl get service gravitee-apim-gateway -n erp-local
```

The service should be `LoadBalancer` and expose port `8082` on localhost once the platform deployment is ready.

To also verify the application UIs from the developer workstation through the local Gravitee gateway, run:

```powershell
.\build\scripts\validate-local.ps1 -IncludeExternalUi
```

`-IncludeExternalUi` checks these public UI routes through `http://localhost:8082`: `/apps/sales-assistant/ui`, `/apps/customer-ordering/ui`, `/apps/buyer/ui`, `/apps/warehouse-operator/ui`, `/apps/fulfilment-operator/ui`, `/apps/inventory-supervisor/ui`, and `/apps/fulfilment-supervisor/ui`. The script does not create gateway exposure; the Gravitee gateway service is exposed by the local Helm values as a Docker Desktop `LoadBalancer`. If the gateway is unreachable, or if all UI routes return `404`, validation fails because the database-less gateway did not synchronize the route ConfigMaps or the gateway exposure is incorrect.

For a destructive clean-slate rebuild and validation handoff, use `clean-slate-teardown-build-test-plan.md`.
