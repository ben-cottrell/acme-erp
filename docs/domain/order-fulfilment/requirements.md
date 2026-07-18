# Domain Requirements: Order Fulfilment

## 1. Purpose

The Order Fulfilment bounded context owns durable fulfilment task state, pick/pack/ship/completion rules, courier shipment purchase records, label references, fulfilment exceptions, fulfilment status history, and fulfilment operational history records.

Order Fulfilment exposes WebAPI contracts and owns the Fulfilment database. It is authoritative for fulfilment task lifecycle, fulfilment authorization, courier transaction references, exception approval, completion decisions, and fulfilment operational history. Fulfilment operator, supervisor, sales visibility, and reporting screens are owned by application services.

## 2. Domain Scope

### In Scope

- Receipt of released sales order contracts from Sales and creation of fulfilment tasks.
- Fulfilment task lifecycle from release through picking, packing, shipping purchase, label reference, completion, partial fulfilment, cancellation, and exception state.
- Component requirement, picked quantity, short pick, substitution, damaged component, and packing validation.
- MVP courier shipment purchase path, label reference storage, tracking reference, and shipping exception state.
- Inventory reservation, consumption, and reversal request contracts.
- Fulfilment status updates to Sales and fulfilment history/reporting data.

### Out of Scope

- Razor Pages UI, task queue presentation, scanner UX, or label print dialog behavior.
- Sales order creation, customer account ownership, pricing, payment, invoicing, returns/RMA, or customer communication.
- Product master ownership, stock balance authority, regular stock checks, goods receipt booking, or inventory adjustments.
- Purchase order authoring, supplier ordering, finance postings, courier contract management, shipping rate negotiation, failed delivery processing, and refunds for the MVP.

## 3. Business Context

ACME needs released sales demand to become controlled warehouse fulfilment work without Sales or application services owning warehouse state. Fulfilment must validate picks against released requirements, coordinate inventory consumption, purchase courier shipping where needed, preserve label evidence, and report progress back to Sales.

The MVP outcome is a reliable fulfilment lifecycle where released orders can be picked, packed, shipped, completed, partially fulfilled, or placed into exception state with supervisor control and operational traceability.

## 4. Stakeholders and Roles

| Role | Description | Responsibilities | Domain Permissions |
|---|---|---|---|
| Fulfilment Operator | Warehouse user executing tasks. | Pick, pack, request shipping purchase, print labels through applications, complete tasks, record exceptions. | Update assigned fulfilment task steps where policy allows. |
| Fulfilment Supervisor | Control role for fulfilment exceptions. | Approve short picks, substitutions, shipping overrides, cancellations after picking starts, and completion reversals. | Approve/reject controlled fulfilment actions and view fulfilment history. |
| Sales Assistant/Sales Supervisor | Sales users needing fulfilment visibility. | Monitor released order progress and customer-impacting exceptions. | Query fulfilment status through Sales or authorized reporting contracts. |
| Inventory Supervisor | Inventory control user resolving stock issues. | Review reservation/consumption failures and coordinate inventory exceptions. | Query fulfilment-linked inventory exception context. |

## 5. Domain Capabilities and Workflows

