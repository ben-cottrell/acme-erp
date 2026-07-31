# Domain Requirements: Sales

## 1. Purpose

The Sales bounded context owns the durable business record for MVP customer account reference data, sales orders, sales order lines, order channels, buyer request origination, release-to-fulfilment decisions, and copied fulfilment visibility.

Sales provides the authoritative demand record for internal sales-assisted ordering and authenticated customer ordering. It exposes WebAPI contracts, owns the Sales database, and enforces sales authorization, validation, persistence, and state transitions. User-facing workflows remain in the Sales Assistant and Customer Ordering applications.

## 2. Domain Scope

### In Scope

- MVP customer account reference data required for B2B order capture and customer-scoped queries.
- Sales order creation, draft editing, submission, confirmation, inventory waiting, buyer request waiting, fulfilment release, fulfilment progress visibility, and completion.
- Originating channel recording for Sales Assistant and Customer Ordering.
- Buyer request origination for non-routinely stocked products and copied Purchasing status visibility.
- Product validation and availability requests to Inventory Management.
- Release contracts to Order Fulfilment and copied task, shipment, tracking, and completion visibility.
- Authorized operational searches and customer-scoped order status queries.

### Out of Scope

- Razor Pages, navigation, form presentation, and user-facing workflow orchestration.
- Physical picking, packing, shipping purchase, label handling, and warehouse task execution.
- Purchase order authoring, supplier reference ownership, and goods receipt booking.
- Product master ownership, inventory balances, stock checks, and stock movements.
- Pricing, promotions, tax, payment capture, invoicing, credit control, returns/RMA, finance postings, and guest checkout.

## 3. Business Context

ACME requires one consistent sales order record across assisted and customer-originated ordering. Sales coordinates current product and availability information from Inventory Management, creates buyer requests in Purchasing for non-routinely stocked products, and releases eligible demand to Order Fulfilment without transferring ownership of sales state.

The MVP outcome is a traceable order flow from capture through completion, with clear waiting states when inventory or purchasing activity is required and no durable sales state in application services.

## 4. Stakeholders and Roles

| Role | Description | Responsibilities | Domain Permissions |
|---|---|---|---|
| Sales Assistant | Internal user who captures and monitors customer orders through Sales Assistant. | Create orders, edit drafts, submit orders, inspect availability, initiate buyer requests, and release eligible orders. | Create and edit drafts, submit orders, request release, and query permitted customer orders. |
| Authenticated Customer | Customer user ordering through Customer Ordering. | Create, edit, and submit orders for the linked customer account and view their status. | Create and edit own drafts, submit own orders, and query orders for the authenticated customer account only. |
| Buyer | Purchasing user acting through Buyer. | Source non-routinely stocked lines and link buyer requests to purchase orders. | Read the minimum Sales request context exposed through integration contracts; Purchasing owns all buyer actions. |
| Fulfilment Operator | Warehouse user acting through Fulfilment Operator. | Execute released work and progress it to completion. | Read released order data and return task progress through Order Fulfilment contracts. |
| Integration Service Account | Authenticated service identity for cross-domain calls. | Exchange validated commands and status updates. | Invoke only explicitly scoped Sales integration operations. |

## 5. Domain Capabilities and Workflows

### 5.1 Order Capture and Submission

The workflow starts when Sales Assistant or Customer Ordering sends an authorized create command. Sales creates a Draft order, permits draft-line edits, and validates required customer, channel, address, product, and quantity data on submission. A valid submission becomes Confirmed, Pending Inventory, or Pending Buyer Request. Invalid input returns deterministic errors and leaves the current durable state unchanged.

### 5.2 Inventory and Buyer Request Coordination

Sales validates stocked lines and current availability through Inventory Management. A confirmed order with insufficient availability becomes Pending Inventory. A non-routinely stocked line causes Sales to create one buyer request with a stable external identifier and send it to Purchasing. Copied buyer request status is limited to Open, Linked, and Satisfied.

### 5.3 Fulfilment Release and Completion Visibility

