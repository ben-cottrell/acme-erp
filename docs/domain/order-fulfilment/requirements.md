# Domain Requirements: Order Fulfilment

## 1. Purpose

The Order Fulfilment bounded context owns durable fulfilment task state, pick/pack/ship/completion rules, courier shipment purchase records, label references, fulfilment exceptions, fulfilment status history, and fulfilment operational history records.

Order Fulfilment exposes WebAPI contracts and owns the Fulfilment database. It is authoritative for fulfilment task lifecycle, fulfilment authorization, courier transaction references, exception approval, completion decisions, idempotency, and fulfilment operational history. Fulfilment operator, supervisor, sales visibility, and reporting screens are owned by application services.

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

- **Fulfilment intake** starts when Sales sends a released order contract. It ends with a fulfilment task created, duplicate release recognized, release rejected, or intake exception recorded.
- **Pick workflow** starts when an operator begins a task. It ends with required quantities picked, short pick/substitution/damage exception raised, or task returned to queue.
- **Pack and ship workflow** starts after pick validation. It ends with packing confirmed, courier shipping purchased, label reference stored, or shipping exception recorded.
- **Completion workflow** starts after pick, pack, shipping, and label conditions are met or an approved manual exception exists. It ends with Inventory consumption, Sales status update, partial fulfilment/backorder, or completion exception.
- **Exception workflow** starts when validation, stock, courier, label, cancellation, or reversal issue occurs. It ends with supervisor approval, rejection, retry, cancellation, or recovery.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| FUL-DOM-001 | Intake | The system shall create fulfilment tasks only from Sales-released order contracts that include order identifiers, lines, quantities, delivery context, correlation ID, and idempotency key. | Must | Given a valid release, when Order Fulfilment accepts it, then a task is created once; given a duplicate release with the same key, then the original task reference is returned. |
| FUL-DOM-002 | Task lifecycle | The system shall maintain explicit fulfilment task states from Released through Picking, Picked, Packing, Packed, Shipping Purchased, Label Printed, Partially Fulfilled, Completed, Cancelled, and Exception. | Must | Given a transition request, when the transition is invalid for the current state, then the system rejects it and records no state change. |
| FUL-DOM-003 | Pick validation | The system shall validate picked products, SKUs, serials where applicable, and quantities against released order requirements and Inventory data. | Must | Given picked quantities match requirements, when pick is confirmed, then the task can progress to packing; given mismatch or damage, then a pick exception is recorded. |
| FUL-DOM-004 | Exception approvals | The system shall require Fulfilment Supervisor approval for short picks, substitutions, partial fulfilment release, shipping overrides, cancellation after picking starts, and completion reversals. | Must | Given an operator records an exception, when the same operator attempts approval, then the approval is denied by the local self-approval rule. |
| FUL-DOM-005 | Courier shipment | The system shall record courier shipment purchase request, result, label reference, tracking reference, and courier exception state for the MVP provider path. | Must | Given shipping purchase succeeds, when the provider response is received, then shipment and label references are stored; given failure, then a shipping exception is visible and retryable. |
| FUL-DOM-006 | Completion | The system shall complete a fulfilment task only when required pick, pack, shipping purchase, label, Sales update, and Inventory consumption conditions are satisfied or an approved exception exists. | Must | Given required conditions pass, when completion is requested, then Inventory consumption is recorded and Sales is updated; given a downstream failure, then completion exception state is preserved. |
| FUL-DOM-007 | Partial fulfilment | The system shall support partial fulfilment where approved and report remaining quantities to Sales as backordered. | Must | Given a supervisor approves partial fulfilment, when completion occurs for available quantities, then Sales receives fulfilled and backordered quantities. |
| FUL-DOM-008 | Inventory coordination | The system shall request Inventory reservation, consumption, and reversal using external IDs, correlation IDs, and idempotency keys. | Must | Given a fulfilment command is retried, when Inventory receives the same idempotency key, then duplicate consumption or reversal is not created. |
| FUL-DOM-009 | Fulfilment queries | The system shall expose query contracts for task queues, exceptions, shipment references, completion history, and operational reporting. | Should | Given an authorized query, when filters are supplied, then results are role-scoped and include stale integration indicators where applicable. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| FUL-BR-001 | Fulfilment begins only for orders released by Sales. | Intake | Order Fulfilment API | Sales owns release decision. |
| FUL-BR-002 | Picked components must match released order requirements unless a controlled exception is approved. | Picking | Pick validation | Product master remains Inventory-owned. |
| FUL-BR-003 | Courier shipping must be purchased before a courier label is printed unless a manual exception is authorized. | Shipping | Shipping workflow | MVP supports one provider path. |
| FUL-BR-004 | Orders cannot be completed until pick, pack, shipping, label, Sales, and Inventory conditions are satisfied or queued with visible exception state. | Completion | Completion workflow | No hidden success on partial failure. |
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
| Packed | Shipping Purchase Pending, Exception | Shipping requested | Shipping may be skipped only by approved manual exception. |
| Shipping Purchase Pending | Shipping Purchased, Exception | Courier response | Retryable provider failure. |
| Shipping Purchased | Label Printed, Exception | Label generated/stored | Label reference required unless approved exception. |
| Label Printed | Completed, Partially Fulfilled, Exception | Completion request | Inventory consumption and Sales update required. |
| Partially Fulfilled | Completed, Exception | Remaining fulfilment or correction | Backorder reported to Sales. |
| Completed | Exception | Correction/reversal | Terminal for normal path. |
| Cancelled | Exception | Approved cancellation | Terminal unless correction is approved. |
| Exception | Prior recoverable state, Cancelled | Retry, supervisor decision, correction | Recovery path depends on prior state. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Fulfilment Task | Order Fulfilment | Yes | Unique task ID, status, source sales order, timestamps, assigned/acting user where applicable. | Sales order external ID. |
| Fulfilment Task Line | Order Fulfilment | Yes | Product/SKU reference, required quantity, picked quantity, exception state. | Inventory product/SKU external IDs. |
| Shipment Purchase Record | Order Fulfilment | Conditional | Courier, request/result, amount if returned, tracking, label reference, error state. | Courier transaction ID. |
| Label Reference | Order Fulfilment | Conditional | Stored reference or provider label ID; printable file storage is implementation-specific. | Courier provider. |
| Reservation/Consumption Reference | Inventory Management | Conditional | External IDs only; Inventory owns stock mutation. | Inventory reservation/movement IDs. |
| Fulfilment Activity History | Order Fulfilment | Yes | Actor/service, action, prior/new state, outcome, timestamp, correlation ID. | Order Fulfilment-owned operational history. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Failure Handling |
|---|---|---|---|---|---|---|
| FUL-INT-001 | Sales | Order Fulfilment | Inbound command | Released order header, lines, quantities, delivery context, channel, correlation ID, idempotency key. | Fulfilment release. | Reject invalid payloads; return existing task for duplicate release. |
| FUL-INT-002 | Order Fulfilment | Sales | Outbound update | Fulfilment status, quantities, backorder, shipment/tracking references, exceptions. | Task status changes. | Retry idempotently; preserve pending Sales update exception. |
| FUL-INT-003 | Order Fulfilment | Inventory Management | Outbound command/query | Availability validation, reservation, consumption, reversal, task and sales IDs. | Release, pick, completion, reversal. | Surface stock exception and block hidden completion. |
| FUL-INT-004 | Order Fulfilment | Courier Service | Bidirectional | Shipment purchase request/result, label data/reference, tracking, error details. | Shipping purchase. | Retry where safe; record provider failure and require recovery/override. |
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