- **Fulfilment intake** starts when Sales sends a released order contract. It ends with a fulfilment task created or the release rejected as invalid.
- **Pick workflow** starts when an operator begins a task. It ends with required quantities picked, short pick/substitution/damage exception raised, or task returned to queue.
- **Pack and ship workflow** starts after pick validation. It ends with packing confirmed, courier shipping purchased, label reference stored, or shipping exception recorded.
- **Completion workflow** starts after pick, pack, shipping, and label conditions are met or an approved manual exception exists. It ends with accepted Inventory consumption and Sales status updates, or approved partial fulfilment/backorder.
- **Exception workflow** starts when validation, stock, label, cancellation, or reversal issue occurs. It ends with supervisor approval, rejection, cancellation, or correction.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| FUL-DOM-001 | Intake | The system shall create fulfilment tasks only from Sales-released order contracts that include order identifiers, lines, quantities, and delivery context. | Must | Given a valid release, when Order Fulfilment accepts it, then a task is created; given invalid or ineligible data, then the release is rejected without partial state. |
| FUL-DOM-002 | Task lifecycle | The system shall maintain explicit fulfilment task states from Released through Picking, Picked, Packing, Packed, Shipping Purchased, Label Printed, Partially Fulfilled, Completed, Cancelled, and Exception. | Must | Given a transition request, when the transition is invalid for the current state, then the system rejects it and records no state change. |
| FUL-DOM-003 | Pick validation | The system shall validate picked products, SKUs, serials where applicable, and quantities against released order requirements and Inventory data. | Must | Given picked quantities match requirements, when pick is confirmed, then the task can progress to packing; given mismatch or damage, then a pick exception is recorded. |
| FUL-DOM-004 | Exception approvals | The system shall require Fulfilment Supervisor approval for short picks, substitutions, partial fulfilment release, shipping overrides, cancellation after picking starts, and completion reversals. | Must | Given an operator records an exception, when the same operator attempts approval, then the approval is denied by the local self-approval rule. |
| FUL-DOM-005 | Courier shipment | The system shall record accepted courier shipment, label, and tracking references for the MVP provider path. | Must | Given the courier accepts a shipment purchase, when the provider response is received, then the shipment, label, and tracking references are stored. |
| FUL-DOM-006 | Completion | The system shall complete a fulfilment task only when required pick, pack, shipping purchase, label, Sales update, and Inventory consumption conditions are satisfied or an approved business exception exists. | Must | Given required conditions pass, when completion is requested, then Inventory accepts the consumption, Sales accepts the fulfilment update, and the task becomes Completed or Partially Fulfilled as appropriate. |
| FUL-DOM-007 | Partial fulfilment | The system shall support partial fulfilment where approved and report remaining quantities to Sales as backordered. | Must | Given a supervisor approves partial fulfilment, when completion occurs for available quantities, then Sales receives fulfilled and backordered quantities. |
| FUL-DOM-008 | Inventory coordination | The system shall request Inventory reservation, consumption, and reversal using Sales order, fulfilment task, and Inventory business references. | Must | Given a valid request, when Inventory accepts it, then Order Fulfilment records the resulting reservation or stock movement reference. |
| FUL-DOM-009 | Fulfilment queries | The system shall expose query contracts for task queues, business exceptions, shipment references, completion history, and operational reporting. | Should | Given an authorized query, when filters are supplied, then results are role-scoped and include the requested business state. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| FUL-BR-001 | Fulfilment begins only for orders released by Sales. | Intake | Order Fulfilment API | Sales owns release decision. |
| FUL-BR-002 | Picked components must match released order requirements unless a controlled exception is approved. | Picking | Pick validation | Product master remains Inventory-owned. |
| FUL-BR-003 | Courier shipping must be purchased before a courier label is printed unless a manual exception is authorized. | Shipping | Shipping workflow | MVP supports one provider path. |
| FUL-BR-004 | Orders cannot be completed until pick, pack, shipping, label, Sales, and Inventory conditions are satisfied or an authorized business exception is approved. | Completion | Completion workflow | Sales and Inventory must accept their respective updates before completion is recorded. |
| FUL-BR-005 | Inventory consumption must be traceable to fulfilment task, sales order, and reservation. | Consumption | Inventory integration | Inventory owns stock movements. |
| FUL-BR-006 | Partial fulfilment must report remaining quantities to Sales as backordered. | Partial fulfilment | Completion workflow | Customer wording belongs to applications/Sales visibility. |
| FUL-BR-007 | Fulfilment Supervisor approval is required for controlled exceptions and reversals. | Exceptions | Authorization | Operator who records an exception cannot approve it. |
| FUL-BR-008 | Royal Mail is the default first courier provider unless ACME supplies a different existing courier account before implementation starts. | Courier | Provider integration | Existing requirement retained as MVP assumption. |

## 8. State Model

| State | Allowed Transitions | Triggering Events | Guards / Notes |
|---|---|---|---|
| Released | Picking, Cancelled, Exception | Sales release accepted, cancellation, validation issue | Task created from Sales contract. |
| Picking | Picked, Pick Exception, Cancelled, Exception | Pick action, mismatch, damage, cancellation | Cancellation after picking starts requires approval. |
| Pick Exception | Picking, Picked, Partially Fulfilled, Cancelled, Exception | Supervisor decision | Short pick/substitution needs approval. |
| Picked | Packing, Exception | Pick confirmation | Requires validated quantities or approved exception. |
| Packing | Packed, Exception | Pack confirmation | Packing failure remains recoverable. |
| Packed | Shipping Purchased, Exception | Courier purchase accepted or business exception raised | Shipping may be skipped only by approved manual exception. |
| Shipping Purchased | Label Printed, Exception | Label generated/stored | Label reference required unless approved exception. |
| Label Printed | Completed, Partially Fulfilled, Exception | Completion request | Inventory consumption and Sales update required. |
| Partially Fulfilled | Completed, Exception | Remaining fulfilment or correction | Backorder reported to Sales. |
| Completed | Exception | Correction/reversal | Terminal for normal path. |
| Cancelled | Exception | Approved cancellation | Terminal unless correction is approved. |
| Exception | Prior recoverable state, Cancelled | Supervisor decision or correction | Recovery path depends on prior state. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Fulfilment Task | Order Fulfilment | Yes | Unique task ID, status, source sales order, timestamps, assigned/acting user where applicable. | Sales order external ID. |
| Fulfilment Task Line | Order Fulfilment | Yes | Product/SKU reference, required quantity, picked quantity, exception state. | Inventory product/SKU external IDs. |
| Shipment Purchase Record | Order Fulfilment | Conditional | Courier, accepted amount if returned, tracking, and label reference. | Courier transaction ID. |
| Label Reference | Order Fulfilment | Conditional | Stored reference or provider label ID; printable file storage is implementation-specific. | Courier provider. |
| Reservation/Consumption Reference | Inventory Management | Conditional | External IDs only; Inventory owns stock mutation. | Inventory reservation/movement IDs. |
| Fulfilment Activity History | Order Fulfilment | Yes | Actor/service, action, prior/new state, outcome, and timestamp. | Order Fulfilment-owned operational history. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Validation |
|---|---|---|---|---|---|---|
| FUL-INT-001 | Sales | Order Fulfilment | Inbound command | Released order header, lines, quantities, delivery context, and channel. | Fulfilment release. | Reject invalid or ineligible release data without creating partial state. |
| FUL-INT-002 | Order Fulfilment | Sales | Outbound update | Fulfilment status, quantities, backorder, shipment/tracking references, and business exceptions. | Task status changes. | Sales validates the order identity and resulting status change. |
| FUL-INT-003 | Order Fulfilment | Inventory Management | Outbound command/query | Availability validation, reservation, consumption, reversal, task IDs, and Sales order IDs. | Release, pick, completion, reversal. | Inventory Management rejects invalid order, task, location, reference, or quantity data. |
| FUL-INT-004 | Order Fulfilment | Courier Service | Bidirectional | Accepted shipment purchase, label, tracking, and provider business references. | Shipping purchase. | Order Fulfilment validates the referenced task before storing accepted provider references. |
| FUL-INT-005 | Application APIs | Order Fulfilment | Inbound command/query | Pick, pack, ship, label, complete, exception, approval, and search requests. | User actions. | Domain validation/authorization errors returned without partial lifecycle changes. |

