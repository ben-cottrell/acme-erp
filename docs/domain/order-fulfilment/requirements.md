# Domain Requirements: Order Fulfilment

## 1. Purpose

The Order Fulfilment bounded context owns durable fulfilment task state, task lines, exact-quantity pick and pack progress, accepted courier shipment purchase records, label references, tracking references, and completion state.

Order Fulfilment exposes WebAPI contracts, owns the Fulfilment database, and enforces fulfilment authorization, validation, persistence, and state transitions. Fulfilment Operator screens and Sales visibility presentation remain application concerns.

## 2. Domain Scope

### In Scope

- Idempotent intake of Sales-released orders with Inventory reservation references.
- Fulfilment task creation, work assignment, exact-quantity picking, packing, courier shipment purchase, label reference capture, inventory consumption coordination, Sales status updates, and completion.
- Product, SKU, barcode, and serial validation through Inventory Management.
- Accepted courier transaction, shipment, tracking, service, and label references.
- Authorized task worklist, shipment reference, and completion queries.
- Ordinary validation, concurrency, dependency-failure, retry, and idempotency behavior.

### Out of Scope

- Razor Pages, scanner presentation, navigation, print dialogs, and user-facing workflow orchestration.
- Sales order creation, customer account ownership, pricing, payment, invoicing, customer communication, returns/RMA, and failed-delivery processing.
- Product master ownership, stock balances, stock checks, goods receipts, and stock mutation persistence.
- Purchase order authoring, supplier ordering, courier contract negotiation, rate shopping, refunds, and finance postings.

## 3. Business Context

ACME requires released sales demand to become controlled warehouse work without Sales or application services owning fulfilment state. Order Fulfilment must validate exact picks against released requirements, preserve accepted courier and label references, coordinate Inventory consumption, and provide Sales with current progress.

The MVP outcome is a straight-through fulfilment workflow in which a valid released order is picked in full, packed, assigned an accepted courier shipment and label, consumed from Inventory, reported to Sales, and completed.

## 4. Stakeholders and Roles

| Role | Description | Responsibilities | Domain Permissions |
|---|---|---|---|
| Fulfilment Operator | Internal user acting through Fulfilment Operator. | Select work, record exact picks and serials, confirm packing, purchase courier shipping, obtain labels, and complete tasks. | Claim permitted tasks and perform valid lifecycle actions for assigned work. |
| Sales Assistant | Internal user acting through Sales Assistant. | Monitor released order progress and shipment references. | Read copied progress through Sales and authorized fulfilment query contracts. |
| Authenticated Customer | Customer user acting through Customer Ordering. | View customer-permitted order and shipment status. | Read Sales-shaped status for the authenticated customer account; no direct Fulfilment mutation. |
| Integration Service Account | Authenticated Sales, Inventory Management, and courier identity. | Exchange release, validation, consumption, shipment, and status data. | Invoke only named integration operations with required external identifiers. |

## 5. Domain Capabilities and Workflows

### 5.1 Release Intake and Work Assignment

Sales sends a released order containing external order and line IDs, exact quantities, delivery context, channel, and Inventory reservation IDs. Order Fulfilment validates the contract and creates one Released task per release identity. A Fulfilment Operator may claim a permitted Released task and start Picking.

### 5.2 Exact Picking and Packing

The operator records product, SKU, barcode, quantity, and serials where required. Inventory Management validates current identifiers and serial data. Pick confirmation succeeds only when every released line is picked in the exact required quantity. Packing confirmation requires all picked lines and package data required by the courier request.

### 5.3 Courier, Label, and Completion