Fulfilment Supervisor approval is required for short pick, substitution, partial fulfilment, shipping override, cancellation after picking starts, and completion reversal. The operator who records an exception or requests reversal shall not approve the related controlled action. Courier and service integrations shall use scoped service identities and correlation metadata.

## 13. Operational History and Traceability

Order Fulfilment shall record operational history for release intake, task creation, assignment changes, pick/pack actions, exceptions, supervisor decisions, shipping purchase requests/results, label references, completion, partial fulfilment, cancellation, reversal, Sales updates, Inventory consumption/reversal requests, and authorization denials.

Operational history records shall include actor/service, source application/domain, task and sales order IDs, prior/new state, quantities where relevant, reason/comments, provider transaction references where applicable, outcome, timestamp, correlation ID, and idempotency key.

## 14. Non-Functional Requirements

- Fulfilment release, Sales update, Inventory mutation, and courier purchase operations shall be correlated and idempotent where retries are possible.
- Task queue queries shall support pagination and stable sorting by status, age, and priority-related fields.
- Provider failures shall be observable through structured logs, metrics, health checks, and exception queues.
- Completion shall not infer success for failed Sales or Inventory updates; visible exception state is required.
- Label references and courier transaction details shall be retrievable for operational review.
- The Fulfilment API shall remain independent of application UI projects and application-owned persistence.

## 15. Dependencies

- Sales for released order contracts and customer-visible status synchronization.
- Inventory Management for product/component validation, reservation, consumption, reversal, and stock exception state.
- Courier service for MVP shipment purchase, label references, tracking, and provider errors.
- Gravitee and Authentik for authenticated ingress, service identity, and correlation metadata.

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
