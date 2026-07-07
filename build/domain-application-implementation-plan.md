# Domain/Application Architecture Implementation Plan

This plan is for an implementation agent that must replace the current placeholder API/UI projects with the domain/application architecture documented in `docs/architecture/domain-and-application-boundaries.md`.

The existing API and UI projects are placeholders. Do not preserve or migrate them. Delete the old placeholder source trees and service manifests, then scaffold replacement projects and deployment assets from the new architecture.

## Success Criteria

The task is complete only when all of the following are true:

- The old placeholder project folders under `src/Sales`, `src/Purchasing`, `src/InventoryManagement`, and `src/OrderFulfilment` are removed.
- The old Kubernetes service manifests for module UIs and module APIs are removed.
- `Acme.Erp.slnx` contains only the new domain API projects and application API/UI projects.
- Domain APIs exist for Sales, Purchasing, Inventory Management, and Order Fulfilment.
- Application API/UI pairs exist for Sales Assistant, Customer Ordering, Buyer, Warehouse Operator, Fulfilment Operator, Inventory Supervisor, and Fulfilment Supervisor.
- Domain APIs have database connection string configuration for their owned SQL Server database.
- Application APIs and UIs have no database connection string, EF Core migration, or SQL Server access configuration.
- Gravitee route configuration uses `/domain/<domain>/api` for domain APIs and `/apps/<application>/api|ui` for application services.
- `build/skaffold.yaml` builds every replacement service image and no old placeholder image.
- `build/k8s/services/` contains manifests for every replacement service and no old placeholder service manifest.
- `.github/workflows/ci-docker-images.yml` builds, inspects, and publishes every replacement service image and no old placeholder image.
- All GitHub Actions workflows are free of old `src/Sales`, `src/Purchasing`, `src/InventoryManagement`, `src/OrderFulfilment`, and old domain UI references.
- `build/scripts/validate-local.ps1` validates the new services, routes, health endpoints, readiness endpoints, and OpenAPI endpoints.
- `dotnet build Acme.Erp.slnx`, `skaffold diagnose -f build/skaffold.yaml`, and `./build/scripts/validate-local.ps1` succeed.

## Target Project Inventory

### Domain API Projects

Domain APIs are database-owning WebAPI services. They expose OpenAPI and health/readiness endpoints. They may use EF Core later, but initial scaffolding may keep placeholder endpoints while preserving database ownership configuration.

| Domain | Project path | Assembly/root namespace | Image | Kubernetes service | Route | Database secret key |
|---|---|---|---|---|---|---|
| Sales | `src/Domain/Sales/Acme.Erp.Sales.Api` | `Acme.Erp.Sales.Api` | `acme-erp/sales-api` | `sales-api` | `/domain/sales/api` | `sales` |
| Purchasing | `src/Domain/Purchasing/Acme.Erp.Purchasing.Api` | `Acme.Erp.Purchasing.Api` | `acme-erp/purchasing-api` | `purchasing-api` | `/domain/purchasing/api` | `purchasing` |
| Inventory Management | `src/Domain/InventoryManagement/Acme.Erp.InventoryManagement.Api` | `Acme.Erp.InventoryManagement.Api` | `acme-erp/inventory-management-api` | `inventory-management-api` | `/domain/inventory/api` | `inventory` |
| Order Fulfilment | `src/Domain/OrderFulfilment/Acme.Erp.OrderFulfilment.Api` | `Acme.Erp.OrderFulfilment.Api` | `acme-erp/order-fulfilment-api` | `order-fulfilment-api` | `/domain/fulfilment/api` | `fulfilment` |

### Application API/UI Projects

Each application has exactly one API and exactly one UI. Application UIs call only their paired application API. Application APIs call domain APIs and do not own databases.

