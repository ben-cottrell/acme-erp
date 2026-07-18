# Monorepo Structure

## Status

This document defines repository, project, namespace, image, route, and deployment asset conventions for the ACME ERP monorepo.

## Repository Layout

```text
Acme.Erp.slnx
build/
  skaffold.yaml
  k8s/
    authentik/
    gravitee/
    namespaces/
    services/
    sqlserver/
  scripts/
docs/
  architecture/
  application/
  domain/
  cross-cutting/              # legacy source requirements during migration
  inventory-management/       # legacy source requirements during migration
  order-fulfilment/           # legacy source requirements during migration
  purchasing/                 # legacy source requirements during migration
  sales/                      # legacy source requirements during migration
src/
  Applications/
  Domain/
tests/
```

The top-level `Acme.Erp.slnx` is the only solution file. Do not create per-domain or per-application solution files.

## Project Conventions

| Domain | API project | Image name | Route |
|---|---|---|---|
| Sales | `src/Domain/Sales/Acme.Erp.Sales.Api` | `acme-erp/sales-api` | `/domain/sales/api` |
| Purchasing | `src/Domain/Purchasing/Acme.Erp.Purchasing.Api` | `acme-erp/purchasing-api` | `/domain/purchasing/api` |
| Inventory Management | `src/Domain/InventoryManagement/Acme.Erp.InventoryManagement.Api` | `acme-erp/inventory-management-api` | `/domain/inventory/api` |
| Order Fulfilment | `src/Domain/OrderFulfilment/Acme.Erp.OrderFulfilment.Api` | `acme-erp/order-fulfilment-api` | `/domain/fulfilment/api` |

| Application | API project | UI project | Image names | Routes |
|---|---|---|---|---|
| Sales Assistant | `src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Api` | `src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Ui` | `acme-erp/sales-assistant-api`, `acme-erp/sales-assistant-ui` | `/apps/sales-assistant/api`, `/apps/sales-assistant/ui` |
| Customer Ordering | `src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Api` | `src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Ui` | `acme-erp/customer-ordering-api`, `acme-erp/customer-ordering-ui` | `/apps/customer-ordering/api`, `/apps/customer-ordering/ui` |
| Buyer | `src/Applications/Buyer/Acme.Erp.Buyer.Api` | `src/Applications/Buyer/Acme.Erp.Buyer.Ui` | `acme-erp/buyer-api`, `acme-erp/buyer-ui` | `/apps/buyer/api`, `/apps/buyer/ui` |
| Warehouse Operator | `src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Api` | `src/Applications/WarehouseOperator/Acme.Erp.WarehouseOperator.Ui` | `acme-erp/warehouse-operator-api`, `acme-erp/warehouse-operator-ui` | `/apps/warehouse-operator/api`, `/apps/warehouse-operator/ui` |
| Fulfilment Operator | `src/Applications/FulfilmentOperator/Acme.Erp.FulfilmentOperator.Api` | `src/Applications/FulfilmentOperator/Acme.Erp.FulfilmentOperator.Ui` | `acme-erp/fulfilment-operator-api`, `acme-erp/fulfilment-operator-ui` | `/apps/fulfilment-operator/api`, `/apps/fulfilment-operator/ui` |
| Inventory Supervisor | `src/Applications/InventorySupervisor/Acme.Erp.InventorySupervisor.Api` | `src/Applications/InventorySupervisor/Acme.Erp.InventorySupervisor.Ui` | `acme-erp/inventory-supervisor-api`, `acme-erp/inventory-supervisor-ui` | `/apps/inventory-supervisor/api`, `/apps/inventory-supervisor/ui` |
| Fulfilment Supervisor | `src/Applications/FulfilmentSupervisor/Acme.Erp.FulfilmentSupervisor.Api` | `src/Applications/FulfilmentSupervisor/Acme.Erp.FulfilmentSupervisor.Ui` | `acme-erp/fulfilment-supervisor-api`, `acme-erp/fulfilment-supervisor-ui` | `/apps/fulfilment-supervisor/api`, `/apps/fulfilment-supervisor/ui` |

The active MVP contains four domain API projects and seven application API/UI pairs. Security Administration and Audit Reporting are retired for MVP and must not be scaffolded from this structure.

## Naming Rules

