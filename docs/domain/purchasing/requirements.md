# Domain Requirements: Purchasing

## 1. Purpose

The Purchasing bounded context owns durable supplier-backed purchase orders, MVP supplier reference data, purchasing approval state, buyer request queue decisions, purchase order receipt visibility, purchasing status history, and purchasing operational history records.

Purchasing exposes WebAPI contracts and owns the Purchasing database. It is authoritative for purchase order validation, purchasing approval rules, buyer request handling, purchasing authorization, idempotency, and purchasing operational history. Buyer workbench, purchasing manager screens, warehouse receipt presentation, and reporting screens are owned by application services.

## 2. Domain Scope

### In Scope

- Purchase order creation, amendment, submission, approval, ordering, cancellation, closure, status transitions, and operational history.
- Supplier reference data for the 10 to 20 active MVP suppliers.
- Buyer request queue decisions for non-routinely stocked product requests from Sales.
- Purchase order lookup contracts for Inventory Management goods receipt matching.
- Receipt status and exception visibility copied from Inventory Management.
- Purchasing reporting endpoints, open PO queries, and export source data.

### Out of Scope

- Razor Pages UI, buyer workbench screen flow, dashboard layout, or approval presentation.
- Physical goods receipt booking, stock balance mutation, discrepancy adjustment, and inventory movements.
- Sales order capture, customer communication, fulfilment execution, courier shipping, and label printing.
- Supplier onboarding, contract management, tendering, supplier scorecards, invoice matching, accounts payable posting, tax, landed cost allocation, and payment processing for the MVP.

## 3. Business Context

ACME needs buyers to create controlled purchase orders for suppliers and to respond to Sales requests for non-stocked products while giving Inventory Management reliable purchase order data for receipt matching. Purchasing must prevent unauthorized approval, retain receipt visibility, and preserve decision history for amendments and approvals.

The MVP outcome is a simple purchasing workflow where POs can be authored, approved when policy requires, made available for receipt, updated with receipt status, and reported without applications or Inventory owning Purchasing state.

## 4. Stakeholders and Roles

| Role | Description | Responsibilities | Domain Permissions |
|---|---|---|---|
| Buyer | Purchasing user creating and managing POs. | Create drafts, amend eligible POs, process buyer requests, monitor expected arrivals. | Create/update POs, submit for approval, act on buyer requests, query receipt visibility. |
| Purchasing Manager | Approval/control role. | Approve/reject controlled PO actions, review amendments and cancellations. | Approve/reject POs and controlled amendments subject to self-approval checks. |
| Sales Assistant/Sales Supervisor | Originators of non-stocked product requests through Sales. | Monitor buyer request status. | Query copied buyer request status through Sales/application contracts. |
| Warehouse Operator/Inventory Supervisor | Consumers of PO receipt-matching data through Inventory. | Receive goods and resolve receipt exceptions. | Read eligible PO details through Inventory/Purchasing contracts. |

## 5. Domain Capabilities and Workflows