Sales rechecks product activity and availability before release. For an eligible order, Sales requests an Inventory reservation and sends the release contract to Order Fulfilment using one correlation identifier. Sales records Released to Fulfilment only after both domains accept their changes. Order Fulfilment progress updates move the copied Sales view through In Fulfilment to Completed.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| SAL-DOM-001 | Customer reference | The system shall maintain the active customer account reference, permitted customer identities, default contact, billing address, and shipping address required for MVP ordering. | Must | Given an authenticated actor and an active permitted account, when customer reference data is requested, then Sales shall return only data within that actor's scope. |
| SAL-DOM-002 | Order creation | The system shall create a Draft sales order from an authorized application command containing a customer account and originating channel. | Must | Given an authorized complete create command, when Sales accepts it, then one Draft order with a unique order number shall be persisted; an idempotent replay shall return the same order. |
| SAL-DOM-003 | Draft editing | The system shall permit authorized actors to add, update, or remove lines only while an order is Draft. | Must | Given a Draft order and matching concurrency token, when a permitted edit is submitted, then Sales shall persist the edit; given a non-Draft order or stale token, Sales shall reject the edit without changing the order. |
| SAL-DOM-004 | Order submission | The system shall validate all required order data and determine the next valid state when a Draft order is submitted. | Must | Given valid customer, channel, address, and line data, when the order is submitted, then it shall become Confirmed, Pending Inventory, or Pending Buyer Request according to current product and availability responses. |
| SAL-DOM-005 | Product and availability validation | The system shall query Inventory Management for active product, SKU, stocked status, and current availability during submission and immediately before release. | Must | Given an unknown or inactive stocked SKU, when validation runs, then Sales shall return a line-level validation error; given insufficient stock, then the order shall become Pending Inventory. |
| SAL-DOM-006 | Buyer request origination | The system shall create one buyer request for each submitted non-routinely stocked line and maintain copied Open, Linked, or Satisfied status from Purchasing. | Must | Given a non-routinely stocked line, when submission succeeds, then Sales shall persist a request linked to the order line and send its external ID to Purchasing exactly once for the idempotency key. |
| SAL-DOM-007 | Fulfilment release | The system shall release a Confirmed order only after current product validation succeeds, sufficient stock is reserved, and all buyer requests are Satisfied. | Must | Given all release guards pass, when release is requested, then Inventory and Order Fulfilment shall receive correlated commands and Sales shall become Released to Fulfilment only after both calls succeed. |
| SAL-DOM-008 | Fulfilment visibility | The system shall consume valid task progress, shipment reference, tracking reference, and completion updates from Order Fulfilment without modifying fulfilment-owned records. | Must | Given a valid update for a known released order, when Sales accepts it, then copied fulfilment data and the Sales status shall be updated idempotently. |
| SAL-DOM-009 | Sales queries | The system shall expose paginated, stably sorted queries for permitted operational order search, buyer request status, fulfilment visibility, and customer order status. | Must | Given authorized filters, when a query is executed, then every result shall satisfy the caller's data scope and the requested filters. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| SAL-BR-001 | Every order shall identify one active Sales-owned customer account and one supported originating channel. | Sales order | Sales command validation | Supported channels are Sales Assistant and Customer Ordering. |
| SAL-BR-002 | Submission requires a contact, billing address, shipping address, and at least one order line. | Sales order | Sales submission workflow | Missing values return field-addressable errors. |
| SAL-BR-003 | Every order-line quantity shall be numeric and greater than zero. | Sales order line | Sales command validation | Unit-of-measure compatibility comes from Inventory Management. |
| SAL-BR-004 | A stocked line shall reference an active Inventory product and SKU. | Stocked order line | Sales and Inventory integration | Sales stores external identifiers only. |
| SAL-BR-005 | A non-routinely stocked line shall have a Satisfied buyer request before fulfilment release. | Buyer-request line | Sales release workflow | Purchasing owns the linked purchase order. |
| SAL-BR-006 | Sales shall record Released to Fulfilment only after Inventory reserves stock and Order Fulfilment accepts the release. | Sales order | Sales release workflow | All calls use a shared correlation identifier. |
| SAL-BR-007 | An Authenticated Customer shall access only orders linked to the customer account resolved from verified identity claims. | Customer order | Sales authorization | Missing or ambiguous account scope fails closed. |
| SAL-BR-008 | A command with a stale row version shall not overwrite a newer order version. | Mutable sales order | Sales persistence | The response identifies a concurrency conflict. |

## 8. State Model

### 8.1 Sales Order