| Application | API path | UI path | API image | UI image | API service | UI service | API route | UI route |
|---|---|---|---|---|---|---|---|---|
| Sales Assistant | `src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Api` | `src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Ui` | `acme-erp/sales-assistant-api` | `acme-erp/sales-assistant-ui` | `sales-assistant-api` | `sales-assistant-ui` | `/apps/sales-assistant/api` | `/apps/sales-assistant/ui` |
| Customer Ordering | `src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Api` | `src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Ui` | `acme-erp/customer-ordering-api` | `acme-erp/customer-ordering-ui` | `customer-ordering-api` | `customer-ordering-ui` | `/apps/customer-ordering/api` | `/apps/customer-ordering/ui` |
| Buyer | `src/Applications/Buyer/Acme.Erp.Buyer.Api` | `src/Applications/Buyer/Acme.Erp.Buyer.Ui` | `acme-erp/buyer-api` | `acme-erp/buyer-ui` | `buyer-api` | `buyer-ui` | `/apps/buyer/api` | `/apps/buyer/ui` |
| Warehouse Operator | `src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Api` | `src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Ui` | `acme-erp/warehouse-operator-api` | `acme-erp/warehouse-operator-ui` | `warehouse-operator-api` | `warehouse-operator-ui` | `/apps/warehouse-operator/api` | `/apps/warehouse-operator/ui` |
| Fulfilment Operator | `src/Applications/FulfilmentOperator/Acme.Erp.FulfilmentOperator.Api` | `src/Applications/FulfilmentOperator/Acme.Erp.FulfilmentOperator.Ui` | `acme-erp/fulfilment-operator-api` | `acme-erp/fulfilment-operator-ui` | `fulfilment-operator-api` | `fulfilment-operator-ui` | `/apps/fulfilment-operator/api` | `/apps/fulfilment-operator/ui` |
| Inventory Supervisor | `src/Applications/InventorySupervisor/Acme.Erp.InventorySupervisor.Api` | `src/Applications/InventorySupervisor/Acme.Erp.InventorySupervisor.Ui` | `acme-erp/inventory-supervisor-api` | `acme-erp/inventory-supervisor-ui` | `inventory-supervisor-api` | `inventory-supervisor-ui` | `/apps/inventory-supervisor/api` | `/apps/inventory-supervisor/ui` |
| Fulfilment Supervisor | `src/Applications/FulfilmentSupervisor/Acme.Erp.FulfilmentSupervisor.Api` | `src/Applications/FulfilmentSupervisor/Acme.Erp.FulfilmentSupervisor.Ui` | `acme-erp/fulfilment-supervisor-api` | `acme-erp/fulfilment-supervisor-ui` | `fulfilment-supervisor-api` | `fulfilment-supervisor-ui` | `/apps/fulfilment-supervisor/api` | `/apps/fulfilment-supervisor/ui` |

## Phase 1: Preflight

Run from the repository root.

```powershell
Set-Location C:/dev/acme-erp
git status --short
dotnet --version
dotnet sln Acme.Erp.slnx list
skaffold diagnose -f build/skaffold.yaml
```

If the worktree contains user changes unrelated to this architecture migration, do not revert them. Work around them or ask for direction if they block the migration.

## Phase 2: Delete Old Placeholder Assets

Delete the old source folders entirely:

```text
src/Sales/
src/Purchasing/
src/InventoryManagement/
src/OrderFulfilment/
```

Delete the old service manifests entirely:

```text
build/k8s/services/sales-api.yaml
build/k8s/services/sales-ui.yaml
build/k8s/services/purchasing-api.yaml
build/k8s/services/purchasing-ui.yaml
build/k8s/services/inventory-management-api.yaml
build/k8s/services/inventory-management-ui.yaml
build/k8s/services/order-fulfilment-api.yaml
build/k8s/services/order-fulfilment-ui.yaml
```

Replace `Acme.Erp.slnx` instead of trying to preserve the old folder layout.

## Phase 3: Scaffold Replacement .NET Projects

Use .NET 10 web templates. Preserve the existing project settings from the placeholder `.csproj` files unless a central props file is introduced separately:

```xml
<TargetFramework>net10.0</TargetFramework>
<Nullable>enable</Nullable>
<ImplicitUsings>enable</ImplicitUsings>
<AnalysisLevel>latest-all</AnalysisLevel>
<TreatWarningsAsErrors>true</TreatWarningsAsErrors>
<EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
<AnalysisMode>AllEnabledByDefault</AnalysisMode>
<InvariantGlobalization>true</InvariantGlobalization>
```