- **Purchase order authoring** starts when a Buyer creates a PO with supplier, lines, quantities, unit costs, purchase date, and expected arrival date. It ends in Draft, Submitted, Approval Required, Approved, Ordered, Cancelled, or validation failure.
- **Approval workflow** starts when policy determines approval is required. It ends with approval, rejection, return for amendment, or cancellation.
- **Buyer request workflow** starts when Sales sends a non-stocked product request. It ends with accepted, linked to PO, rejected with reason, returned for clarification, or closed.
- **Receipt visibility workflow** starts when Inventory books or raises exceptions against a PO. It ends with Purchasing showing not received, partially received, received, exception, or closed status.
- **Amendment and cancellation** starts when a Buyer requests changes. It ends with immediate draft amendment, approved controlled amendment, rejection, or blocked change because receipt state prevents it.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| PUR-DOM-001 | Supplier reference | The system shall maintain MVP supplier reference data required for purchase order creation and reporting. | Must | Given a supplier is inactive or unknown, when a PO is submitted, then Purchasing rejects the PO or blocks submission according to policy. |
| PUR-DOM-002 | PO creation | The system shall accept purchase order commands only when supplier, item, SKU/barcode where available, quantity, unit cost, purchase date, expected arrival date, and correlation metadata are present. | Must | Given required data is complete and authorized, when a Buyer creates a PO, then Purchasing persists it with status history; missing required fields produce validation errors and no partial controlled state. |
| PUR-DOM-003 | PO lifecycle | The system shall maintain explicit PO states for Draft, Submitted, Approval Required, Approved, Ordered, Partially Received, Received, Closed, Cancelled, Rejected, and Exception. | Must | Given a transition is invalid for current state or receipt status, when requested, then Purchasing rejects it and records no state change. |
| PUR-DOM-004 | Approval control | The system shall enforce configurable approval thresholds and self-approval prevention for controlled purchasing actions. | Must | Given a PO exceeds configured threshold, when submitted, then it requires Purchasing Manager approval; given the creator attempts approval, then the action is denied. |
| PUR-DOM-005 | Buyer requests | The system shall receive Sales-originated buyer requests and maintain Purchasing-owned queue decisions without taking ownership of Sales order state. | Must | Given a buyer request is accepted, rejected, returned, or linked to a PO, when status changes, then Purchasing records the decision and sends a correlated status update to Sales. |
| PUR-DOM-006 | Receipt matching support | The system shall expose eligible PO details to Inventory Management for goods receipt matching. | Must | Given Inventory requests an eligible PO, when Purchasing responds, then the response includes supplier, item, SKU/barcode, ordered quantity, unit cost, dates, and current PO status. |
| PUR-DOM-007 | Receipt visibility | The system shall consume Inventory receipt status and exception updates as copied visibility for purchasing workflows. | Must | Given Inventory reports partial receipt or exception, when Purchasing accepts the update, then PO receipt visibility and status history reflect the copied state without Purchasing booking stock. |
| PUR-DOM-008 | Amendment and cancellation | The system shall support draft amendments and controlled post-submission amendments/cancellations with business reason and approval where required. | Must | Given an approved or partially received PO is amended, when controlled fields change, then Purchasing requires approval or rejects the change if receipt state prevents it. |
| PUR-DOM-009 | Purchasing queries | The system shall expose query contracts for open POs, expected arrivals, buyer requests, receipt status, approvals, amendments, and operational history. | Should | Given an authorized query with filters, when Purchasing processes it, then results are permission-scoped and include stale receipt indicators where applicable. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| PUR-BR-001 | Purchase orders must identify an active supplier. | PO | Purchasing validation | Supplier reference data is Purchasing-owned for MVP. |
| PUR-BR-002 | PO lines must contain item, SKU/barcode where available, positive quantity, unit cost, purchase date, and expected arrival date. | PO line | Purchasing validation | Product references originate in Inventory. |
| PUR-BR-003 | Quantity ordered must be positive and numeric. | PO line | Purchasing validation | Unit-of-measure validation may use Inventory data. |
| PUR-BR-004 | Unit cost is captured in configured company currency unless multi-currency is later enabled. | PO line | Purchasing validation | Multi-currency is out of scope for MVP. |
| PUR-BR-005 | Purchase orders used for inventory booking must be available to Inventory Management. | Receipt matching | Purchasing API | Inventory books stock, not Purchasing. |
| PUR-BR-006 | POs over configured approval threshold require Purchasing Manager approval. | Approval | Purchasing authorization | Existing docs mention 10,000 as placeholder. |
| PUR-BR-007 | Buyers may not approve their own purchase orders or controlled amendments. | Approval control | Purchasing authorization | Enforced by domain. |
| PUR-BR-008 | Buyers may amend draft POs without approval. | Amendments | Purchasing state model | Purchasing records change history. |
| PUR-BR-009 | Post-submission changes to supplier, quantity, unit cost, expected arrival date, or cancellation require business reason and approval when approved, ordered, or partially received. | Controlled amendments | Purchasing workflow | Receipt state can block changes. |
| PUR-BR-010 | Sales buyer requests may be accepted, linked to a PO, rejected with reason, returned for clarification, or closed. | Buyer requests | Purchasing workflow | Sales owns originating request context. |

