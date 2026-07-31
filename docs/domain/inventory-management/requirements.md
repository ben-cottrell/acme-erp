# Domain Requirements: Inventory Management

## 1. Purpose

The Inventory Management bounded context owns the durable stock system of record for MVP product, SKU, barcode, stocking and location configuration; recorded stock; stock states; availability; reservations; goods receipts; stock checks; and stock movements.

Inventory Management exposes WebAPI contracts, owns the Inventory database, and enforces inventory authorization, validation, persistence, non-negative stock, reservation, and consumption rules. Warehouse Operator workflows and all other user-facing presentation remain in application services.

## 2. Domain Scope

### In Scope

- Product, SKU, barcode, stocking, location, and serialization configuration required for MVP operations.
- Recorded quantity by SKU, location, and stock state.
- Available-to-promise calculation and stock reservation.
- Purchase-order-matched goods receipt booking, including partial receipts and non-available condition states.
- Stock check creation, actual quantity capture, variance calculation, and completion as an informational count record.
- Immutable stock movements for receipt booking, reservation state changes, consumption, and technical reservation compensation.
- Product, stock, receipt, stock-check, reservation, and movement query contracts.

### Out of Scope

- Razor Pages, scanner presentation, navigation, and user-facing workflow orchestration.
- Purchase order authoring, supplier ordering, and supplier reference ownership.
- Sales order authoring, customer accounts, pricing, payment, invoicing, and customer communication.
- Fulfilment task ownership, picking, packing, courier purchase, and label handling.
- Returns/RMA, accounting postings, landed cost, tax, lot and expiry tracking, and warehouse automation hardware.

## 3. Business Context

ACME requires one trustworthy inventory record for sales availability, purchase-order receiving, and fulfilment execution. Inventory Management must prevent negative stock, validate receipt quantities against ordered terms, exclude non-available stock from availability, and link every stock change to its source.

The MVP outcome is a simple flow in which Warehouse Operators book valid receipts and complete physical counts, Sales and Customer Ordering read availability, and Order Fulfilment reserves and consumes stock through authoritative contracts.

## 4. Stakeholders and Roles

| Role | Description | Responsibilities | Domain Permissions |
|---|---|---|---|
| Warehouse Operator | Internal user acting through Warehouse Operator. | Maintain permitted product/location data, book matched receipts, complete stock checks, and query warehouse records. | Product and location maintenance, receipt booking, stock-check capture, and permitted queries. |
| Buyer | Internal user acting through Buyer. | Use product references for purchase orders and monitor receipt progress through Purchasing. | Read product validation and receipt outcomes through authorized contracts. |
| Sales Assistant | Internal user acting through Sales Assistant. | Validate products, inspect availability, and release eligible orders. | Read product and availability data through Sales Assistant orchestration. |
| Authenticated Customer | Customer user acting through Customer Ordering. | View customer-permitted product availability. | Read availability shaped and scoped by Customer Ordering and Sales. |
| Fulfilment Operator | Internal user acting through Fulfilment Operator. | Pick reserved stock and complete fulfilment tasks. | Use reservation and consumption operations through Order Fulfilment. |
| Integration Service Account | Authenticated identity for domain-to-domain calls. | Exchange purchase order, availability, reservation, and consumption data. | Invoke only explicitly scoped Inventory operations. |

## 5. Domain Capabilities and Workflows

### 5.1 Product and Stocking Configuration

An authorized Warehouse Operator maintains unique products, SKUs, barcodes, locations, stocking flags, and serialization flags. Deactivation prevents new receipt, reservation, and consumption commands while existing records remain queryable.

### 5.2 Goods Receipt

Receipt booking starts with an Ordered or Partially Received Purchasing order reference. Inventory Management retrieves authoritative lines, validates item identity and remaining quantity, and books accepted quantities to Available, Quarantine, Damaged, or Non-Available stock. A partial quantity is valid. Unknown items and quantities above the remaining ordered amount are rejected without a receipt or stock change.

### 5.3 Stock Check

A Warehouse Operator opens a check for one SKU and location, records the actual physical quantity by stock state, and completes it. Inventory Management calculates and stores variance against the recorded quantity at count time. Completion does not change recorded stock.

### 5.4 Reservation and Consumption