For each domain API project:

- Use `Microsoft.NET.Sdk.Web`.
- Add `Microsoft.AspNetCore.OpenApi`.
- Map `/openapi/v1.json`, `/healthz`, `/readyz`, and the domain route root.
- Keep controllers enabled for future vertical-slice implementation.
- Read `ConnectionStrings__DomainDatabase` from configuration. It is acceptable for the placeholder endpoint not to open the database yet, but the deployment manifest must provide the connection string.
- Do not add UI folders or Razor Pages to domain API projects.

For each application API project:

- Use `Microsoft.NET.Sdk.Web`.
- Add `Microsoft.AspNetCore.OpenApi`.
- Map `/openapi/v1.json`, `/healthz`, `/readyz`, and the application API route root.
- Configure typed or named HTTP client placeholders for domain APIs the application consumes.
- Do not add EF Core packages, migrations, `DbContext`, repositories, or database connection strings.

For each application UI project:

- Use `Microsoft.NET.Sdk.Web`.
- Enable Razor Pages.
- Map `/healthz`, `/readyz`, and the application UI route root.
- Add a minimal page that identifies the application and calls no database.
- Configure the paired application API base address only. Do not configure direct domain API calls from UI projects.

Recommended placeholder route behavior:

| Service kind | Route root response |
|---|---|
| Domain API | `GET /domain/<domain>/api` returns service name, kind `domain-api`, and owned domain. |
| Application API | `GET /apps/<application>/api` returns service name, kind `application-api`, paired UI route, and consumed domain API names. |
| Application UI | `GET /apps/<application>/ui` returns the Razor Pages application landing page. |

## Phase 4: Update the Solution File

`Acme.Erp.slnx` must contain these folders and projects:

```text
/src/Domain/Sales/Acme.Erp.Sales.Api
/src/Domain/Purchasing/Acme.Erp.Purchasing.Api
/src/Domain/InventoryManagement/Acme.Erp.InventoryManagement.Api
/src/Domain/OrderFulfilment/Acme.Erp.OrderFulfilment.Api
/src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Api
/src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Ui
/src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Api
/src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Ui
/src/Applications/Buyer/Acme.Erp.Buyer.Api
/src/Applications/Buyer/Acme.Erp.Buyer.Ui
/src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Api
/src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Ui
/src/Applications/FulfilmentOperator/Acme.Erp.FulfilmentOperator.Api
/src/Applications/FulfilmentOperator/Acme.Erp.FulfilmentOperator.Ui
/src/Applications/InventorySupervisor/Acme.Erp.InventorySupervisor.Api
/src/Applications/InventorySupervisor/Acme.Erp.InventorySupervisor.Ui
/src/Applications/FulfilmentSupervisor/Acme.Erp.FulfilmentSupervisor.Api
/src/Applications/FulfilmentSupervisor/Acme.Erp.FulfilmentSupervisor.Ui
```

Validation after this phase:

```powershell
dotnet sln Acme.Erp.slnx list
dotnet build Acme.Erp.slnx
```

## Phase 5: Dockerfiles

Create one Dockerfile beside each replacement project. Use the same multi-stage pattern as the existing placeholders, but update restore/publish paths and entrypoint DLL names.

Example required changes per service:

- Domain Sales API Dockerfile restores `src/Domain/Sales/Acme.Erp.Sales.Api/Acme.Erp.Sales.Api.csproj` and runs `Acme.Erp.Sales.Api.dll`.
- Warehouse Operator API Dockerfile restores `src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Api/Acme.Erp.WarehouseOperator.Api.csproj` and runs `Acme.Erp.WarehouseOperator.Api.dll`.
- Warehouse Operator UI Dockerfile restores `src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Ui/Acme.Erp.WarehouseOperator.Ui.csproj` and runs `Acme.Erp.WarehouseOperator.Ui.dll`.

All service containers should listen on port `8080` through `ASPNETCORE_URLS=http://+:8080`.

## Phase 6: Kubernetes Service Manifests