| State | Allowed Transitions | Trigger | Guards / Notes |
|---|---|---|---|
| Draft | Confirmed, Pending Inventory, Pending Buyer Request | Submit valid draft | Draft is the only editable order state. |
| Pending Inventory | Confirmed | Successful availability recheck | The order remains queryable while waiting. |
| Pending Buyer Request | Confirmed, Pending Inventory | All buyer requests become Satisfied | Availability determines the resulting state. |
| Confirmed | Pending Inventory, Released to Fulfilment | Availability change or release | Release guards in SAL-BR-005 and SAL-BR-006 apply. |
| Released to Fulfilment | In Fulfilment, Completed | Valid Order Fulfilment update | Sales stores copied progress only. |
| In Fulfilment | Completed | Valid completion update | Shipment and tracking references may be populated. |
| Completed | None | Full fulfilment accepted | Terminal state. |

### 8.2 Buyer Request

| State | Allowed Transitions | Trigger | Guards / Notes |
|---|---|---|---|
| Open | Linked | Purchasing links a purchase order | Sales stores the Purchasing external reference. |
| Linked | Satisfied | Purchasing reports sourcing complete | The related order is reevaluated for availability. |
| Satisfied | None | Sourcing complete | Terminal state. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Customer Account Reference | Sales | Yes | Unique account code, active flag, permitted identity mapping, contact, billing address, and shipping address. | Authentik subject or verified customer claim. |
| Sales Order | Sales | Yes | Unique order number, customer ID, channel, state, UTC timestamps, actor context, and row version. | Application request and correlation IDs. |
| Sales Order Line | Sales | Yes | Positive quantity and either Inventory product/SKU IDs or non-routinely stocked item details. | Inventory product and SKU external IDs. |
| Buyer Request | Sales | Conditional | Unique request ID, source line ID, requested description, quantity, and copied status. | Purchasing buyer request and purchase order external IDs. |
| Fulfilment Visibility | Sales copy | Conditional | Task state, shipment reference, tracking reference, completed timestamp, source, and last update ID. | Order Fulfilment task external ID. |
| Availability Result | Inventory Management | Conditional | Used transiently for submission and release guards. | Inventory product, SKU, and reservation external IDs. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Failure Handling |
|---|---|---|---|---|---|---|
| SAL-INT-001 | Sales | Inventory Management | Request/response | Product ID, SKU ID, stocked status, requested quantity, and availability. | Submission and release. | Timeout or unavailable response leaves the order unchanged and returns a retryable service failure with correlation ID. |
| SAL-INT-002 | Sales | Purchasing | Command | Sales buyer request ID, order and line IDs, item details, quantity, and correlation ID. | Non-routinely stocked line submission. | Idempotent retry uses the original request ID and key; exhausted retries remain observable to support staff. |
| SAL-INT-003 | Purchasing | Sales | Update | Buyer request ID, Open/Linked/Satisfied status, purchase order reference, update ID, and timestamp. | Purchasing status change. | Unknown IDs or invalid transitions are rejected without changing Sales state. |
| SAL-INT-004 | Sales | Inventory Management | Command | Order ID, line IDs, quantities, and correlation ID. | Fulfilment release. | Duplicate commands return the original reservation result; failure prevents Sales release. |
| SAL-INT-005 | Sales | Order Fulfilment | Command | Order ID, customer delivery context, channel, lines, quantities, reservation IDs, and correlation ID. | Fulfilment release. | Duplicate commands return the original task; failure prevents Sales release and triggers technical reservation compensation. |
| SAL-INT-006 | Order Fulfilment | Sales | Update | Task ID, order ID, task progress, shipment reference, tracking reference, update ID, and timestamp. | Task progression. | Updates are idempotent by source and update ID; invalid transitions return a conflict response. |
| SAL-INT-007 | Sales Assistant or Customer Ordering API | Sales | Command/query | Order commands and data-scoped query filters. | User action. | Authorization, validation, concurrency, and dependency failures are returned without partial local changes. |

## 11. Search and Query Requirements

| Query / View | Audience | Purpose | Filters |
|---|---|---|---|
| Sales Order Search | Sales Assistant | Find and monitor permitted orders. | Order number, customer, channel, SKU, state, created date range, buyer request state, fulfilment state. |
| Customer Order Status | Authenticated Customer | View current state for the linked customer account. | Order number, state, created date range. |
| Buyer Request Worklist Data | Sales Assistant and Buyer integration | Track sourcing progress. | Request state, order number, item description, created date range. |
| Fulfilment Visibility | Sales Assistant | Track released work and shipment references. | Order number, task state, shipment reference, tracking reference, updated date range. |

