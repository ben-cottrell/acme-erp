# Application Requirements: Fulfilment Operator

## 1. Purpose

The Fulfilment Operator application shall support warehouse fulfilment users who select released tasks, pick exact released quantities, confirm packing, purchase courier shipping, print labels, and complete tasks in full.

The MVP outcome is a task-focused workflow over Order Fulfilment, Sales, and Inventory Management without application-owned durable state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.FulfilmentOperator.Ui` |
| API | `Acme.Erp.FulfilmentOperator.Api` |
| Primary users | Fulfilment Operator |
| Database | None |
| Domain APIs consumed | Order Fulfilment, Sales, Inventory Management |

The Fulfilment Operator UI shall call only the Fulfilment Operator API. The Fulfilment Operator API shall own no database, EF Core migrations, durable business state, or domain invariants.

## 3. User-Facing Scope

### In Scope

- Released fulfilment task worklist and task detail.
- Display of order reference, permitted delivery context, required products, quantities, reservation context, and allowed next actions.
- Scanner-assisted product, SKU, barcode, and serial capture where the product requires serial tracking.
- Exact-quantity pick submission, pack confirmation, courier shipping purchase, label retrieval and print action, and full task completion through Order Fulfilment.
- In-progress task views, pagination, input validation, and recoverable courier or domain technical error handling.

### Out of Scope

- Durable fulfilment, sales, or inventory state, direct database access, or EF Core migrations.
- Sales order creation, customer maintenance, stock count, goods receipt, purchase order authoring, courier contract maintenance, or direct stock mutation.
- Returns, warehouse automation hardware integration, and finance posting.

## 4. Business Context

Fulfilment users need a clear operational path from released order to completed shipment. Order Fulfilment remains authoritative for task lifecycle, courier shipment purchase records, labels, and completion. Inventory Management remains authoritative for products, reservations, and stock consumption, while Sales remains authoritative for released order and permitted delivery context.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Fulfilment Operator | Authenticated warehouse user executing fulfilment tasks. | Select tasks, scan and pick exact released quantities, pack, request shipping, print labels, and complete work in full. | Stable task views, predictable scanner flow, clear required and captured quantities, and concise action results. |

## 6. User Journeys and Workflows

### 6.1 Select a Released Task

The operator filters the released task worklist, opens one task, and reviews the order reference, delivery context, required products, quantities, and current allowed actions. The journey ends with the task ready for its next domain action.

### 6.2 Pick Exact Released Quantities

The operator scans or enters each product and serial where required and may edit or remove unsent entries. The application allows pick confirmation only when every line exactly matches its released required quantity and required serials are present. The journey ends with Picked status and the updated task version, or with retained input and correctable line-level validation messages.

### 6.3 Pack and Ship

When Order Fulfilment exposes packing, the operator confirms packing and requests the configured courier service. The journey ends with shipment, tracking, and label references, or with a retryable technical result while the accepted task state remains authoritative.

### 6.4 Print a Label

The operator opens the label reference returned by Order Fulfilment and triggers browser printing or download. Printing does not change task state unless Order Fulfilment explicitly records a print action.

### 6.5 Complete Fulfilment

The operator submits completion for a Label Ready task. The journey ends with Completed status only after Order Fulfilment confirms exact Inventory consumption and the accepted Sales completion update.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| FOP-APP-001 | Released worklist | The system shall display released fulfilment tasks available to the Fulfilment Operator. | Must | Given supported filters, when the worklist loads, then tasks shall be paginated and show task ID, order reference, age, channel, and current state. |
| FOP-APP-002 | Task detail | The system shall display required products, exact released quantities, reservation context, delivery data, and current lifecycle actions returned by the domains. | Must | Given a task is opened, when composed data loads, then each section shall identify its source result and no data shall be persisted locally. |
| FOP-APP-003 | Scanner capture | The system shall support product, SKU, barcode, and required serial entry by scanner or keyboard. | Must | Given a focused pick field and keyboard-wedge scan ending in Enter or Tab, when the value is received, then validation shall run and focus shall advance predictably. |
| FOP-APP-004 | Pick form editing | The system shall allow the operator to add, edit, or remove unsent product, quantity, location, and serial entries for the active task. | Must | Given an active pick form, when the operator corrects an entry before confirmation, then the updated values shall remain available for validation without changing durable fulfilment state. |
| FOP-APP-005 | Exact pick confirmation | The system shall submit a pick confirmation only when every captured line exactly matches its released required quantity and required serials. | Must | Given all captured lines and serials match the released task exactly, when submitted once, then the UI shall display Picked status and the updated task version; otherwise the form shall retain entries and display line-level validation errors. |
| FOP-APP-006 | Pack confirmation | The system shall expose packing only when Order Fulfilment reports the task as Picked. | Must | Given a Picked task and valid package data, when the operator confirms packing, then the UI shall display Packed status and the updated version. |
| FOP-APP-007 | Shipping purchase | The system shall request the configured courier shipment through Order Fulfilment. | Must | Given a Packed task and valid delivery data, when requested once, then the UI shall display the shipment and tracking references returned by Order Fulfilment. |
| FOP-APP-008 | Label action | The system shall retrieve and present the current label reference from Order Fulfilment. | Must | Given a shipment with a label reference, when the operator selects print or download, then the referenced label shall open without copying label storage into the application. |
| FOP-APP-009 | Full completion | The system shall submit completion only for a Label Ready task using its current version. | Must | Given a Label Ready task and current version, when completion is submitted once, then the UI shall display Completed only after Order Fulfilment confirms exact Inventory consumption and the accepted Sales update. |
| FOP-APP-010 | In-progress work | The system shall provide a paginated view of tasks currently assigned to the operator. | Must | Given the operator opens in-progress work, then only tasks returned within the user's scope shall be shown with stable sorting. |

## 8. UI and Usability Requirements

- Task and pick controls shall have stable dimensions and remain usable on shared workstation and handheld-width browser screens.
- Product and serial fields shall accept keyboard-wedge scanner input ending in Enter or Tab.
- A scan shall not submit the complete pick unless the final confirmation control has focus.
- Pick rows shall display released required and currently captured quantities without layout shift.
- Forms shall preserve unsent entries after validation, authorization, conflict, timeout, or dependency failure responses.
- Validation messages shall appear beside affected fields and action-level messages in a stable summary region.
- Shipping and label views shall display shipment, tracking, and label references distinctly.
- Exact pick confirmation and task completion shall each require an explicit final action.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Fulfilment task external ID and version | Order Fulfilment | All task actions | Yes | Not editable; refresh after version conflict. |
| Sales order reference and delivery context | Sales and Order Fulfilment | Task identification and shipping | Conditional | Display only recipient name, delivery address, instructions, and order reference permitted for fulfilment. |
| Product external ID, SKU, and barcode | Inventory Management and Order Fulfilment | Pick identification | Yes | Display recognized product and required quantity. |
| Serial number | Inventory Management and Order Fulfilment | Serialized product tracking | Conditional | Required only where the product is marked serialized; prevent duplicate serial entry in the active task. |
| Captured pick quantity | User input to Order Fulfilment | Exact pick confirmation | Yes | Positive and exactly equal to the released required quantity at confirmation. |
| Shipment and tracking references | Order Fulfilment | Shipping confirmation | Conditional | Display exactly as returned by the domain. |
| Label reference | Order Fulfilment | Print or download | Conditional | Treat as a reference to domain or infrastructure-owned content. |
| Completion status and timestamp | Order Fulfilment | Completion confirmation | Yes after completion | Display Completed only with the completion timestamp returned by Order Fulfilment. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| FOP-INT-001 | Load worklist or task | Order Fulfilment, with permitted Sales and Inventory Management reads | Filters, paging, task ID, order and product external IDs | Identify unavailable sections and permit retry; do not display missing data as zero. | Propagate one correlation ID across the composed read. |
| FOP-INT-002 | Validate pick entries | Order Fulfilment | Task ID, product, SKU, barcode, location, serial, quantity, and operator context | Retain input, map validation to rows, and identify temporary validation failures. | Propagate the active task correlation ID. |
| FOP-INT-003 | Confirm exact pick | Order Fulfilment | Task ID, version, exact products, locations, serials, quantities, and operator context | Retain input, map validation to rows, refresh after version conflict, and query uncertain outcomes before resubmission. | Send one idempotency key per pick confirmation and an end-to-end correlation ID. |
| FOP-INT-004 | Confirm packing | Order Fulfilment | Task ID, version, package data, and pack confirmation | Query uncertain outcomes before enabling another confirmation. | Send one idempotency key and correlation ID. |
| FOP-INT-005 | Purchase shipping | Order Fulfilment | Task ID, version, and configured service request | Distinguish courier rejection from timeout; query shipment state before retry. | Send one idempotency key that Order Fulfilment propagates to the courier integration. |
| FOP-INT-006 | Retrieve label | Order Fulfilment | Task ID and label reference | Preserve shipment state and permit retrieval retry without repurchasing shipping. | Propagate the request correlation ID. |
| FOP-INT-007 | Complete task | Order Fulfilment | Task ID and current version | Query uncertain outcomes before resubmission and display only the state returned by Order Fulfilment. | Send one idempotency key and end-to-end correlation ID. |

The paired API shall use bounded timeouts. Safe reads may be retried automatically. Mutation retries shall reuse the original idempotency key. Cross-service references shall use external IDs.

## 11. Operational View and Search Requirements

| View | Audience | Purpose | Filters |
|---|---|---|---|
| Released Task Worklist | Fulfilment Operator | Select new work | Task state, age, SKU, order, channel |
| My In-Progress Tasks | Fulfilment Operator | Resume assigned work | Task state, started date, SKU, order |
| Recently Completed Tasks | Fulfilment Operator | Confirm recent outcomes | Completion date, order, shipment reference, task ID |

Worklists shall use deterministic sorting and pagination. Recently Completed Tasks shall be assembled from Order Fulfilment queries and shall not be stored by the application. The MVP shall not provide scheduled reports or data exports.

## 12. Security and Permissions

- Authentik shall authenticate users and Gravitee shall enforce ingress policy.
- The UI and paired API shall require the Fulfilment Operator role for every route and action.
- The paired API shall forward user identity and correlation context to domain APIs.
- Order Fulfilment shall remain authoritative for task scope, allowed actions, lifecycle, courier records, label references, validation, and persistence.
- Sales shall remain authoritative for released order and permitted delivery context; Inventory Management shall remain authoritative for product, serial, reservation, and stock-consumption data.
- Logs shall exclude tokens, delivery addresses, recipient names, and label content.

## 13. Non-Functional Requirements

- **Performance:** Worklists shall be paginated, and scan validation shall provide an in-progress state without unexpected focus movement.
- **Reliability:** The application shall remain stateless beyond normal authenticated session and request context and shall not store labels or local task drafts.
- **Consistency:** Task mutations shall use domain versions and uncertain outcomes shall be queried before resubmission.
- **Observability:** Requests shall carry correlation IDs; metrics shall identify route, dependency, courier outcome class, and duration without personal data.
- **Availability:** Courier unavailability shall not prevent viewing or retaining the current packed task; shipping shall show a retryable technical result.
- **Maintainability:** Versioned domain clients and scanner workflows shall be covered by contract and UI tests.
- **Localization:** MVP dates and numbers shall use the ACME deployment locale; multiple locales are not required.
- **Supportability:** Unexpected technical errors shall display a support reference derived from the correlation ID.

## 14. Errors and Edge Cases

- Duplicate clicks or network retries shall not repeat exact pick confirmation, packing, shipping, or completion mutations for one idempotency key.
- A stale task version shall require refresh before another mutation.
- An unknown product, duplicate serial, or quantity rejected by domain validation shall block submission while retaining other valid entries.
- A courier timeout shall trigger shipment-state lookup before another shipping request is available.
- Label retrieval failure shall not purchase another shipment or alter task state.
- If Sales or Inventory Management detail is unavailable, Order Fulfilment task data may remain visible, but actions requiring the missing data shall be disabled with a technical reason.

## 15. Dependencies

- Order Fulfilment for task lifecycle, exact pick confirmation, packing, courier shipping, labels, full completion, validation, and persistence.
- Sales for released order reference, permitted delivery context, and fulfilment status coordination.
- Inventory Management for product, barcode, serial, reservation, and accepted stock-consumption references.
- Authentik and Gravitee for identity, claims, ingress, and route policy.
- One configured courier path, keyboard-wedge barcode scanners, and versioned API contracts using external IDs.

## 16. Assumptions

- The application is available only to authenticated Fulfilment Operator users.
- MVP supports one courier provider path and one default shipping service configured in Order Fulfilment.
- Operators may view recipient name, delivery address, delivery instructions, and order reference only.
- Label files remain domain or infrastructure owned; the application presents the returned reference.
- Scanner support targets keyboard-wedge devices that emit text followed by Enter or Tab.
- Serial entry is required only when Inventory Management marks the product serialized.
- Every task uses the exact quantities released by Sales and completes as one full task.
- Worklists use a default page size of 50 and oldest released task first for new work.

## 17. Open Questions

None. The remaining courier, device, and contract details can use the stated MVP defaults and owning-domain rules.

## 18. Acceptance Summary

The Fulfilment Operator MVP is complete when an authenticated operator can select released work, edit unsent pick entries, confirm exact released quantities, confirm packing, purchase one courier shipment, retrieve and print its label, complete the task in full, and review recent outcomes. Mutations must be idempotent, technical failures recoverable, and all durable state and business validation domain-owned.