Sales requests reservation during fulfilment release. A successful reservation reduces available-to-promise without reducing recorded stock. Order Fulfilment consumes the reserved quantity at completion, reducing recorded and reserved quantities atomically and creating immutable movements. A technical release may remove an unused reservation created during a failed release orchestration.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| INV-DOM-001 | Product configuration | The system shall maintain unique products, SKUs, barcodes, locations, stocked flags, active flags, and serialization flags required by MVP workflows. | Must | Given an authorized valid command, when configuration is saved, then current data shall be queryable; duplicate identifiers or invalid relationships shall be rejected. |
| INV-DOM-002 | Stock balance | The system shall maintain non-negative recorded, reserved, and available-to-promise quantities by SKU, location, and stock state. | Must | Given any stock mutation, when it commits, then every affected quantity shall satisfy its invariant in the same transaction. |
| INV-DOM-003 | Goods receipt | The system shall book a goods receipt only for known active items and quantities within the remaining amount on an eligible Purchasing order line. | Must | Given a matching line and valid quantity, when a Warehouse Operator books it, then one receipt and its stock movements shall commit; invalid input shall produce no receipt or stock change. |
| INV-DOM-004 | Receipt condition | The system shall place each received quantity into Available, Quarantine, Damaged, or Non-Available stock according to the submitted condition. | Must | Given a valid receipt line, when booked, then only Available quantity shall contribute to available-to-promise and all condition quantities shall remain queryable. |
| INV-DOM-005 | Stock check | The system shall record actual quantities and calculated variance for one SKU and location in a completed stock-check record without changing stock balances. | Must | Given an Open check, when valid actual quantities are submitted, then Inventory shall store the count-time recorded quantity, actual quantity, variance, actor, and completion time and shall leave stock unchanged. |
| INV-DOM-006 | Stock movements | The system shall append an immutable movement for every receipt, reservation state change, consumption, and technical reservation compensation. | Must | Given a successful mutation, when the transaction commits, then each movement shall identify source type, source external ID, quantity, stock state, actor or service, and UTC timestamp. |
| INV-DOM-007 | Availability | The system shall expose active stocked status and available-to-promise quantity without allowing query consumers to mutate inventory. | Must | Given an authorized product/SKU query, when Inventory responds, then it shall return current identifiers, active and stocked flags, and availability by permitted scope. |
| INV-DOM-008 | Reservation | The system shall reserve available stock idempotently for a valid Sales order and Order Fulfilment task context. | Must | Given sufficient available stock, when a valid reservation command is accepted, then reserved quantity shall increase and available-to-promise shall decrease by the same amount. |
| INV-DOM-009 | Consumption | The system shall consume only active reserved quantities supplied by Order Fulfilment at full task completion. | Must | Given valid reservation references and exact quantities, when consumption succeeds, then recorded and reserved quantities shall decrease atomically and movement references shall be returned. |
| INV-DOM-010 | Inventory queries | The system shall expose paginated, stably sorted searches for product configuration, balances, receipts, stock checks, reservations, and movements. | Must | Given authorized filters, when a query runs, then every result shall satisfy caller scope and requested filters. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| INV-BR-001 | Product codes, SKU codes, and barcodes shall be unique within Inventory Management. | Product configuration | Inventory validation and persistence | Inactive records retain their identifiers. |
| INV-BR-002 | New receipts, reservations, and consumption shall use active products, SKUs, and locations. | Stock mutation | Inventory validation | Existing records remain queryable after deactivation. |
| INV-BR-003 | Receipt quantity shall be positive and shall not exceed the remaining ordered quantity returned by Purchasing. | Goods receipt | Receipt workflow | Partial receipt is valid. |
| INV-BR-004 | Only Available stock shall contribute to available-to-promise. | Availability | Inventory calculation | Reserved, Quarantine, Damaged, and Non-Available quantities are excluded. |
| INV-BR-005 | Recorded and reserved quantities shall never be negative, and reserved quantity shall not exceed recorded Available stock. | Stock balance | Inventory transaction rules | Mutations fail atomically. |
| INV-BR-006 | Serialized products shall capture one unique serial number for each received and consumed unit. | Receipt and consumption | Inventory validation | Lot and expiry data are not used in MVP. |
| INV-BR-007 | A completed stock check shall preserve count-time recorded quantity, actual quantity, variance, actor, and timestamp and shall not mutate stock. | Stock check | Stock-check workflow | Variance is informational. |
| INV-BR-008 | Every stock change shall reference its source domain and external business ID. | Stock movement | Inventory persistence | Cross-domain database keys are prohibited. |
| INV-BR-009 | Reservation and consumption commands shall carry Sales order, Order Fulfilment task, and correlation identifiers. | Reservation and consumption | Integration validation | Missing ownership context is not inferred. |
| INV-BR-010 | A stale row version shall not overwrite newer mutable configuration or balance state. | Mutable records | Inventory persistence | Caller must refresh before retry. |