- Domain project names use `Acme.Erp.<Domain>.<ServiceKind>`.
- Application project names use `Acme.Erp.<Application>.<ServiceKind>`.
- Root namespaces match project names.
- Kubernetes service names use lower-kebab-case and match image names without the `acme-erp/` prefix.
- Domain API routes use `/domain/<domain>/api`.
- Application API routes use `/apps/<application>/api`.
- Application UI routes use `/apps/<application>/ui`.
- Dockerfiles stay beside the project they build.
- Kubernetes service manifests stay under `build/k8s/services/` and use the route and image conventions above.

## Source Organization

Domain code is organized by bounded context first, then service, then vertical feature slices inside the service. Application code is organized by role or workload first, then paired API/UI services.

Recommended API shape:

```text
src/Domain/<Domain>/Acme.Erp.<Domain>.Api/
  <FeatureOrWorkflow>/
    <Feature>Controller.cs
    <Command>.cs
    <Command>Handler.cs
    <Query>.cs
    <QueryHandler.cs
    <Entity>.cs
    <EntityConfiguration.cs
    <IntegrationContracts>.cs
  Program.cs
  appsettings.json
```

Recommended application API shape:

```text
src/Applications/<Application>/Acme.Erp.<Application>.Api/
  <Workflow>/
    <Workflow>Controller.cs
    <CommandOrQuery>.cs
    <DomainClient>.cs
  Program.cs
  appsettings.json
```

Recommended application UI shape:

```text
src/Applications/<Application>/Acme.Erp.<Application>.Ui/
  Pages/
    <FeatureOrWorkflow>/
      Index.cshtml
      Index.cshtml.cs
      Details.cshtml
      Details.cshtml.cs
  Program.cs
  appsettings.json
```

Avoid broad catch-all folders such as `Models`, `Helpers`, and `Utils` as primary organization. Feature names should describe ERP behavior, such as `SalesOrderEntry`, `GoodsReceipt`, `PurchaseOrderApproval`, or `FulfilmentShipping`.

Application APIs must not contain EF Core `DbContext` types, migrations, repositories, or durable business entities.

## Common Convention Placement

Common behavior such as OpenAPI publication, health checks, logging, diagnostics, service identity, and authorization is documented as conventions and implemented inside the owning service.

Do not move domain-specific rules, entities, workflow policies, or application services into common infrastructure. Prefer local implementation over an incorrect abstraction when behavior belongs to one bounded context.

## Test Layout

Tests live under `tests/` and should mirror the owning source project and feature name.

Recommended pattern:

```text
tests/
  Domain/
    Sales/
    Acme.Erp.Sales.Api.Tests/
      SalesOrderEntry/
    InventoryManagement/
    Acme.Erp.InventoryManagement.Api.Tests/
      GoodsReceipt/
  Applications/
    WarehouseOperator/
      Acme.Erp.WarehouseOperator.Api.Tests/
        GoodsReceiptWorkflow/
```

XUnit v3 is the test framework for all automated tests.

## Build and Deployment Assets

- `build/skaffold.yaml` defines local image builds and deployment profiles.
- `build/k8s/services/*.yaml` contains app workload and service manifests.
- `build/k8s/sqlserver/*` contains local SQL Server and database bootstrap assets.
- `build/k8s/authentik/*` contains local Authentik configuration assets.
- `build/k8s/gravitee/*` contains local Gravitee route and API management configuration assets.
- `build/scripts/bootstrap-local.ps1` prepares local secrets and generated values, then invokes Skaffold-managed platform and app deployment.
- `build/scripts/validate-local.ps1` validates the local stack.

## Recommendations

- Keep generated or local-only secrets under ignored local paths such as `build/.local/`.
- Keep OpenAPI contracts close to the API that owns them, and publish through Gravitee.
- Keep database migrations close to the domain API or domain-owned persistence project that owns the database.
- Keep domain requirements under `docs/domain/<domain>/`, application requirements under `docs/application/<application>/`, and architecture decisions under `docs/architecture/`.

## Review Checklist

- [ ] Each service project is included in `Acme.Erp.slnx`.
- [ ] Each service image appears in `build/skaffold.yaml`.
- [ ] Each service has a Kubernetes manifest under `build/k8s/services/`.
- [ ] Namespaces, images, services, and routes follow the domain and application naming tables.
- [ ] New tests mirror the owning domain/application and feature.
- [ ] Common platform conventions are implemented inside the owning service unless a later explicit architecture decision reintroduces shared projects.
