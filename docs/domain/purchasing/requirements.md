# Domain Requirements: Purchasing

## 1. Purpose

The Purchasing bounded context owns durable MVP supplier reference data, purchase orders, purchase order lines, buyer request work state, and copied receipt visibility.

Purchasing exposes WebAPI contracts, owns the Purchasing database, and is authoritative for purchasing validation, authorization, persistence, and state transitions. Buyer workbench and Warehouse Operator presentation remain application concerns.

## 2. Domain Scope

### In Scope

- Supplier reference data for the active MVP supplier set.
- Purchase order draft creation, draft editing, placement with a supplier, receipt progress visibility, and closure.
- Sales-originated buyer request intake, purchase order linkage, and sourcing completion.
- Purchase order lookup contracts used by Inventory Management for goods receipt validation.
- Copied received quantities and receipt status from Inventory Management.
- Authorized purchase order, expected arrival, supplier, buyer request, and receipt searches.

### Out of Scope

- Razor Pages, navigation, workbench presentation, and user-facing orchestration.
- Goods receipt booking, stock balance mutation, stock movements, and physical warehouse work.
- Sales order capture, customer communication, fulfilment execution, courier operations, and label handling.
- Supplier onboarding, contracts, tendering, supplier scorecards, invoice matching, accounts payable, tax, landed cost, payment processing, and multi-currency purchasing.

## 3. Business Context

ACME requires Buyers to place supplier purchase orders and source non-routinely stocked items requested by Sales. Inventory Management requires authoritative purchase order data before it can book received stock. Purchasing must preserve ordered terms, expose expected arrivals, and show receipt progress without owning inventory balances.

The MVP outcome is a direct workflow from draft authoring to supplier ordering, followed by receipt visibility and closure.

## 4. Stakeholders and Roles

| Role | Description | Responsibilities | Domain Permissions |
|---|---|---|---|
| Buyer | Internal user acting through Buyer. | Maintain permitted supplier references, create and edit drafts, place purchase orders, link buyer requests, monitor arrivals, and close fully received orders. | Supplier maintenance, draft authoring, order placement, buyer request actions, closure, and permitted queries. |
| Sales Assistant | Internal user originating buyer requests through Sales Assistant. | Monitor sourcing progress for non-routinely stocked sales lines. | Read copied buyer request status through Sales contracts; no direct Purchasing mutation. |
| Warehouse Operator | Internal user receiving goods through Warehouse Operator. | Select an ordered purchase order and record matching received quantities in Inventory Management. | Read eligible purchase order details through the Inventory workflow. |
| Integration Service Account | Authenticated service identity for Sales and Inventory Management calls. | Exchange buyer request, purchase order, and receipt data. | Invoke only explicitly scoped integration operations. |

## 5. Domain Capabilities and Workflows

### 5.1 Supplier and Purchase Order Authoring

An authorized Buyer maintains the active supplier references required for ordering. Purchase order authoring starts with a Draft containing a supplier, dates, currency, and one or more lines. Draft terms may be edited until placement. Successful placement makes the purchase order Ordered and fixes the ordered supplier, item, quantity, unit cost, purchase date, and expected arrival data.

### 5.2 Buyer Request Sourcing

Purchasing receives one idempotent buyer request for each Sales request ID. The request starts Open, becomes Linked when a Buyer links an Ordered purchase order line, and becomes Satisfied when Inventory receipt visibility shows the linked requested quantity received.

### 5.3 Receipt Visibility and Closure

