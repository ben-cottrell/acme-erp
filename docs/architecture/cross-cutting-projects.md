# Cross-Cutting Projects

## Status

This document defines when shared projects are allowed and which cross-cutting concerns should be centralized across domains and applications.

## Core Rule

Create shared projects only for concerns that affect multiple APIs or services and have stable, domain-neutral or application-neutral behavior. Do not create shared projects for domain-specific business rules.

## Allowed Shared Concern Areas

| Concern | Purpose | Candidate project name | Consumers |
|---|---|---|---|
| API conventions | Common problem details, correlation headers, OpenAPI filters, idempotency headers | `Acme.Erp.ApiConventions` | API services |
| Security integration | Authentik/OIDC claim mapping helpers, authorization policy primitives, service account authentication support | `Acme.Erp.Security` | API and UI services |
| Audit contracts | Shared audit event envelopes, retention categories, actor/source metadata | `Acme.Erp.Audit` | API services and any audit reporting service |
| Observability | Logging enrichment, correlation propagation, tracing conventions, health check helpers | `Acme.Erp.Observability` | API and UI services |
| Integration contracts | Shared envelope types for correlation, idempotency, external IDs, and contract metadata | `Acme.Erp.Integration` | API services |
| Testing support | XUnit v3 fixtures, deterministic ID helpers, local test host helpers, contract test utilities | `Acme.Erp.Testing` | Test projects |

Project names may be adjusted during implementation, but the boundary rule remains: shared code is cross-cutting, stable, and not owned by one business domain or application.

## Prohibited Shared Code

Do not place these in shared projects:

- Sales order creation or release rules.
- Purchasing approval workflow or PO amendment rules.
- Inventory stock movement, availability, reservation, or goods receipt rules.
- Fulfilment picking, packing, shipping, completion, or partial fulfilment rules.
- Domain-owned EF Core entities or `DbContext` types.
- Domain-specific API request/response contracts unless they are explicit published integration contracts.
- Product, customer, supplier, or courier business rules owned by one domain.

## Shared Contract Rules

Shared integration contracts must be explicit about ownership.

Each contract includes:

- Source service.
- Target service or event audience.
- Correlation ID.
- Idempotency key for retryable mutations.
- External record IDs and owning domain.
- Schema version.
- Timestamp.
- Actor identity or service account identity.
- Failure and retry semantics where applicable.

## Security and Authorization

Security shared code may provide policy primitives and claim mapping helpers, but domain APIs remain responsible for final authorization decisions.

Central shared code may define:

- Permission category constants for read, create, update, approve, cancel, export, configure, and administer.
- Claim names and mapping conventions from Authentik tokens.
- Service account authentication helpers.
- Common authorization failure response shape.

Domain APIs define:

- Which permissions are required for each business action.
- Data-scope checks.
- Segregation-of-duties checks.
- Approval threshold evaluation.
- Audit decisions for local business records.

## Audit and Observability

Shared audit and observability code should standardize event envelopes, log enrichment, correlation propagation, and health check patterns.

Domain APIs own the business meaning of audit events. For example, `PurchaseOrderApproved`, `InventoryAdjustmentPosted`, and `FulfilmentCompleted` are domain-owned events even when they use a shared audit envelope.

## Shared Project Placement

Recommended placement when shared projects are introduced:

```text
src/Shared/
  Acme.Erp.ApiConventions/
  Acme.Erp.Security/
  Acme.Erp.Audit/
  Acme.Erp.Observability/
  Acme.Erp.Integration/
tests/Shared/
  Acme.Erp.Testing/
```

Do not create the full set preemptively. Add a shared project only when at least two services need it or when a platform integration requires one common implementation.

## Versioning and Change Control

- Shared projects must avoid breaking consumers without coordinated updates.
- Published integration contracts use schema versions.
- Cross-cutting changes that affect security, audit, ingress, or identity require architecture review.
- Shared projects should remain small enough that domain and application teams can understand their dependency impact.

## Review Checklist

- [ ] Shared code is used by multiple services or tests.
- [ ] Domain-specific behavior remains inside the owning domain.
- [ ] Shared security code does not bypass domain authorization decisions.
- [ ] Shared audit code standardizes shape without owning domain semantics.
- [ ] Integration contracts clearly name external IDs and owning domains.
- [ ] Shared project additions are justified by real duplication or platform consistency needs.