Create one manifest per replacement service under `build/k8s/services/`.

Domain API manifests:

- Use `app.kubernetes.io/component: domain-api`.
- Include `ConnectionStrings__DomainDatabase` from `erp-sqlserver-connection-strings` with the correct key: `sales`, `purchasing`, `inventory`, or `fulfilment`.
- Expose port 80 targeting container port 8080.
- Keep `/healthz` liveness and `/readyz` readiness probes.

Application API manifests:

- Use `app.kubernetes.io/component: application-api`.
- Do not include SQL Server connection string environment variables.
- Include domain API base URL environment variables for consumed domains, for example:
  - `DomainApis__Sales=http://sales-api/domain/sales/api`
  - `DomainApis__Purchasing=http://purchasing-api/domain/purchasing/api`
  - `DomainApis__InventoryManagement=http://inventory-management-api/domain/inventory/api`
  - `DomainApis__OrderFulfilment=http://order-fulfilment-api/domain/fulfilment/api`
- Expose port 80 targeting container port 8080.
- Keep `/healthz` liveness and `/readyz` readiness probes.

Application UI manifests:

- Use `app.kubernetes.io/component: application-ui`.
- Do not include SQL Server connection string environment variables.
- Include only the paired application API base URL, for example `ApplicationApi__BaseUrl=http://warehouse-operator-api/apps/warehouse-operator/api`.
- Expose port 80 targeting container port 8080.
- Keep `/healthz` liveness and `/readyz` readiness probes.

Recommended manifest filenames:

```text
sales-api.yaml
purchasing-api.yaml
inventory-management-api.yaml
order-fulfilment-api.yaml
sales-assistant-api.yaml
sales-assistant-ui.yaml
customer-ordering-api.yaml
customer-ordering-ui.yaml
buyer-api.yaml
buyer-ui.yaml
warehouse-operator-api.yaml
warehouse-operator-ui.yaml
fulfilment-operator-api.yaml
fulfilment-operator-ui.yaml
inventory-supervisor-api.yaml
inventory-supervisor-ui.yaml
fulfilment-supervisor-api.yaml
fulfilment-supervisor-ui.yaml
```

## Phase 7: Skaffold

Replace `build/skaffold.yaml` artifacts with all 18 replacement images.

Rules:

- Keep the existing `platform`, `apps`, and `all` profiles.
- Keep platform manifests in the `platform` profile.
- Keep `build/k8s/services/*.yaml` in the `apps` profile.
- Ensure no artifact references `src/Sales`, `src/Purchasing`, `src/InventoryManagement`, or `src/OrderFulfilment`.
- Ensure every replacement Dockerfile is referenced exactly once.

Validation after this phase:

```powershell
skaffold diagnose -f build/skaffold.yaml
```

## Phase 8: CI/CD Pipelines

Update the GitHub Actions pipelines so CI builds the same replacement service inventory as Skaffold.

Primary workflow to update:

```text
.github/workflows/ci-docker-images.yml
```

This workflow currently contains the old eight-image matrix. Replace that matrix with all 18 replacement images and Dockerfile paths:

| Image | Dockerfile |
|---|---|
| `sales-api` | `src/Domain/Sales/Acme.Erp.Sales.Api/Dockerfile` |
| `purchasing-api` | `src/Domain/Purchasing/Acme.Erp.Purchasing.Api/Dockerfile` |
| `inventory-management-api` | `src/Domain/InventoryManagement/Acme.Erp.InventoryManagement.Api/Dockerfile` |
| `order-fulfilment-api` | `src/Domain/OrderFulfilment/Acme.Erp.OrderFulfilment.Api/Dockerfile` |
| `sales-assistant-api` | `src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Api/Dockerfile` |
| `sales-assistant-ui` | `src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Ui/Dockerfile` |
| `customer-ordering-api` | `src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Api/Dockerfile` |
| `customer-ordering-ui` | `src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Ui/Dockerfile` |
| `buyer-api` | `src/Applications/Buyer/Acme.Erp.Buyer.Api/Dockerfile` |
| `buyer-ui` | `src/Applications/Buyer/Acme.Erp.Buyer.Ui/Dockerfile` |
| `warehouse-operator-api` | `src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Api/Dockerfile` |
| `warehouse-operator-ui` | `src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Ui/Dockerfile` |
| `fulfilment-operator-api` | `src/Applications/FulfilmentOperator/Acme.Erp.FulfilmentOperator.Api/Dockerfile` |
| `fulfilment-operator-ui` | `src/Applications/FulfilmentOperator/Acme.Erp.FulfilmentOperator.Ui/Dockerfile` |
| `inventory-supervisor-api` | `src/Applications/InventorySupervisor/Acme.Erp.InventorySupervisor.Api/Dockerfile` |
| `inventory-supervisor-ui` | `src/Applications/InventorySupervisor/Acme.Erp.InventorySupervisor.Ui/Dockerfile` |
| `fulfilment-supervisor-api` | `src/Applications/FulfilmentSupervisor/Acme.Erp.FulfilmentSupervisor.Api/Dockerfile` |
| `fulfilment-supervisor-ui` | `src/Applications/FulfilmentSupervisor/Acme.Erp.FulfilmentSupervisor.Ui/Dockerfile` |

Review these workflows for old path or image references and update only where needed:

```text
.github/workflows/ci.yml
.github/workflows/ci-build.yml
.github/workflows/ci-codeql.yml
.github/workflows/ci-test.yml
.github/workflows/ci-coverage.yml
.github/workflows/ci-vulnerability-scan.yml
.github/workflows/ci-dependency-review.yml
.github/workflows/ci-version.yml
```

Expected workflow behavior after the migration:

- `ci.yml` keeps the existing gate order: version, vulnerability scan, dependency review, build, CodeQL, test, coverage, Docker images.
- Build, test, coverage, vulnerability, and CodeQL workflows continue to operate against `Acme.Erp.slnx` unless they contain old explicit project paths.
- Docker image publishing still targets GHCR using the existing `ghcr.io/<owner>/<repo>/<image>` naming behavior.
- Docker image inspection still verifies both the GitVersion semantic version tag and short-SHA tag for every image.
- Pull requests build and inspect images but do not publish them.

Also update `.github/agents/ci-cd-pipeline-scaffolder.agent.md` if it remains in the repository. Its repository facts should describe domain APIs under `src/Domain`, application API/UI projects under `src/Applications`, and Dockerfiles living beside each service project.

Validation after this phase:

```powershell
rg "src/(Sales|Purchasing|InventoryManagement|OrderFulfilment)" .github
rg "Acme\.Erp\.(Sales|Purchasing|InventoryManagement|OrderFulfilment)\.Ui" .github
rg "sales-ui|purchasing-ui|inventory-management-ui|order-fulfilment-ui" .github
```

Expected result: no active workflow or agent references to old project paths, old domain UI project names, or old domain UI image names.

## Phase 9: Gravitee Routes

Replace the route list in `build/k8s/gravitee/route-config.yaml`.

Domain API route entries:

```json
{ "name": "sales-api", "path": "/domain/sales/api", "target": "http://sales-api.erp-local.svc.cluster.local/domain/sales/api", "openApi": "http://sales-api.erp-local.svc.cluster.local/openapi/v1.json" }
{ "name": "purchasing-api", "path": "/domain/purchasing/api", "target": "http://purchasing-api.erp-local.svc.cluster.local/domain/purchasing/api", "openApi": "http://purchasing-api.erp-local.svc.cluster.local/openapi/v1.json" }
{ "name": "inventory-management-api", "path": "/domain/inventory/api", "target": "http://inventory-management-api.erp-local.svc.cluster.local/domain/inventory/api", "openApi": "http://inventory-management-api.erp-local.svc.cluster.local/openapi/v1.json" }
{ "name": "order-fulfilment-api", "path": "/domain/fulfilment/api", "target": "http://order-fulfilment-api.erp-local.svc.cluster.local/domain/fulfilment/api", "openApi": "http://order-fulfilment-api.erp-local.svc.cluster.local/openapi/v1.json" }
```