## 8. State Model

| State | Allowed Transitions | Triggering Events | Guards / Notes |
|---|---|---|---|
| Draft | Submitted, Cancelled | Buyer submits or cancels | Draft can be amended by creator/authorized Buyer. |
| Submitted | Approval Required, Approved, Rejected, Cancelled, Exception | Validation and approval policy evaluation | Approval required depends on policy threshold. |
| Approval Required | Approved, Rejected, Returned, Cancelled | Manager decision | Creator cannot approve own PO. |
| Approved | Ordered, Cancelled, Exception | Buyer sends/order marks ordered | Controlled amendments require approval. |
| Ordered | Partially Received, Received, Cancelled, Exception | Inventory receipt update or cancellation request | Cancellation may be blocked after receipt. |
| Partially Received | Received, Closed, Exception | Inventory receipt update or closure | Quantity changes require controlled handling. |
| Received | Closed, Exception | Final review/closure | Stock booking is Inventory-owned. |
| Returned | Draft, Cancelled | Buyer amendment | Preserves approval comments. |
| Rejected | Draft, Cancelled | Buyer revises or cancels | Rejection reason required. |
| Cancelled | Exception | Correction | Terminal unless approved correction. |
| Closed | Exception | Correction | Terminal for normal workflow. |
| Exception | Prior recoverable state, Cancelled | Retry, correction, manual review | Used for integration or policy failures. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Supplier Reference | Purchasing | Yes | Active supplier, supplier identifier, basic contact/reference data required for MVP. | Future supplier master if introduced. |
| Purchase Order | Purchasing | Yes | Unique PO number, supplier, status, dates, buyer, approval status. | Buyer identity and application source. |
| Purchase Order Line | Purchasing | Yes | Item, SKU/barcode where available, quantity, unit cost, expected arrival date. | Inventory product/SKU external IDs. |
| Buyer Request Queue Item | Purchasing | Conditional | Sales request ID, requested item, quantity, decision state, reason. | Sales buyer request external ID. |
| Receipt Visibility | Inventory Management copy | Conditional | Received quantity, receipt status, exception state, receipt date. | Inventory receipt external ID. |
| Purchasing Activity History | Purchasing | Yes | Actor/service, action, prior/new state, outcome, timestamp, correlation ID. | Purchasing-owned operational history. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Failure Handling |
|---|---|---|---|---|---|---|
| PUR-INT-001 | Purchasing | Inventory Management | Outbound query/copy | PO header, lines, supplier, item, SKU/barcode, quantity, unit cost, purchase date, expected arrival, status. | Receipt lookup/booking. | Return explicit unavailable/stale response; do not infer receipt eligibility. |
| PUR-INT-002 | Inventory Management | Purchasing | Inbound update | Received quantities, receipt status, receipt exceptions, receipt dates. | Receipt booking/exception changes. | Ignore duplicates by idempotency; mark receipt visibility stale if update cannot be applied. |
| PUR-INT-003 | Sales | Purchasing | Inbound command | Buyer request ID, customer/order context, requested product details, quantity, reason, correlation ID. | Non-stocked request submission. | Reject incomplete payload; return duplicate response for same idempotency key. |
| PUR-INT-004 | Purchasing | Sales | Outbound update | Buyer request status, decision reason, linked PO reference where allowed, timestamps. | Buyer request decision changes. | Retry idempotently; preserve pending Sales update state. |
| PUR-INT-005 | Inventory Management | Purchasing | Inbound query | Product/SKU/barcode/unit-of-measure validation data where needed. | PO line validation. | Reject or warn according to product validation result. |
| PUR-INT-006 | Application APIs | Purchasing | Inbound command/query | PO commands, approvals, buyer request actions, search/report filters. | User actions. | Domain authorization/validation errors returned without partial state changes. |