Inventory Management queries Ordered purchase orders to validate goods receipts and reports cumulative received quantities. Purchasing derives Ordered, Partially Received, or Received from those quantities. A Buyer may close a Received purchase order; Closed is terminal.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| PUR-DOM-001 | Supplier reference | The system shall maintain unique supplier code, name, active status, default contact, and delivery lead-time note for the MVP supplier set. | Must | Given an authorized valid command, when a supplier is created or updated, then Purchasing shall persist the reference; an inactive supplier shall not be used for a new order. |
| PUR-DOM-002 | Purchase order creation | The system shall create a Draft purchase order with a unique number, active supplier, configured currency, purchase date, expected arrival date, and at least one valid line. | Must | Given complete valid data, when a Buyer creates the order, then one Draft shall be persisted; missing or invalid data shall produce field-level errors with no partial order. |
| PUR-DOM-003 | Draft editing | The system shall permit supplier, date, and line changes only while a purchase order is Draft. | Must | Given a Draft and matching row version, when a Buyer submits valid changes, then they shall be persisted; an Ordered purchase order shall reject term changes. |
| PUR-DOM-004 | Order placement | The system shall place a valid Draft purchase order directly into Ordered state and preserve the ordered terms. | Must | Given an active supplier and valid lines, when placement is requested, then the state shall become Ordered and the order shall be available to Inventory Management. |
| PUR-DOM-005 | Buyer request intake | The system shall persist one Open buyer request for each valid Sales buyer request external ID. | Must | Given a complete authenticated Sales command, when Purchasing accepts it, then one Open request shall exist; replay with the same idempotency key shall return the original request. |
| PUR-DOM-006 | Buyer request linkage | The system shall link an Open buyer request to one Ordered purchase order line with sufficient ordered quantity. | Must | Given matching item details and quantity, when a Buyer links the request, then its state shall become Linked and Sales shall receive the purchase order reference. |
| PUR-DOM-007 | Receipt lookup | The system shall expose ordered supplier, line, quantity, cost, date, expected arrival, and received-to-date data to Inventory Management. | Must | Given a known Ordered or Partially Received purchase order, when Inventory requests it, then Purchasing shall return the authoritative terms and external IDs. |
| PUR-DOM-008 | Receipt visibility | The system shall consume cumulative received quantities from Inventory Management and derive purchase order and buyer request state without booking stock. | Must | Given a valid idempotent receipt update, when cumulative quantity is below ordered quantity, then the order shall be Partially Received; when all lines are fully received, it shall be Received. |
| PUR-DOM-009 | Purchase order closure | The system shall permit a Buyer to close only a Received purchase order. | Must | Given a Received order, when an authorized Buyer closes it, then it shall become Closed; any other current state shall reject closure. |
| PUR-DOM-010 | Purchasing queries | The system shall expose paginated, stably sorted searches for suppliers, active purchase orders, expected arrivals, buyer requests, and receipt visibility. | Must | Given authorized filters, when a query executes, then every result shall satisfy the filters and caller scope. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| PUR-BR-001 | A new purchase order shall identify an active Purchasing-owned supplier. | Purchase order | Purchasing validation | Supplier code is unique. |
| PUR-BR-002 | A purchase order shall contain at least one line with item description, positive quantity, positive unit cost, and Inventory product/SKU ID where available. | Purchase order line | Purchasing validation | Free-text details support non-routinely stocked requests. |
| PUR-BR-003 | Expected arrival date shall not precede purchase date. | Purchase order | Purchasing validation | Calendar dates are stored without local time. |
| PUR-BR-004 | MVP purchase orders shall use the configured company currency. | Purchase order | Purchasing validation | Currency code is persisted with monetary values. |
| PUR-BR-005 | Ordered supplier, item, quantity, unit cost, purchase date, and expected arrival data shall be immutable. | Ordered purchase order | Purchasing state rules | Inventory receives the same terms used at placement. |
| PUR-BR-006 | A buyer request shall link only to an Ordered purchase order line that can cover its requested quantity. | Buyer request | Purchasing linkage workflow | Sales owns the originating order context. |
| PUR-BR-007 | Received-to-date quantity shall be non-negative and shall not exceed ordered quantity. | Receipt visibility | Purchasing integration validation | Inventory Management owns receipt records and stock. |
| PUR-BR-008 | Closed purchase orders and Satisfied buyer requests are terminal. | State transitions | Purchasing state rules | Later commands return a conflict without mutation. |
| PUR-BR-009 | Stale row versions shall not overwrite current mutable state. | Supplier, Draft purchase order | Purchasing persistence | The caller must refresh before retrying. |

## 8. State Model

### 8.1 Purchase Order