After packing, Order Fulfilment sends one idempotent shipment purchase request to the configured courier. Only an accepted provider response creates a shipment purchase record. A task progresses when shipment, tracking, and label references are stored. Completion consumes exact reserved quantities in Inventory Management and sends the resulting completion update to Sales. If a dependency is temporarily unavailable, the task remains at the last committed valid state or Completing while the same correlated operation is retried.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| FUL-DOM-001 | Release intake | The system shall create one Released fulfilment task only from a valid authenticated Sales release containing order, line, quantity, delivery, channel, and reservation data. | Must | Given a complete valid release, when Order Fulfilment accepts it, then one task shall be persisted; an idempotent replay shall return the original task. |
| FUL-DOM-002 | Work assignment | The system shall permit a Fulfilment Operator to claim a permitted unassigned Released task and start Picking. | Must | Given an unassigned permitted task and matching row version, when claim succeeds, then acting user and start time shall be stored; a competing stale claim shall fail. |
| FUL-DOM-003 | Pick capture | The system shall record picked product, SKU, barcode, quantity, location, and required serial numbers against released task lines. | Must | Given valid scan data for the assigned task, when it is recorded, then picked progress shall update; unknown, inactive, duplicate serial, or excess quantity input shall be rejected without changing progress. |
| FUL-DOM-004 | Pick confirmation | The system shall mark a task Picked only when every line exactly equals its released required quantity and required serials are valid. | Must | Given all lines match exactly, when confirmation is requested, then the task shall become Picked; otherwise it shall remain Picking with line-level validation errors. |
| FUL-DOM-005 | Packing | The system shall record package count, weight, dimensions, and packing confirmation for a Picked task. | Must | Given valid package data, when packing is confirmed, then the task shall become Packed; missing or non-positive required values shall be rejected. |
| FUL-DOM-006 | Courier shipment | The system shall purchase one shipment for a Packed task through the configured MVP courier and persist only an accepted transaction, service, tracking, and shipment reference. | Must | Given an accepted idempotent courier response, when stored, then the task shall become Shipping Purchased and replay shall return the same purchase record. |
| FUL-DOM-007 | Label reference | The system shall persist the provider label reference and mark the task Label Ready only when it belongs to the accepted shipment purchase. | Must | Given a valid label reference for the task shipment, when stored, then it shall be retrievable and the task shall become Label Ready. |
| FUL-DOM-008 | Completion | The system shall complete only a Label Ready task whose exact reservation quantities are consumed by Inventory Management and whose completion update is accepted by Sales. | Must | Given all guards pass, when completion runs, then Inventory movement IDs and the Sales update ID shall be stored and the task shall become Completed exactly once. |
| FUL-DOM-009 | Fulfilment queries | The system shall expose paginated, stably sorted queries for available work, assigned work, task details, shipment and label references, and completed tasks. | Must | Given authorized filters, when a query runs, then every result shall satisfy caller scope and requested filters. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| FUL-BR-001 | A fulfilment task shall originate from one Sales release and retain Sales order and line external IDs. | Release intake | Fulfilment validation | Domain database relationships do not cross services. |
| FUL-BR-002 | Released quantities shall be positive and shall have Inventory reservation references. | Task line | Release validation | Missing ownership data is not inferred. |
| FUL-BR-003 | Picked product, SKU, barcode, quantity, and serials shall match the released line exactly before pick confirmation. | Picking | Pick workflow | Excess and unknown input is rejected. |
| FUL-BR-004 | Only the assigned Fulfilment Operator shall mutate a task after claim. | Active task | Fulfilment authorization | Service identities remain limited to named integration operations. |
| FUL-BR-005 | Packing shall begin only after exact pick confirmation. | Packing | State transition | Package values required by courier contracts shall be positive. |
| FUL-BR-006 | Courier shipping shall be purchased before a label reference is accepted. | Shipping | Shipping workflow | The MVP uses one configured provider and service level. |
| FUL-BR-007 | Completion shall require Label Ready state, exact Inventory consumption, and accepted Sales update. | Completion | Completion workflow | Completing supports reliable retry after stock consumption. |
| FUL-BR-008 | Completed tasks, accepted shipment purchase records, and stored integration result IDs shall be immutable. | Completion and shipment records | Fulfilment persistence | Duplicate commands return the original result. |
| FUL-BR-009 | Stale row versions shall not overwrite current task progress. | Mutable task | Fulfilment persistence | Caller must refresh before retry. |

## 8. State Model

