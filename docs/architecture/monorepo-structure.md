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
  cross-cutting/
  inventory-management/
  order-fulfilment/
  purchasing/
  sales/
src/
  InventoryManagement/
  OrderFulfilment/
  Purchasing/
  Sales/
tests/
```

The top-level `Acme.Erp.slnx` is the only solution file. Do not create per-module solution files.

## Project Conventions

| Module | API project | UI project | Image names | Routes |
|---|---|---|---|---|
| Sales | `src/Sales/Acme.Erp.Sales.Api` | `src/Sales/Acme.Erp.Sales.Ui` | `acme-erp/sales-api`, `acme-erp/sales-ui` | `/sales/api`, `/sales/ui` |
| Purchasing | `src/Purchasing/Acme.Erp.Purchasing.Api` | `src/Purchasing/Acme.Erp.Purchasing.Ui` | `acme-erp/purchasing-api`, `acme-erp/purchasing-ui` | `/purchasing/api`, `/purchasing/ui` |
| Inventory Management | `src/InventoryManagement/Acme.Erp.InventoryManagement.Api` | `src/InventoryManagement/Acme.Erp.InventoryManagement.Ui` | `acme-erp/inventory-management-api`, `acme-erp/inventory-management-ui` | `/inventory/api`, `/inventory/ui` |
| Order Fulfilment | `src/OrderFulfilment/Acme.Erp.OrderFulfilment.Api` | `src/OrderFulfilment/Acme.Erp.OrderFulfilment.Ui` | `acme-erp/order-fulfilment-api`, `acme-erp/order-fulfilment-ui` | `/fulfilment/api`, `/fulfilment/ui` |

## Naming Rules

- Project names use `Acme.Erp.<Module>.<ServiceKind>`.
- Root namespaces match project names.
- Kubernetes service names use lower-kebab-case and match image names without the `acme-erp/` prefix.
- API routes use the module route segment plus `/api`.
- UI routes use the module route segment plus `/ui`.
- Dockerfiles stay beside the project they build.
- Kubernetes service manifests stay under `build/k8s/services/` and use the route and image conventions above.

## Source Organization

Module code is organized by bounded context first, then service, then vertical feature slices inside the service.

Recommended API shape:

```text
src/<Module>/Acme.Erp.<Module>.Api/
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

Recommended UI shape:

```text
src/<Module>/Acme.Erp.<Module>.Ui/
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

## Shared Code Placement

Shared projects are allowed only for cross-cutting concerns used by multiple services. Candidate shared project families are documented in `docs/architecture/cross-cutting-projects.md`.

Do not move module-specific domain rules, entities, workflow policies, or application services into shared projects. Prefer duplication over an incorrect shared abstraction when behavior belongs to one bounded context.

## Test Layout

Tests live under `tests/` and should mirror the owning source project and feature name.

Recommended pattern:

```text
tests/
  Sales/
    Acme.Erp.Sales.Api.Tests/
      SalesOrderEntry/
  InventoryManagement/
    Acme.Erp.InventoryManagement.Api.Tests/
      GoodsReceipt/
```

XUnit v3 is the test framework for all automated tests.

## Build and Deployment Assets

- `build/skaffold.yaml` defines local image builds and deployment profiles.
- `build/k8s/services/*.yaml` contains app workload and service manifests.
- `build/k8s/sqlserver/*` contains local SQL Server and database bootstrap assets.
- `build/k8s/authentik/*` contains local Authentik configuration assets.
- `build/k8s/gravitee/*` contains local Gravitee route and API management configuration assets.
- `build/scripts/bootstrap-local.ps1` bootstraps local secrets, platform dependencies, Helm releases, and app deployment.
- `build/scripts/validate-local.ps1` validates the local stack.

## Recommendations

- Keep generated or local-only secrets under ignored local paths such as `build/.local/`.
- Keep OpenAPI contracts close to the API that owns them, and publish through Gravitee.
- Keep database migrations close to the API or module-owned persistence project that owns the database.
- Keep module documentation under `docs/<module>/` and architecture decisions under `docs/architecture/`.

## Review Checklist

- [ ] Each service project is included in `Acme.Erp.slnx`.
- [ ] Each service image appears in `build/skaffold.yaml`.
- [ ] Each service has a Kubernetes manifest under `build/k8s/services/`.
- [ ] Namespaces, images, services, and routes follow the module naming table.
- [ ] New tests mirror the owning module and feature.
- [ ] Shared code is limited to cross-cutting concerns used by multiple modules.