## 8. State Model

| Area | State | Allowed Transitions | Trigger / Guards |
|---|---|---|---|
| Goods Receipt | Draft | Booked | All lines match eligible Purchasing quantities and valid Inventory configuration. |
| Goods Receipt | Booked | None | Terminal; associated movements are immutable. |
| Stock Check | Open | Completed | Actual quantities are supplied for the selected SKU and location. |
| Stock Check | Completed | None | Terminal informational record. |
| Reservation | Reserved | Consumed, Released | Consumption requires exact active references; Released is limited to idempotent technical compensation. |
| Reservation | Consumed | None | Terminal. |
| Reservation | Released | None | Terminal. |
| Stock State | Available | Reserved, Consumed | Reservation changes availability; consumption changes recorded quantity. |
| Stock State | Quarantine | None | Non-available terminal state in MVP. |
| Stock State | Damaged | None | Non-available terminal state in MVP. |
| Stock State | Non-Available | None | Non-available terminal state in MVP. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Product/SKU/Barcode | Inventory Management | Yes | Unique bounded codes, active and stocked flags, serialization flag, and row version. | Consumed by Sales, Purchasing, and Order Fulfilment. |
| Location | Inventory Management | Yes | Unique code and active flag within the MVP logical warehouse. | Warehouse Operator input. |
| Stock Balance | Inventory Management | Yes | Non-negative recorded and reserved quantities by SKU, location, and stock state with row version. | No cross-database foreign keys. |
| Goods Receipt | Inventory Management | Conditional | Unique receipt number, PO reference, receipt date, actor, source, and immutable booked state. | Purchasing order and line external IDs. |
| Stock Check | Inventory Management | Conditional | SKU, location, count-time recorded quantity, actual quantity, variance, actor, and timestamps. | None. |
| Reservation | Inventory Management | Conditional | Positive quantity, state, idempotency key, correlation ID, and timestamps. | Sales order and fulfilment task external IDs. |
| Stock Movement | Inventory Management | Yes for mutations | Append-only type, quantity, state, source, actor/service, correlation ID, and timestamp. | Purchasing order, Sales order, fulfilment task, receipt, and reservation IDs. |
| Serial Record | Inventory Management | Conditional | Unique serial number and current SKU/location/state. | Receipt and fulfilment source IDs. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Failure Handling |
|---|---|---|---|---|---|---|
| INV-INT-001 | Inventory Management | Purchasing | Query | Purchase order number or ID and requested line IDs. | Receipt lookup and booking. | Timeout leaves receipt unbooked and returns a correlated retryable failure. |
| INV-INT-002 | Purchasing | Inventory Management | Response | Supplier, line IDs, product/SKU/barcode, ordered and received-to-date quantities, dates, and state. | Receipt validation. | Unknown, ineligible, or mismatched data is rejected without local mutation. |
| INV-INT-003 | Inventory Management | Purchasing | Update | Receipt ID, PO and line IDs, cumulative received quantities, receipt date, update ID, and correlation ID. | Successful receipt booking. | Bounded retry reuses the update ID; booked local state remains observable. |
| INV-INT-004 | Sales | Inventory Management | Query/command | Product validation, stocked status, availability, reservation request, Sales IDs, fulfilment context, and correlation ID. | Order submission and release. | Queries do not mutate; reservation is idempotent and fails atomically when stock is insufficient. |
| INV-INT-005 | Order Fulfilment | Inventory Management | Command/query | Product and serial validation, reservation lookup, consumption quantities, task ID, Sales order ID, and correlation ID. | Picking and completion. | Invalid references or quantities are rejected without partial stock change. |
| INV-INT-006 | Warehouse Operator API | Inventory Management | Command/query | Product/location maintenance, receipt, stock-check, and search requests. | User action. | Authorization, validation, concurrency, and dependency failures return deterministic responses without partial mutation. |

## 11. Search and Query Requirements

| Query / View | Audience | Purpose | Filters |
|---|---|---|---|
| Product and Barcode Search | Warehouse Operator, Buyer, Sales and Fulfilment integrations | Identify current product configuration. | Product code, SKU, barcode, active flag, stocked flag, serialization flag. |
| Stock Balance Search | Warehouse Operator and authorized domain integrations | Review recorded and available quantities. | SKU, barcode, location, stock state, availability. |
| Goods Receipt Records | Warehouse Operator and Buyer integration | Trace booked receipts. | Receipt number, PO number, supplier reference, SKU, receipt date range, stock state. |
| Completed Stock Checks | Warehouse Operator | Review completed counts and variance. | SKU, barcode, location, completion date range, actor. |
| Reservation Search | Fulfilment and Sales integrations | Trace reserved demand. | Reservation ID, Sales order ID, fulfilment task ID, state, created date range. |
| Stock Movement Ledger | Warehouse Operator and support users with permission | Trace stock changes. | SKU, location, movement type, source type, source ID, date range. |