| State | Allowed Transitions | Trigger | Guards / Notes |
|---|---|---|---|
| Released | Picking | Operator claims and starts task | Task must be unassigned and within caller scope. |
| Picking | Picked | Exact pick confirmation | Every line and required serial shall match. |
| Picked | Packing | Operator starts packing | Pick data is fixed. |
| Packing | Packed | Valid packing confirmation | Required package data is present. |
| Packed | Shipping Purchased | Courier accepts idempotent purchase | Failed calls leave the state Packed. |
| Shipping Purchased | Label Ready | Valid provider label reference stored | Shipment and tracking references are present. |
| Label Ready | Completing | Completion command accepted | Exact Inventory consumption is initiated. |
| Completing | Completed | Inventory result and Sales update are durably stored | Retry reuses original correlation and update IDs. |
| Completed | None | Completion committed | Terminal state. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Fulfilment Task | Order Fulfilment | Yes | Unique task number, state, delivery context, channel, assignment, timestamps, correlation ID, and row version while mutable. | Sales order external ID. |
| Fulfilment Task Line | Order Fulfilment | Yes | Positive required quantity, picked quantity not above required, and fixed line identity after intake. | Sales line, Inventory product, SKU, barcode, and reservation external IDs. |
| Picked Serial | Order Fulfilment | Conditional | Unique within task and exact count for serialized lines. | Inventory serial external ID. |
| Package | Order Fulfilment | Conditional | Positive package count, weight, and required dimensions. | Task ID. |
| Shipment Purchase Record | Order Fulfilment | Conditional | Accepted provider transaction, service, tracking, amount/currency when returned, request identity, and timestamp. | Courier transaction external ID. |
| Label Reference | Order Fulfilment | Conditional | Provider label ID or retrievable reference tied to one shipment purchase. | Courier label external ID. |
| Completion Result | Order Fulfilment | Conditional | Inventory movement IDs, Sales update ID, correlation ID, and completion timestamp. | Inventory movement and Sales update external IDs. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Failure Handling |
|---|---|---|---|---|---|---|
| FUL-INT-001 | Sales | Order Fulfilment | Command | Sales order and line IDs, exact quantities, delivery context, channel, reservation IDs, source, idempotency key, and correlation ID. | Fulfilment release. | Incomplete or ineligible release is rejected without task creation; duplicate identity returns original task. |
| FUL-INT-002 | Order Fulfilment | Inventory Management | Query | Product, SKU, barcode, serial, location, reservation, task, and Sales order IDs. | Pick capture and confirmation. | Unavailable validation leaves task progress unchanged and returns a correlated retryable failure. |
| FUL-INT-003 | Order Fulfilment | Courier Service | Request/response | Delivery context, package data, configured service, request identity, transaction, shipment, tracking, and label data. | Shipping purchase and label retrieval. | Bounded retry uses the same provider idempotency identity; no accepted local record is duplicated. |
| FUL-INT-004 | Order Fulfilment | Inventory Management | Command | Task, Sales order, reservation IDs, exact quantities, idempotency key, and correlation ID. | Completion. | Duplicate calls return original movement IDs; failure leaves the task Label Ready or Completing according to committed progress. |
| FUL-INT-005 | Order Fulfilment | Sales | Update | Task and order IDs, Completed state, shipment and tracking references, update ID, and completion timestamp. | Completion. | Bounded retry reuses the update ID; Completing remains observable until Sales accepts it. |
| FUL-INT-006 | Fulfilment Operator API | Order Fulfilment | Command/query | Claim, pick, pack, ship, label, complete, and search requests. | User action. | Authorization, validation, concurrency, and dependency failures return deterministic responses without invalid lifecycle changes. |

## 11. Worklist and Query Requirements

| Query / View | Audience | Purpose | Filters |
|---|---|---|---|
| Available Task Worklist | Fulfilment Operator | Select unassigned released work. | Released date, channel, SKU, task number. |
| Assigned Work | Fulfilment Operator | Continue the user's current tasks. | State, assigned user, updated date range, task number. |
| Task Detail | Fulfilment Operator and Sales integration | View required lines and current progress. | Task ID or Sales order ID. |
| Shipment and Label References | Fulfilment Operator and Sales Assistant integration | Retrieve accepted shipping evidence. | Task number, Sales order, tracking reference, shipment date range. |
| Completed Task Search | Fulfilment Operator and Sales integration | Trace completed work. | Completion date range, task number, Sales order, SKU, tracking reference. |

## 12. Security and Authorization Controls