Add matching route entries for every application API and UI using the inventory table above. Application APIs include `openApi`; application UIs do not.

## Phase 10: SQL Server Bootstrap and Secrets

Keep the four existing domain databases and connection string secret keys:

```text
sales_db        -> sales
purchasing_db   -> purchasing
inventory_db    -> inventory
fulfilment_db   -> fulfilment
```

Do not add databases or SQL credentials for application services. If any generated manifest or appsetting adds application database configuration, remove it.

`build/scripts/bootstrap-local.ps1` should continue generating only the four domain database connection strings plus platform secrets.

## Phase 11: Validation Script

Update `build/scripts/validate-local.ps1` to validate the new service inventory.

Required changes:

- Replace all old route checks such as `http://sales-api/sales/api` with domain route checks such as `http://sales-api/domain/sales/api`.
- Remove all old module UI service checks.
- Add health, readiness, and route-root checks for all 4 domain APIs.
- Add health, readiness, and route-root checks for all 7 application APIs.
- Add health, readiness, and route-root checks for all 7 application UIs.
- Add OpenAPI checks for all domain APIs and application APIs: `http://<service>/openapi/v1.json`.
- Keep Authentik and Gravitee platform checks.

The validation script should keep building the solution first:

```powershell
dotnet sln Acme.Erp.slnx list
dotnet build Acme.Erp.slnx
```

## Phase 12: Documentation Consistency Check

After implementation, run these scans from the repository root:

```powershell
rg "src/(Sales|Purchasing|InventoryManagement|OrderFulfilment)" .
rg "Acme\.Erp\.(Sales|Purchasing|InventoryManagement|OrderFulfilment)\.Ui" .
rg "/(sales|purchasing|inventory|fulfilment)/(api|ui)" build docs src
rg "ConnectionStrings__(ModuleDatabase|.*Database)" src build/k8s/services
rg "sales-ui|purchasing-ui|inventory-management-ui|order-fulfilment-ui" .github build src
```

Expected results:

- The first two scans return no references to old source paths or old domain UI projects.
- The old route scan returns no active route/configuration references.
- Database connection strings appear only in domain API manifests and domain API configuration code.
- The old domain UI image scan returns no active workflow, Skaffold, manifest, or source references.

## Phase 13: Full Build, Pipeline, and Local Runtime Validation

Run these commands from the repository root:

```powershell
dotnet build Acme.Erp.slnx
skaffold diagnose -f build/skaffold.yaml
./build/scripts/validate-local.ps1
```

If Docker is available locally, build at least one domain API image and one application UI image using the same Dockerfiles referenced by the pipeline before relying on CI for the full 18-image matrix:

```powershell
docker build --file src/Domain/Sales/Acme.Erp.Sales.Api/Dockerfile --tag acme-erp/sales-api:local-ci-check .
docker build --file src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Ui/Dockerfile --tag acme-erp/warehouse-operator-ui:local-ci-check .
```

The full 18-image build, inspect, and publish behavior is validated by `.github/workflows/ci-docker-images.yml` in GitHub Actions.

Then, if the local cluster is available and the user wants runtime validation:

```powershell
./build/scripts/bootstrap-local.ps1 -DeploymentScope platform
./build/scripts/bootstrap-local.ps1 -DeploymentScope apps
./build/scripts/validate-local.ps1
```

## Common Pitfalls

- Do not scaffold domain UIs. Sales, Purchasing, Inventory Management, and Order Fulfilment are API-only domain bounded contexts.
- Do not give application APIs databases. Application APIs are orchestration services.
- Do not let application UIs call domain APIs directly. UIs call only their paired application API.
- Do not keep old `/sales/api`, `/sales/ui`, `/inventory/api`, `/inventory/ui`, `/purchasing/api`, `/purchasing/ui`, `/fulfilment/api`, or `/fulfilment/ui` routes.
- Do not preserve old placeholder projects; replace them with the new project inventory.
- Do not update SQL Server bootstrap to create application databases.
- Do not add services outside the active four-domain and seven-application inventory. Authentication and identity remain Authentik/Gravitee platform concerns, while access permissions are owned by each application workflow and paired domain API.