## 12. Security and Authorization Controls

- Inventory Management shall require an authenticated user or scoped service identity for every non-health operation.
- It shall authorize product/location maintenance, receipt booking, stock-check capture, reservation, consumption, technical reservation compensation, and queries independently.
- Warehouse Operator access shall be limited to granted warehouse and location scope.
- Sales, Purchasing, and Order Fulfilment identities shall invoke only named contracts and shall supply required external ownership identifiers.
- Authorization shall fail closed and shall not disclose out-of-scope stock or source-document data.
- Serial numbers and supplier unit-cost context shall be returned only to workflows that require them.

## 13. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| INV-NFR-001 | Consistency | Each stock mutation and its movements shall commit atomically in one Inventory database transaction. |
| INV-NFR-002 | Reliability | Cross-service mutations shall use idempotency keys, correlation IDs, deterministic duplicate responses, and bounded retries for transient outbound failures. |
| INV-NFR-003 | Concurrency | Mutable configuration and balance writes shall use optimistic concurrency and atomic invariant checks. |
| INV-NFR-004 | Performance | Availability lookups and operational searches shall use indexed filters, bounded result sets, pagination where applicable, and stable sorting for MVP volume. |
| INV-NFR-005 | Observability | Structured logs, metrics, traces, health checks, and readiness checks shall expose operation, outcome, correlation ID, and dependency without logging full serial-number lists. |
| INV-NFR-006 | Contracts | The Inventory API shall publish OpenAPI 3.0 contracts documenting identity, external IDs, validation errors, authorization failures, conflicts, and retryable dependency failures. |
| INV-NFR-007 | Maintainability | Inventory Management shall not depend on application UI projects or application-owned persistence. |
| INV-NFR-008 | Localization | Quantities, UTC timestamps, and calendar dates shall follow shared data conventions; display formatting remains an application concern. |
| INV-NFR-009 | Testability | Automated tests shall cover receipt matching, partial receipts, condition states, stock-check variance, non-negative stock, serialization, reservation, consumption, idempotency, and authorization. |

## 14. Technical Failures and Edge Cases

- Duplicate receipt, reservation, consumption, compensation, and integration-update commands shall return the original outcome for the same idempotency identity.
- A stale row version shall return a conflict and preserve current state.
- Unknown product, SKU, barcode, location, purchase order, reservation, Sales order, or fulfilment task references shall be rejected without partial mutation.
- A Purchasing timeout shall leave the receipt unbooked.
- Failure to notify Purchasing after a committed receipt shall use the original update ID on bounded retry and shall not book stock again.
- A command that would produce negative stock, over-reservation, over-consumption, or over-receipt shall fail atomically.
- Out-of-order source updates shall be rejected or ignored idempotently using source update identity.

## 15. Dependencies

- Purchasing for authoritative ordered terms and receipt-progress consumption.
- Sales for availability queries, reservation commands, and Sales order references.
- Order Fulfilment for product and serial validation, reservation lookup, and consumption commands.
- Gravitee and Authentik for ingress, OAuth/OIDC identity, user claims, location scope, and service identities.
- Warehouse Operator for user-facing product, location, receipt, stock-check, and inventory-query workflows.

## 16. Assumptions

- Inventory Management owns MVP product, SKU, barcode, stocking, and location configuration until a dedicated product master exists.
- MVP uses one logical warehouse with simple location codes.
- Available, Reserved, Quarantine, Damaged, and Non-Available are the MVP stock states.
- Partial purchase order receipts are valid; quantities above the remaining ordered amount are rejected.
- Completed stock checks are informational and do not change stock.
- Reservations occur during Sales fulfilment release and consumption occurs at full Order Fulfilment completion.
- Automated reservation expiry is not used; technical release is limited to failed release orchestration.
- Lot and expiry tracking are not used in MVP.

## 17. Open Questions

None for the MVP Inventory Management workflow.

## 18. Acceptance Summary

The Inventory Management specification is complete when Warehouse Operator can maintain inventory references, book valid purchase-order receipts, complete informational stock checks, and query operational records; Sales and Customer Ordering can use current availability; Buyer can use product and receipt data; Order Fulfilment can reserve and consume exact quantities; and every stock mutation remains non-negative, atomic, idempotent, correlated, and traceable through Inventory-owned movements.