## 11. Reporting and Query Requirements

| Report / Query | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Fulfilment Task Queue | Operators, Supervisors | Prioritize released work. | Status, age, channel, SKU, priority, operator. | CSV optional for workload review. |
| Exception Queue | Fulfilment Supervisor | Resolve pick, pack, ship, label, completion, and cancellation issues. | Exception type, age, SKU, courier, operator, sales order. | CSV for supervisor review. |
| Shipment and Label References | Fulfilment Supervisor | Trace courier purchases and labels. | Courier, tracking, date, order, status. | CSV for operational review. |
| Partial Fulfilment/Backorder Report | Sales, Fulfilment Supervisor | Track remaining quantities. | Customer, order, SKU, date, status. | CSV optional. |
| Completion History | Fulfilment Supervisor | Review completed or reversed tasks. | Date, actor, order, SKU, exception, approval. | CSV for operational review. |

## 12. Security, Authorization, and Approval Controls

Order Fulfilment shall enforce authorization for task intake, assignment, pick, pack, shipping purchase, label reference, completion, partial fulfilment, exception approval, cancellation, reversal, reporting, and export. Application screen checks are not authoritative.

Fulfilment Supervisor approval is required for short pick, substitution, partial fulfilment, shipping override, cancellation after picking starts, and completion reversal. The operator who records an exception or requests reversal shall not approve the related controlled action. Courier and service integrations shall use scoped service identities.

## 13. Operational History and Traceability

Order Fulfilment shall record operational history for release intake, task creation, assignment changes, pick/pack actions, business exceptions, supervisor decisions, accepted shipment purchases, label references, completion, partial fulfilment, cancellation, reversal, accepted Sales and Inventory updates, and authorization denials.

Operational history records shall include actor/service, source application/domain, task and sales order IDs, prior/new state, quantities where relevant, reason/comments, provider transaction references where applicable, outcome, and timestamp.

## 14. Non-Functional Requirements

- Task queue queries shall support pagination and stable sorting by status, age, and priority-related fields.
- Label references and courier transaction details shall be retrievable for operational review.
- The Fulfilment API shall remain independent of application UI projects and application-owned persistence.

## 15. Dependencies

- Sales for released order contracts and accepted customer-visible status updates.
- Inventory Management for product/component validation, reservation, consumption, reversal, and stock exception state.
- Courier service for accepted MVP shipment purchase, label references, and tracking.
- Gravitee and Authentik for authenticated ingress and service identity.

## 16. Assumptions and MVP Defaults

- Royal Mail is the default MVP courier provider.
- MVP supports one standard courier service level, PDF/browser label output, and no rate shopping or courier contract management.
- Inventory is reserved at Sales release and consumed at fulfilment completion.
- Label file storage and print dialog behavior are implementation/application concerns; the domain owns references and evidence.
- Returns/RMA, failed delivery processing, refunds, and finance postings are deferred.
- Fulfilment task queues use status and age as the default ordering inputs.
- Partial fulfilment requires Fulfilment Supervisor approval and does not require customer confirmation in MVP.
- Courier label references and shipment history are retained according to Order Fulfilment-owned operational data policy; no central compliance-retention baseline applies in MVP.

## 17. Acceptance Summary

The Order Fulfilment requirements are complete for MVP when they define authoritative fulfilment state ownership, release intake, pick/pack/ship/completion workflows, Inventory and Sales integrations, courier references, supervisor approvals, operational history, reporting needs, and explicit MVP defaults without assigning UI workflows or durable fulfilment state to application services.