| State | Allowed Transitions | Trigger | Guards / Notes |
|---|---|---|---|
| Draft | Ordered | Buyer places valid order | Draft is the only state in which ordered terms are editable. |
| Ordered | Partially Received, Received | Inventory receipt update | Ordered remains when cumulative received quantity is zero. |
| Partially Received | Partially Received, Received | Later receipt update | Cumulative quantities are idempotent and monotonic. |
| Received | Closed | Buyer closes order | Every line is fully received. |
| Closed | None | Closure accepted | Terminal state. |

### 8.2 Buyer Request

| State | Allowed Transitions | Trigger | Guards / Notes |
|---|---|---|---|
| Open | Linked | Buyer links an Ordered line | One active purchase order line link per request. |
| Linked | Satisfied | Linked requested quantity is received | Purchasing reports status to Sales. |
| Satisfied | None | Sourcing complete | Terminal state. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Supplier Reference | Purchasing | Yes | Unique code, bounded name/contact fields, active flag, and row version. | None for MVP. |
| Purchase Order | Purchasing | Yes | Unique number, supplier ID, state, currency, purchase date, expected arrival date, Buyer identity, timestamps, and row version while mutable. | Correlation and application request IDs. |
| Purchase Order Line | Purchasing | Yes | Item description, positive quantity, positive unit cost, and received-to-date copy. | Inventory product, SKU, and barcode external IDs where available. |
| Buyer Request | Purchasing | Conditional | Unique Sales request ID, requested description, quantity, state, and timestamps. | Sales order and line external IDs. |
| Buyer Request Link | Purchasing | Conditional | One linked purchase order line and covered quantity. | Sales request and Purchasing line IDs. |
| Receipt Visibility | Purchasing copy | Conditional | Inventory receipt ID, cumulative received quantity, receipt date, source, and update ID. | Inventory receipt external ID. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Failure Handling |
|---|---|---|---|---|---|---|
| PUR-INT-001 | Sales | Purchasing | Command | Buyer request ID, Sales order and line IDs, item details, quantity, source, and correlation ID. | Non-routinely stocked request submission. | Incomplete commands are rejected; duplicate identity returns the original request. |
| PUR-INT-002 | Purchasing | Sales | Update | Buyer request ID, Open/Linked/Satisfied state, linked purchase order reference, update ID, and timestamp. | Buyer request state change. | Transient failures use bounded retry with the same update ID; local state remains committed and observable. |
| PUR-INT-003 | Inventory Management | Purchasing | Query | Purchase order number or external ID. | Goods receipt lookup. | Unknown or ineligible orders return a not-found or conflict response without mutation. |
| PUR-INT-004 | Purchasing | Inventory Management | Response | Supplier, lines, external product IDs, ordered quantities, unit costs, dates, state, and received-to-date values. | Goods receipt lookup. | Response data is generated from the current authoritative order version. |
| PUR-INT-005 | Inventory Management | Purchasing | Update | Purchase order and line IDs, receipt ID, cumulative received quantities, receipt date, update ID, and correlation ID. | Successful stock booking. | Unknown IDs, decreasing totals, over-receipt, and invalid state are rejected without changing visibility. |
| PUR-INT-006 | Buyer API | Purchasing | Command/query | Supplier, purchase order, buyer request actions, and search filters. | User action. | Authorization, validation, concurrency, and dependency failures return deterministic responses without partial local changes. |

## 11. Search and Query Requirements

| Query / View | Audience | Purpose | Filters |
|---|---|---|---|
| Supplier Search | Buyer | Select and maintain supplier references. | Code, name, active status. |
| Active Purchase Orders | Buyer | Monitor orders through receipt. | PO number, supplier, SKU, state, Buyer, purchase date, expected arrival date. |
| Expected Arrivals | Buyer and Warehouse Operator integration | Plan and identify goods receipts. | Arrival date range, supplier, SKU, PO state. |
| Buyer Request Worklist | Buyer | Source Sales-requested items. | State, Sales order, item description, created date range. |
| Receipt Visibility | Buyer | Compare ordered and received quantities. | PO number, supplier, SKU, receipt date range, PO state. |

