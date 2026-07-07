# Application Requirements: Fulfilment Operator

## 1. Purpose

The Fulfilment Operator application supports warehouse fulfilment users who view released orders, identify required components, pick, pack, request courier shipping where authorized, print labels, and complete or partially fulfil orders.

The MVP outcome is a task-focused fulfilment application that guides operators through Order Fulfilment workflows while surfacing Sales and Inventory context without owning durable fulfilment, sales, or inventory state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.FulfilmentOperator.Ui` |
| API | `Acme.Erp.FulfilmentOperator.Api` |
| Primary users | Fulfilment Operator |
| Database | None |
| Domain APIs consumed | Order Fulfilment, Sales, Inventory Management |

The Fulfilment Operator UI calls only the Fulfilment Operator API. The Fulfilment Operator API owns no durable business state, uses no EF Core migrations, and does not connect to SQL Server.

## 3. User-Facing Scope

### In Scope

- Released fulfilment task queue, task detail, and required order/component context.
- Product, SKU, serial where applicable, quantity, availability/reservation context, and pick validation display.
- Picked component capture, pack confirmation, shipping purchase request, label print action, completion, and partial fulfilment actions through Order Fulfilment.
- Pick exception, damaged component, short pick, shipping purchase failure, label failure, and inventory consumption exception presentation.
- Supervisor route for controlled exceptions, completion reversal, cancellation after picking starts, and override approval.
- Accessible task entry and review screens suitable for keyboard/scanner-assisted operation.

### Out of Scope

- Durable fulfilment, sales, or inventory state; direct SQL access; EF Core migrations.
- Sales order creation, customer account maintenance, stock balance mutation, regular stock counts, goods receipts, PO authoring, courier contract management, and approval of controlled exceptions.

## 4. Business Context

Fulfilment operators need a clear operational workflow for moving released orders through pick, pack, ship, label, and completion steps. The application must guide tasks and show domain feedback while Order Fulfilment remains authoritative for lifecycle and Inventory remains authoritative for stock.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Fulfilment Operator | Warehouse user executing fulfilment tasks. | Pick, pack, ship, print labels, complete tasks, record exceptions. | Task queue, scanner/keyboard entry, clear next action, exception prompts. |
| Fulfilment Supervisor | Escalation role outside this primary app. | Approve exceptions and reversals in supervisor app. | Routed links/status only. |

## 6. User Journeys and Workflows

- **Open task**: operator selects a released task and reviews product, quantity, reservation, delivery context, and current state.
- **Pick**: operator scans/selects products/SKUs/serials, enters picked quantities, and submits pick confirmation or exception.
- **Pack**: operator confirms packing after pick validation succeeds or approved exception exists.
- **Ship and label**: operator requests courier shipping purchase where authorized, sees provider response, and prints/downloads label reference returned by Order Fulfilment.
- **Complete**: operator completes full or partial fulfilment; Order Fulfilment coordinates Inventory consumption and Sales update.
- **Escalate exception**: operator records issue and routes to Fulfilment Supervisor when approval is required.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| FOP-APP-001 | Task queue | The application shall display released fulfilment tasks from Order Fulfilment with status, age, order reference, and priority/context fields available from the domain. | Must | Given authorized operator access, when the queue loads, then tasks are paginated and filterable without local persistence. |
| FOP-APP-002 | Task detail | The application shall show component requirements and Inventory validation data without storing sales or inventory state locally. | Must | Given a task is opened, when data is loaded, then required products/SKUs/quantities and reservation/availability context are displayed. |
| FOP-APP-003 | Pick capture | The application shall allow operators to record picked components through Order Fulfilment. | Must | Given picked data matches requirements, when submitted, then Order Fulfilment advances the task; mismatches return exception state. |
| FOP-APP-004 | Pack/ship/label | The application shall allow authorized operators to pack orders, request courier shipping purchase, and print labels using Order Fulfilment responses. | Must | Given shipping purchase succeeds, when the operator opens label action, then the label reference is available for printing; provider failure shows retry/escalation. |
| FOP-APP-005 | Completion | The application shall allow authorized operators to complete or partially fulfil tasks through Order Fulfilment. | Must | Given completion succeeds, when Order Fulfilment updates Sales and Inventory, then the UI shows completed/partial status; downstream failure shows completion exception. |
| FOP-APP-006 | Exception routing | The application shall route exception approval, completion reversal, and cancellation-after-picking approval to supervisor applications. | Must | Given controlled exception exists, when viewed by operator, then approval controls are not available and supervisor-required state is shown. |
| FOP-APP-007 | Accessibility/scanner use | The application shall provide accessible fulfilment task screens suitable for keyboard and scanner-assisted operation. | Must | Given scanner or keyboard input, when pick fields are used, then focus and validation behave predictably. |

## 8. UI, Accessibility, and Usability Requirements

- Task queue shall prioritize actionable tasks and clearly show blocked/exception states.
- Pick forms shall support fast scan/enter flows and show remaining quantity without layout shift.
- Shipping and label actions shall show provider status, retry availability, and exception route.
- Customer delivery context shall be displayed only when required for fulfilment and allowed by local access rules.
- Screens shall target WCAG 2.2 AA, with clear focus, labels, and error summaries.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Fulfilment task | Order Fulfilment | Queue/detail workflow. | Yes | Show current state and allowed next actions. |
| Sales order reference/delivery context | Sales/Order Fulfilment | Task context. | Conditional | Display minimum necessary customer data. |
| Product/SKU/serial | Inventory Management/Order Fulfilment | Pick validation. | Yes | Show mismatch/unknown/serial-required errors. |
| Picked quantity | User input to Order Fulfilment | Pick step. | Yes | Non-negative and no more than required unless exception. |
| Shipment/label reference | Order Fulfilment/courier | Ship and print. | Conditional | Show provider failure and retry state. |
| Completion status | Order Fulfilment | Workflow outcome. | Yes | Show partial/backorder/exception state. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| FOP-INT-001 | Load task queue | Order Fulfilment | Filters, status, paging. | Show unavailable queue state. | Correlate request. |
| FOP-INT-002 | Record pick | Order Fulfilment | Task line, product/SKU/serial, quantity. | Show pick exception returned by domain. | Idempotency key for submit. |
| FOP-INT-003 | Pack task | Order Fulfilment | Pack confirmation, task ID. | Show invalid-state or exception response. | Correlate command. |
| FOP-INT-004 | Request shipping | Order Fulfilment | Shipment request data. | Show provider failure and retry/escalation. | Idempotency key for shipping request. |
| FOP-INT-005 | Print label | Order Fulfilment | Label reference request. | Show label unavailable/failure state. | Correlate request. |
| FOP-INT-006 | Complete task | Order Fulfilment | Completion/partial completion data. | Show Inventory/Sales downstream exception. | Idempotency key for completion. |

## 11. Reporting, Search, and Dashboard Requirements

| View / Report | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Released Task Queue | Fulfilment Operator | Select work. | Status, age, SKU, order, channel. | None for MVP. |
| My In-Progress Tasks | Fulfilment Operator | Resume work. | Operator, status, age. | None. |
| Task Exceptions | Fulfilment Operator | Track escalations. | Exception type, task, status, age. | Supervisor/reporting apps handle export. |
| Recent Completions | Fulfilment Operator | Confirm submitted work. | Date, task, order, status. | None. |

## 12. Security and Permissions

The application shall enforce Fulfilment Operator route and screen access. Order Fulfilment remains authoritative for task lifecycle, allowed actions, exception approval needs, courier records, label references, and operational history. Inventory remains authoritative for stock reservations/consumption. The app shall not expose supervisor-only approvals.

## 13. Operational History and Traceability

The application shall pass operator identity, source app, correlation ID, and command context to Order Fulfilment. Operators may view task history relevant to their workflow, while broader CSV outputs belong to supervisor workflows.

## 14. Non-Functional Requirements

- Queue and task screens shall load paged data and make stale/unavailable states visible.
- Submission actions shall use idempotency keys where duplicate mutation is possible.
- The application shall propagate correlation IDs to Order Fulfilment, Sales, and Inventory calls.
- The app shall not cache task data beyond request/session needs.
- Validation and exception messages shall explain the next operational action.

## 15. Dependencies

- Order Fulfilment for task lifecycle, shipping, labels, completion, exceptions, and operational history.
- Sales for released order/customer delivery context and status synchronization through fulfilment contracts.
- Inventory Management for product validation, reservations, consumption, and stock exceptions.
- Authentik and Gravitee for identity, ingress, role claims, route policy, and correlation metadata.

## 16. Assumptions and MVP Defaults

- Fulfilment Operator users are internal authenticated warehouse users.
- MVP supports one courier provider path through Order Fulfilment.
- Supervisor approvals occur in Fulfilment Supervisor, not this application.
- Label file storage is domain/infrastructure-owned; this app presents and triggers print/download from the provided reference.
- MVP pick capture supports product/SKU/barcode and serial number entry only where Inventory marks the product as serialized.
- Operators may view recipient name, delivery address, order reference, and delivery instructions only; wider customer account data is not shown.
- Shipping uses the default service level configured in Order Fulfilment; operators do not choose shipping services in MVP.

## 17. Acceptance Summary

The Fulfilment Operator requirements are complete for MVP when they define task queue, pick, pack, ship, label, completion, partial fulfilment, exception routing, scanner/accessibility needs, security, operational history context, and explicit MVP defaults without assigning fulfilment, sales, or inventory state to the application.