- Order Fulfilment shall require an authenticated user or scoped service identity for every non-health operation.
- It shall authorize release intake, task claim, pick capture, pick confirmation, packing, courier purchase, label storage, completion, integration update, and query operations independently.
- A Fulfilment Operator shall access only tasks within granted warehouse scope and shall mutate only tasks assigned to that identity after claim.
- Sales and Inventory Management identities shall invoke only their named contracts and shall supply required external IDs.
- Courier credentials and provider payload details shall be protected and shall not be returned to unauthorized callers.
- Authorization shall fail closed and shall not reveal out-of-scope task, customer delivery, serial, or shipment data.

## 13. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| FUL-NFR-001 | Consistency | Each local task transition and associated records shall commit in one Fulfilment database transaction. |
| FUL-NFR-002 | Reliability | Release, courier, consumption, and Sales update mutations shall use idempotency keys, correlation IDs, deterministic duplicate responses, and bounded retry for transient failures. |
| FUL-NFR-003 | Concurrency | Task assignment and progress writes shall use optimistic concurrency. |
| FUL-NFR-004 | Performance | Worklist and operational queries shall use indexed filters, bounded page sizes, pagination, and stable sorting suitable for MVP volume. |
| FUL-NFR-005 | Observability | Structured logs, metrics, traces, health checks, and readiness checks shall include operation, task ID, outcome, correlation ID, and dependency without logging full delivery addresses or courier credentials. |
| FUL-NFR-006 | Contracts | The Fulfilment API shall publish OpenAPI 3.0 contracts documenting identity, external IDs, validation errors, authorization failures, conflicts, and retryable dependency failures. |
| FUL-NFR-007 | Maintainability | Order Fulfilment shall not depend on application UI projects or application-owned persistence. |
| FUL-NFR-008 | Localization | Weights, dimensions, money returned by the courier, UTC timestamps, and calendar dates shall follow shared data conventions; formatting remains an application concern. |
| FUL-NFR-009 | Testability | Automated tests shall cover intake idempotency, assignment concurrency, exact picks, serialization, packing data, courier idempotency, label guards, completion coordination, authorization, and retries. |

## 14. Technical Failures and Edge Cases

- Duplicate release, courier purchase, label, consumption, Sales update, and completion commands shall return the original outcome for the same idempotency identity.
- A stale row version or competing task claim shall return a conflict and preserve current task state.
- Unknown or inactive product, SKU, barcode, serial, location, reservation, task, or Sales order references shall be rejected without invalid progress.
- An excess, duplicate, or wrong-item scan shall return a line-level validation error and leave recorded progress unchanged for that command.
- A courier timeout shall leave the task Packed unless an accepted provider result is recovered with the same request identity.
- An Inventory failure before consumption shall leave the task Label Ready; a response-loss after consumption shall be resolved by idempotent replay.
- A Sales outage after Inventory consumption shall leave the task Completing and retry the same update until Sales returns its deterministic result.

## 15. Dependencies

- Sales for released order contracts and accepted completion visibility.
- Inventory Management for product, SKU, barcode, serial, location, reservation, and consumption validation.
- The configured courier service for accepted shipment purchase, tracking, and label references.
- Gravitee and Authentik for ingress, OAuth/OIDC identity, user claims, warehouse scope, and service identities.
- Fulfilment Operator for user-facing worklist, pick, pack, ship, label, and completion workflows.
- Sales Assistant and Customer Ordering for user-facing progress through Sales-owned visibility.

## 16. Assumptions

- Royal Mail is the configured MVP courier provider.
- MVP uses one courier service level and does not perform rate shopping.
- Every released task is fulfilled in its exact released quantity.
- Inventory is reserved during Sales release and consumed during Order Fulfilment completion.
- Browser/PDF label rendering and printing are application concerns; the domain owns the retrievable provider reference.
- Accepted shipment, label, and completion records are immutable operational evidence.
- Worklists sort by state age and task number by default.

## 17. Open Questions

None for the MVP Order Fulfilment workflow.

## 18. Acceptance Summary

The Order Fulfilment specification is complete when Fulfilment Operator can claim Sales-released work, pick exact valid quantities and serials, pack, purchase one courier shipment, retrieve its label, consume Inventory reservations, notify Sales, and complete the task while all state, references, authorization, idempotency, correlation, concurrency, and domain boundaries remain enforceable and testable.