## 12. Security and Authorization Controls

- Sales shall require an authenticated user or scoped service identity for every non-health operation.
- Sales shall authorize create, draft edit, submit, release, customer-reference maintenance, integration update, and query actions independently.
- Customer commands and queries shall be constrained to the customer account resolved from verified Authentik claims.
- Sales Assistant access shall be limited to the customer and order scope granted by mapped claims.
- Service identities shall be permitted only for named integration contracts and shall not receive interactive-user permissions.
- Authorization shall fail closed and shall not disclose whether an out-of-scope order exists.
- Sensitive customer contact and address data shall be returned only when required by the permitted workflow.

## 13. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| SAL-NFR-001 | Consistency | Sales shall commit each local aggregate change in one Sales database transaction. |
| SAL-NFR-002 | Reliability | Cross-service mutations shall use idempotency keys, correlation IDs, bounded retries for transient failures, and deterministic duplicate responses. |
| SAL-NFR-003 | Performance | Operational queries shall support pagination, bounded page sizes, indexed filters, and stable sorting suitable for the expected MVP data volume. |
| SAL-NFR-004 | Concurrency | Mutable order writes shall use optimistic concurrency and shall not silently overwrite newer state. |
| SAL-NFR-005 | Observability | Structured logs, metrics, traces, health checks, and readiness checks shall include service, operation, correlation ID, outcome, and dependency name without logging sensitive address data. |
| SAL-NFR-006 | Contracts | The Sales API shall publish OpenAPI 3.0 contracts documenting identity requirements, external ID ownership, validation errors, authorization failures, conflicts, and retryable dependency failures. |
| SAL-NFR-007 | Maintainability | Sales shall have no dependency on application UI projects or application-owned persistence. |
| SAL-NFR-008 | Localization | Persisted business dates shall use UTC instants or explicit calendar dates; customer-facing formatting remains an application concern. |
| SAL-NFR-009 | Testability | Automated tests shall cover required fields, customer scope, availability outcomes, buyer request transitions, release guards, idempotency, and fulfilment updates. |

## 14. Technical Failures and Edge Cases

- Duplicate create, buyer request, reservation, release, and status-update calls shall return the original outcome when their idempotency identity matches.
- A stale row version shall return a conflict response and preserve the current order.
- An unavailable dependency shall leave Sales state at the last committed state and return a correlated retryable failure.
- An invalid external ID, payload, source identity, or state transition shall be rejected without partial mutation.
- If Inventory reservation succeeds but Order Fulfilment intake fails, Sales shall request idempotent reservation compensation and shall not mark the order released.
- Out-of-order fulfilment updates shall be rejected or ignored idempotently according to source update sequence.

## 15. Dependencies

- Inventory Management for product, SKU, stocked status, availability, reservation, and technical reservation compensation.
- Purchasing for buyer request intake, purchase order linkage, and sourcing completion status.
- Order Fulfilment for release acceptance, task progress, shipment references, tracking references, and completion.
- Gravitee and Authentik for ingress, OAuth/OIDC identity, customer claims, user claims, and service identities.
- Sales Assistant and Customer Ordering application APIs for user-facing workflow orchestration.

## 16. Assumptions

- Sales owns MVP customer account reference data until a dedicated customer master exists.
- Customer Ordering requires authentication; guest checkout and anonymous tracking are not included.
- Sales Assistant and Customer Ordering are the only originating sales channels in the MVP.
- Inventory reservation occurs during fulfilment release and consumption occurs during fulfilment completion.
- Buyer requests use the simple Open, Linked, and Satisfied lifecycle.
- Customer-visible wording and formatting are shaped by Customer Ordering from Sales-owned state.
- One configured company currency is used where applications display monetary context; Sales does not calculate prices in this MVP.

## 17. Open Questions

None for the MVP Sales workflow.

## 18. Acceptance Summary

The Sales specification is complete when Sales owns customer references and sales order state; Sales Assistant and Customer Ordering can create and submit scoped orders; non-routinely stocked lines integrate with Buyer through Purchasing; stocked lines use Inventory validation and reservation; eligible orders release to Order Fulfilment; copied completion visibility is queryable; and all mutations preserve domain ownership, authorization, idempotency, correlation, and transaction boundaries.