# Testing and Quality

## Status

This document defines automated testing, analyzer, formatting, build, validation, and quality gate expectations.

## Fixed Decisions

- Use XUnit v3 for automated tests.
- Use the latest C# language version on .NET 10.
- Enable nullable reference types.
- Enable full analyzers with the strictest feasible Microsoft-aligned settings.
- Treat warnings as errors where feasible.
- Validate the local stack using Docker Desktop Kubernetes and Skaffold.

## Test Strategy

| Test type | Scope | Examples |
|---|---|---|
| Unit tests | Domain rules and application workflow decisions without infrastructure | Sales release criteria, purchase order state transitions, inventory negative-balance prevention, fulfilment completion rules |
| Vertical slice tests | Feature command/query behavior with realistic dependency fakes or in-memory implementations where appropriate | Goods receipt validation, buyer request intake, sales order validation |
| API tests | Controller routing, authorization, validation, error responses, OpenAPI behavior | Required field validation, forbidden operations, business conflict responses |
| Integration tests | SQL Server, EF Core migrations, service clients, Authentik/Gravitee integration where feasible | Migration application, repository transaction behavior, service-to-service contract handling |
| Contract tests | Cross-domain API and event payload compatibility | Sales release payload consumed by Fulfilment, Purchasing PO payload consumed by Inventory |
| Smoke tests | Built services in local Kubernetes | `/healthz`, `/readyz`, `/openapi/v1.json`, domain and application placeholder routes |

## Required Business Coverage

Each domain must include tests for its controlling business rules. Each application must include tests for its orchestration and route-level behavior.

Sales:

- Required customer, channel, product, SKU where applicable, and quantity validation.
- Availability check behavior and release eligibility.
- Buyer request creation for non-routinely stocked products.
- Draft edits succeed with a current concurrency token; non-Draft edits are rejected without mutation.
- Submitted orders reject term mutations, and API contract tests verify their immutable state.

Purchasing:

- Required PO fields: supplier, item, SKU, barcode where available, quantity, unit cost, purchase date, expected arrival date.
- Draft edits and placement by an authorized Buyer.
- Ordered purchase orders reject term mutations, and API contract tests verify their immutable state.
- Only Received purchase orders may be closed.

Inventory Management:

- Stock checks preserve count-time recorded quantity, actual quantity, and variance without changing balances or creating stock movements.
- Goods receipt matching against Purchasing PO data.
- Prevention of unmatched receipts updating available stock.
- Negative inventory balance prevention.
- Exact reservation at fulfilment release and atomic consumption of those quantities at full fulfilment completion.

Order Fulfilment:

- Fulfilment starts only from Sales-released orders.
- Pick confirmation requires every released line in its exact quantity and all required serials; under-picks, over-picks, and mismatches leave the task in Picking with validation errors.
- Shipping purchase and label availability are required before completion.
- Completion consumes every exact reservation quantity, stores the Inventory and Sales integration results idempotently, and produces one terminal Completed task.
- Dependency, concurrency, and retry tests preserve the last committed valid state and never create an invalid lifecycle transition or duplicate external effect.

Cross-cutting:

- Required permissions and data scopes for read, create, Draft update, submission or placement, and each defined workflow transition.
- Service account scope and failed authorization behavior.

## Quality Gates

Minimum local gates before architecture or implementation work is considered ready:

```powershell
dotnet build .\Acme.Erp.slnx
.\build\scripts\validate-local.ps1
```

As test projects are added, the build gate must include:

```powershell
dotnet test .\Acme.Erp.slnx
```

CI should fail on build errors, test failures, analyzer warnings configured as errors, missing required contracts, and local deployment manifest validation failures.

## Analyzer and Formatting Conventions

- Use Microsoft-aligned .NET analyzers and ASP.NET Core analyzer defaults.
- Prefer explicit nullable annotations and avoid suppressions unless justified.
- Keep `.editorconfig` as the source of style truth when introduced.
- Do not disable analyzer rules globally to bypass local warnings; narrow suppressions require a reason.
- Keep generated code out of analyzer noise where generation tooling requires it.

## OpenAPI and Contract Quality

- Every API exposes OpenAPI 3.0 JSON.
- Cross-domain payloads document external ID ownership.
- Error responses distinguish validation, authorization, and business conflict responses.
- Contract tests guard cross-domain payloads used by Sales, Purchasing, Inventory Management, and Order Fulfilment.

## Test Data Rules

- Test data must use deterministic IDs where assertions depend on identity.
- Test data ownership follows domain ownership: Inventory product/SKU data, Sales customer data, Purchasing supplier data, and Authentik identity and role-claim data.
- Tests must not depend on the execution order of unrelated tests.
- Tests that mutate SQL Server state must isolate databases, schemas, transactions, or data identifiers.

## Review Checklist

- [ ] XUnit v3 is used for tests.
- [ ] Build uses .NET 10 and the latest C# language version.
- [ ] Nullable reference types and analyzers are enabled.
- [ ] Warnings-as-errors are used where feasible.
- [ ] Business rules have focused unit or slice tests.
- [ ] Cross-domain payloads have contract coverage.
- [ ] Local validation checks Kubernetes platform and application readiness.
- [ ] Smoke tests verify health, readiness, and OpenAPI endpoints.
