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
| Unit tests | Domain rules and application workflow decisions without infrastructure | Sales release criteria, PO approval threshold evaluation, inventory negative-balance prevention, fulfilment completion rules |
| Vertical slice tests | Feature command/query behavior with realistic dependencies substituted or in-memory where appropriate | Goods receipt mismatch handling, buyer request intake, sales order validation |
| API tests | Controller routing, authorization, validation, error responses, OpenAPI behavior | Required field validation, forbidden self-approval, idempotency replay |
| Integration tests | SQL Server, EF Core migrations, service clients, Authentik/Gravitee integration where feasible | Migration application, repository transaction behavior, service-to-service contract handling |
| Contract tests | Cross-domain API and event payload compatibility | Sales release payload consumed by Fulfilment, Purchasing PO payload consumed by Inventory |
| Smoke tests | Built services in local Kubernetes | `/healthz`, `/readyz`, `/openapi/v1.json`, domain and application placeholder routes |

## Required Business Coverage

Each domain must include tests for its controlling business rules. Each application must include tests for its orchestration and route-level behavior.

Sales:

- Required customer, channel, product, SKU where applicable, and quantity validation.
- Availability check behavior and release eligibility.
- Buyer request creation for non-routinely stocked products.
- Idempotent website order submission.
- Sales Supervisor approval for controlled amendments and cancellations.

Purchasing:

- Required PO fields: supplier, item, SKU, barcode where available, quantity, unit cost, purchase date, expected arrival date.
- Purchase orders over 10,000 require Purchasing Manager approval.
- Buyers cannot approve their own purchase orders.
- Post-submission amendments require business reason and approval where configured.

Inventory Management:

- Stock count variance calculation and discrepancy review.
- Goods receipt matching against Purchasing PO data.
- Prevention of unmatched receipts updating available stock.
- Negative inventory balance prevention.
- Reservation at fulfilment release and consumption at fulfilment completion.

Order Fulfilment:

- Fulfilment starts only from Sales-released orders.
- Picked components validate against sales order requirements.
- Shipping purchase and label availability are required before completion unless approved exception exists.
- Partial fulfilment reports remaining quantities to Sales as backordered.
- Inventory consumption failure creates a visible exception.

Cross-cutting:

- Authorization categories for read, create, update, approve, cancel, and workflow-owned export.
- Local self-approval prevention.
- Operational history records for controlled actions.
- Service account scope and failed authorization behavior.
- Correlation ID and idempotency behavior for cross-domain and application-to-domain mutations.

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
- Mutating endpoints document idempotency key behavior.
- Cross-domain payloads document external ID ownership.
- Error responses distinguish validation, authorization, conflict, retryable integration failure, and unrecoverable failure.
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
