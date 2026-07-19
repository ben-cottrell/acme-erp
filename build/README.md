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

`-DeploymentScope` also accepts targeted scopes for local repair and faster iteration: `namespace`, `sqlserver`, `identity`, `gateway`, and `routes`. For example, use `-DeploymentScope gateway` to reapply only the Gravitee gateway without restarting SQL Server or Authentik.

The default gateway exposure mode is `-GatewayExposure PortForward`. It deploys the Gravitee gateway as a `ClusterIP` service and starts `kubectl port-forward` for `http://localhost:8082`. Use `-GatewayExposure LoadBalancer` only when you specifically want Docker Desktop to allocate the local LoadBalancer endpoint, or `-GatewayExposure None` when validating only in-cluster behavior.

The bootstrap script stores local secret material in Kubernetes Secrets in the `erp-local` namespace. Existing cluster secrets are preserved by default. Use `-RotateSecrets` only when you intentionally want new local credentials.

Kubernetes Secret shape is declarative in `build/k8s/local-secrets/local-secret-values.json`. The bootstrap script renders those configured Kubernetes Secrets in memory and applies them directly to the cluster, so SQL Server and application secret material is not duplicated into generated files under `build/k8s/local-secrets/`.

The script automates:

- prerequisite checks for `dotnet`, Docker, `kubectl`, Skaffold, and Helm
- Docker Desktop Kubernetes context validation
- namespace creation
- local SQL Server, Authentik, and service credential generation
- Kubernetes Secret application from the declarative `build/k8s/local-secrets/local-secret-values.json` configuration
- generated Authentik Helm values creation under `build/.local/`
- Skaffold deployment for platform/app manifests, including local Helm chart rendering
- SQL Server bootstrap job readiness checks
- optional local Gravitee gateway port-forwarding for workstation routes

Manual setup still required:

- enable Kubernetes in Docker Desktop
- install Skaffold and Helm if missing
- keep the bootstrap-created Gravitee port-forward process running before browser testing or external UI validation

## Skaffold Profiles

```powershell
skaffold run -f .\build\skaffold.yaml -p platform
skaffold run -f .\build\skaffold.yaml -p apps
```

The `platform` profile applies namespaces, SQL Server, the Authentik bootstrap ConfigMap, Gravitee route ConfigMaps, and Skaffold-rendered Authentik and Gravitee Helm charts. `bootstrap-local.ps1` prepares the generated Authentik values file before invoking Skaffold.

The platform layer is also split into narrower profiles: `namespace`, `sqlserver`, `identity`, `gateway`, `gateway-loadbalancer`, and `routes`. The bootstrap script uses these narrower profiles internally so targeted repairs do not churn unrelated platform workloads. The combined `platform` profile remains available for direct Skaffold use.

The `apps` profile builds and deploys the 18 ASP.NET Core service images and includes the Gravitee route ConfigMaps so app deployments keep route ownership declarative.

Use `bootstrap-local.ps1 -DeploymentScope all` when platform and apps should be deployed together; the script runs the profiles in dependency order.

## Helm Local Tuning

The local Helm values are tuned for a single-node Docker Desktop cluster:

- Authentik runs one server, one worker, PostgreSQL, and Redis.
- Gravitee runs in database-less gateway-only mode for local development.
- Gravitee Management API, portal, UI, MongoDB, and Elasticsearch are not deployed locally.
- Gravitee route definitions are synchronized from Kubernetes ConfigMaps in `build/k8s/gravitee/routes/*.yaml`.
- Authentik and Gravitee Helm chart versions are pinned in `build/skaffold.yaml` for repeatable fresh-cluster bootstraps.

The default Gravitee gateway service is a `ClusterIP` service on port `8082`, with the workstation URL provided by `kubectl port-forward`. This is more reliable on Docker Desktop than relying on LoadBalancer allocation. To opt into Docker Desktop LoadBalancer behavior, use `bootstrap-local.ps1 -DeploymentScope gateway -GatewayExposure LoadBalancer` or the `gateway-loadbalancer` Skaffold profile. These settings are development-only and live in `build/k8s/authentik/values.local.yaml`, `build/k8s/gravitee/values.local.yaml`, and `build/k8s/gravitee/values.local-loadbalancer.yaml`.

The canonical local gateway URL remains `http://localhost:8082`.

## Destructive Teardown

To return the Docker Desktop environment to a clean slate before a full rebuild, run this from the repository root:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build\scripts\teardown-local.ps1
```

The script only runs when the active Kubernetes context is `docker-desktop`. It stops Skaffold and `kubectl port-forward` processes, deletes Skaffold-managed ERP resources, uninstalls **every Helm release in every namespace** in that Kubernetes context, deletes `erp-local`, removes local `acme-erp/*` images and `build/.local`, then runs `docker system prune -a --volumes --force`.

`docker system prune` removes every unused Docker container, image, volume, network, and build-cache entry on the machine. It retains resources currently in use. Do not run this script when Docker Desktop or its Kubernetes context contains workloads you need to preserve.

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

With the default bootstrap settings, the service should be `ClusterIP` and a `kubectl port-forward` process should expose port `8082` on localhost. If you selected `-GatewayExposure LoadBalancer`, the service should be `LoadBalancer` and expose port `8082` on localhost once Docker Desktop assigns an endpoint.

To also verify the application UIs from the developer workstation through the local Gravitee gateway, run:

```powershell
.\build\scripts\validate-local.ps1 -IncludeExternalUi
```

`-IncludeExternalUi` checks these public UI routes through `http://localhost:8082`: `/apps/sales-assistant/ui`, `/apps/customer-ordering/ui`, `/apps/buyer/ui`, `/apps/warehouse-operator/ui`, `/apps/fulfilment-operator/ui`, `/apps/inventory-supervisor/ui`, and `/apps/fulfilment-supervisor/ui`. The script does not create gateway exposure; use `bootstrap-local.ps1 -GatewayExposure PortForward` or manually run `kubectl port-forward -n erp-local svc/gravitee-apim-gateway 8082:8082` first. If the gateway is unreachable, core in-cluster validation may still be healthy while workstation gateway exposure is unavailable. If all UI routes return `404`, validation fails because the database-less gateway did not synchronize the route ConfigMaps.

## Local Recovery

- If Skaffold cannot render remote charts because a local Helm index is missing or stale, run `helm repo update` and retry.
- If the Gravitee gateway is absent from `erp-local`, run `kubectl get deployment,service -A | Select-String gravitee` to check whether rendered resources landed in another namespace, then re-run `bootstrap-local.ps1 -DeploymentScope gateway`.
- If Docker Desktop leaves the Gravitee LoadBalancer pending, switch to the default port-forward path: `bootstrap-local.ps1 -DeploymentScope gateway -GatewayExposure PortForward`.
- If only routes changed, run `bootstrap-local.ps1 -DeploymentScope routes` instead of reapplying the whole platform.
- If Authentik startup is interrupted and migrations become inconsistent, delete and recreate only `erp-local` before using the destructive teardown script.

For a destructive clean-slate rebuild and validation handoff, run `teardown-local.ps1` first, then follow `clean-slate-teardown-build-test-plan.md` from the build phase onward.