## 11. Reporting and Query Requirements

| Report / Query | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Open PO Search | Buyer, Purchasing Manager | Manage active purchase orders. | PO number, supplier, SKU, status, buyer, expected arrival date. | CSV for operational review. |
| Expected Arrivals | Buyer, Warehouse, Inventory Supervisor | Plan receipts. | Date range, supplier, SKU, PO status. | CSV optional. |
| Buyer Request Queue | Buyer, Purchasing Manager | Process non-stocked requests. | Request state, Sales order, SKU/description, age, buyer. | CSV optional. |
| Approval History | Purchasing Manager | Review controlled decisions. | Approver, requester, threshold, date, status. | CSV for operational review. |
| Receipt Exception Visibility | Buyer, Inventory Supervisor | Monitor PO receipt problems. | Supplier, PO, SKU, exception type, age. | CSV optional. |

## 12. Security, Authorization, and Approval Controls

Purchasing shall enforce authorization for supplier reference maintenance, PO creation, amendment, submission, approval, cancellation, buyer request decisions, receipt visibility queries, reports, and exports. Application controls are not authoritative.

Purchasing Manager approval is required for configured high-value POs and controlled post-submission amendments/cancellations. Buyers cannot approve their own POs or controlled amendments. Platform administration access does not imply purchasing approval authority unless the user also has explicit Purchasing Manager permission.

## 13. Operational History and Traceability

Purchasing shall record operational history for supplier reference changes, PO creation, submission, approval, rejection, amendment, cancellation, ordering, receipt visibility updates, buyer request decisions, and authorization denials.

Operational history records shall include actor/service, source application/domain, PO and buyer request IDs, prior/new state, changed controlled fields, reason/comments, outcome, timestamp, correlation ID, and idempotency key where applicable.

## 14. Non-Functional Requirements

- PO commands, buyer request commands, and receipt status updates shall be idempotent where retries may occur.
- Query contracts shall support pagination and stable sorting for open PO and buyer request queues.
- Integration failures shall create visible stale or exception state rather than silently hiding missing receipt or Sales updates.
- Purchasing validation errors shall be deterministic and field-addressable for application presentation.
- Structured logs, metrics, health checks, and operational history shall support operational diagnosis.
- Purchasing services shall not depend on application UI projects or application-owned persistence.

## 15. Dependencies

- Inventory Management for product/SKU/barcode validation and receipt status feedback.
- Sales for buyer request origination and status synchronization.
- Gravitee and Authentik for authenticated ingress, service identities, user roles, and correlation metadata.
- Buyer, Warehouse Operator, Inventory Supervisor, and Sales Assistant application APIs for user-facing workflows and presentation.

## 16. Assumptions and MVP Defaults

- Purchasing owns supplier reference data for the 10 to 20 active MVP suppliers until a dedicated supplier master is introduced.
- The MVP purchase order approval threshold is 10,000 in the configured company currency.
- Purchasing Manager is the MVP approval role for high-value purchase orders and controlled post-submission amendments.
- MVP uses one configured company currency; multi-currency is deferred.
- MVP supplier reference records require supplier name, supplier code, active status, default contact name, default contact email, and default delivery lead-time note where known.
- Supplier-facing status visibility is out of scope; all purchase order status visibility is internal for MVP.
- Accounts payable, invoice matching, tax, landed cost, and payment processing are deferred.
- Receipt status is copied visibility from Inventory Management and does not transfer stock ownership to Purchasing.
- Purchasing approvals and PO amendment history are retained according to Purchasing-owned operational data policy; no central compliance-retention baseline applies in MVP.

## 17. Acceptance Summary

The Purchasing requirements are complete for MVP when they define authoritative PO and supplier-reference ownership, buyer request decisions, approval and amendment workflows, Inventory and Sales integrations, receipt visibility, local approval controls, operational history, reporting needs, and explicit MVP defaults without assigning UI workflows or durable purchasing state to application services.