## 12. Security and Authorization Controls

- Purchasing shall require an authenticated user or scoped service identity for every non-health operation.
- Purchasing shall authorize supplier maintenance, draft authoring, order placement, buyer request linkage, closure, integration updates, and queries independently.
- Buyer access shall be constrained by mapped business scope where configured.
- Sales and Inventory Management service identities shall invoke only their named contracts.
- Authorization shall fail closed and shall not reveal out-of-scope supplier or purchase order data.
- Supplier contact and unit-cost data shall be returned only to permitted workflows.

## 13. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| PUR-NFR-001 | Consistency | Each supplier, purchase order, buyer request, or receipt-visibility change shall commit in one Purchasing database transaction. |
| PUR-NFR-002 | Reliability | Cross-service mutations shall use idempotency keys, correlation IDs, deterministic duplicate responses, and bounded retries for transient outbound failures. |
| PUR-NFR-003 | Performance | Searches shall use pagination, bounded page sizes, indexed filters, and stable sorting suitable for the expected MVP data volume. |
| PUR-NFR-004 | Concurrency | Mutable suppliers and Draft purchase orders shall use optimistic concurrency. |
| PUR-NFR-005 | Observability | Structured logs, metrics, traces, health checks, and readiness checks shall include operation, outcome, correlation ID, and dependency without logging supplier contact details. |
| PUR-NFR-006 | Contracts | The Purchasing API shall publish OpenAPI 3.0 contracts documenting identity, external IDs, validation errors, authorization failures, conflicts, and retryable dependency failures. |
| PUR-NFR-007 | Maintainability | Purchasing shall not depend on application UI projects or application-owned persistence. |
| PUR-NFR-008 | Localization | Dates, quantities, money, and ISO currency codes shall follow shared data conventions; presentation formatting remains an application concern. |
| PUR-NFR-009 | Testability | Automated tests shall cover required fields, direct placement, immutable ordered terms, buyer request transitions, receipt totals, closure, authorization, and idempotency. |

## 14. Technical Failures and Edge Cases

- Duplicate purchase order placement, buyer request intake, status update, and receipt update calls shall return the original outcome for the same idempotency identity.
- Stale row versions shall return a conflict and preserve current data.
- Unknown external IDs, malformed payloads, invalid source identities, and invalid transitions shall be rejected without partial mutation.
- A temporary Sales outage shall not roll back a committed buyer request change; retry shall reuse the original update ID.
- An Inventory receipt update with a decreasing cumulative quantity or quantity above ordered amount shall be rejected.
- An unavailable dependency shall produce a correlated retryable failure while preserving the last committed Purchasing state.

## 15. Dependencies

- Sales for buyer request origination and receipt of buyer request status.
- Inventory Management for product identifiers, purchase order receipt lookup, and copied cumulative receipt quantities.
- Gravitee and Authentik for ingress, OAuth/OIDC identity, user claims, and service identities.
- Buyer for user-facing supplier, purchase order, buyer request, expected arrival, and receipt-visibility workflows.
- Warehouse Operator for user-facing receipt capture through Inventory Management.

## 16. Assumptions

- Purchasing owns reference data for 10 to 20 active MVP suppliers until a dedicated supplier master exists.
- Buyers place valid purchase orders directly with suppliers.
- Ordered purchase order terms are immutable.
- MVP uses one configured company currency.
- Supplier-facing access and electronic supplier transmission are not included; placement records that the order was sent through the Buyer workflow.
- Receipt visibility is copied from Inventory Management and does not transfer stock ownership.
- Buyer requests use the Open, Linked, and Satisfied lifecycle.

## 17. Open Questions

None for the MVP Purchasing workflow.

## 18. Acceptance Summary

The Purchasing specification is complete when Buyer can maintain supplier references, author and place purchase orders, process Sales buyer requests, expose ordered terms to Inventory Management, consume receipt progress, close fully received orders, and query current work while Purchasing preserves durable ownership, authorization, immutable ordered terms, idempotency, correlation, and database boundaries.
