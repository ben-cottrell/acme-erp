# Service Internal Architecture

## Status

This document defines the required internal architecture for domain WebAPI services, application WebAPI services, and Razor Pages services.

## Required Architectural Style

Each service uses layered architecture inside a vertical feature organization. Layers are logical boundaries; physical folders should remain feature-oriented.

| Logical layer | Responsibility | May depend on |
|---|---|---|
| API boundary | Controllers, request/response contracts, validation mapping, OpenAPI annotations | Application code and service-local API conventions |
| UI boundary | Razor Pages, page models, view models, API client calls | API client abstractions and UI-specific helpers inside the owning service |
| Application workflow | Commands, queries, handlers, orchestration, transaction boundaries | Domain, persistence abstractions, integration clients |
| Domain rules | Entities, value objects, domain services, status transitions, business invariants | No infrastructure dependencies |
| Persistence | EF Core `DbContext`, configurations, migrations, repositories where useful | Domain and application abstractions |
| Infrastructure/integrations | HTTP clients, Authentik/Gravitee integration support, courier clients, SQL Server providers, observability exporters | Application interfaces and service-local infrastructure |

Domain WebAPI services may use every layer in the table, including persistence. Application WebAPI services use API boundary, application workflow, and integration layers, but they must not use the persistence layer or own domain rules. Razor Pages UI services use the UI boundary layer and API client abstractions.

## Vertical Slice Organization

Group files by ERP behavior. A slice should contain the controller, commands, handlers, domain rules, persistence configuration, and local contracts needed for that behavior when those files are specific to the slice.

Examples:

- `SalesOrderEntry`
- `InventoryAvailability`
- `GoodsReceipt`
- `StockCheck`
- `PurchaseOrderEntry`
- `BuyerRequestReview`
- `FulfilmentPicking`
- `FulfilmentShipping`

Recommended API example:

```text
Acme.Erp.InventoryManagement.Api/
  GoodsReceipt/
    GoodsReceiptsController.cs
    StartGoodsReceipt.cs
    RecordReceiptLine.cs
    BookMatchedReceipt.cs
    GoodsReceipt.cs
    GoodsReceiptLine.cs
    GoodsReceiptConfiguration.cs
    PurchasingPurchaseOrderClient.cs
```

Use technical folders only when they support a clear boundary that cuts across many features inside the service, such as `Database`, `OpenApi`, or `Security`. Do not use catch-all `Models`, `Helpers`, or `Utils` folders for core behavior.

## Domain WebAPI Service Rules

- APIs use ASP.NET Core WebAPI Controllers.
- Controllers stay thin: authenticate, authorize, bind, validate request shape, delegate to application workflow, and translate responses.
- Business rules live in domain/application code, not controller actions.
- Domain API services are the only processes that connect to domain databases.
- EF Core migrations are owned by the database-owning domain API service or an adjacent domain-owned persistence project.
- Public API contracts use OpenAPI 3.0.

## Application WebAPI Service Rules

- Application APIs use ASP.NET Core WebAPI Controllers.
- Application APIs orchestrate user-facing workflows by calling domain APIs.
- Application APIs do not own databases, EF Core migrations, or durable business state.
- Application APIs do not contain domain invariants or persistence logic.
- Application APIs may shape workflow-specific responses and compose multiple domain API responses for their paired UI.
- Application APIs call domain APIs using delegated user context or scoped service identities according to the workflow contract.
- Application APIs enforce route-level and workflow-level authorization for user experience, but domain APIs remain authoritative for business authorization.

## Razor Pages Service Rules

- Razor Pages apps use server-side rendering.
- Each Razor Pages application UI calls only its paired application API.
- UI services never use EF Core or direct SQL Server connections.
- Page models hold presentation flow and API client calls, not business invariants.
- UI services enforce route-level and page-level authorization for user experience, but domain APIs remain the authority for business authorization.
- UI validation improves ergonomics; API validation remains mandatory.

## Domain and Workflow Rules

- Status transitions are explicit and tested.
- Domain models use `System.Guid` identifiers backed by SQL Server `UNIQUEIDENTIFIER` columns.
- Cross-domain references are named external IDs, not navigation properties to another domain's database.
- Negative inventory balances are prohibited by Inventory Management domain rules.
- Inventory availability and completed stock checks are informational; a stock check cannot change balances or create movements.
- Inventory reservation covers every required line at fulfilment release; inventory consumes those exact quantities atomically at full fulfilment completion.
- Sales order and purchase order terms are mutable only in Draft and are fixed by submission or placement.
- Order Fulfilment confirms picking only when every released line and required serial matches exactly, then follows the defined packing, shipping, label, and completion transitions.

## Integration Rules

- Integration clients live behind application-owned interfaces so workflows can be tested without real external services.
- Integration payloads carry external IDs.
- Inbound integration handlers validate source, schema, authorization, and current state before mutating local data.

## Error and Failure Handling

- Validation failures return clear client errors and do not mutate state.
- Authorization failures fail closed.
- Application workflow failures roll back the transaction when the requested business change cannot be completed.

## Review Checklist

- [ ] Feature code is organized by ERP workflow rather than broad technical category.
- [ ] Controllers and Razor Page models stay thin.
- [ ] Domain rules do not depend on infrastructure.
- [ ] UI services have no database access.
- [ ] Application API services have no database access.
- [ ] Domain API services own persistence and migrations.
- [ ] Domain APIs enforce required permissions, data scopes, and state transitions.
- [ ] Cross-domain references use external IDs.
