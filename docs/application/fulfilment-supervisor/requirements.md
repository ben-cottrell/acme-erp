# Application Requirements: Fulfilment Supervisor

## 1. Purpose

The Fulfilment Supervisor application supports fulfilment control users who monitor workload, resolve pick/pack/ship/completion exceptions, approve controlled overrides, review partial fulfilment, and oversee completion reversals or cancellations after picking starts.

The MVP outcome is a supervisory control application that gives fulfilment leaders enough Sales, Inventory, and fulfilment context to make decisions while Order Fulfilment remains authoritative for lifecycle, approvals, and operational history.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.FulfilmentSupervisor.Ui` |
| API | `Acme.Erp.FulfilmentSupervisor.Api` |
| Primary users | Fulfilment Supervisor |
| Database | None |
| Domain APIs consumed | Order Fulfilment, Sales, Inventory Management |

The Fulfilment Supervisor UI calls only the Fulfilment Supervisor API. The Fulfilment Supervisor API owns no durable business state, uses no EF Core migrations, and does not connect to SQL Server.

## 3. User-Facing Scope

### In Scope

- Fulfilment workload and exception queues by status, age, SKU, channel, operator, and exception type.
- Review of pick exceptions, short picks, substitutions, damaged components, shipping overrides, label failures, completion exceptions, and inventory consumption failures.
- Approval/rejection of controlled fulfilment exceptions through Order Fulfilment.
- Review of partial fulfilment/backorder proposals and cancellation after picking starts.
- Read-only Sales order/customer delivery context and Inventory reservation/consumption context where needed and allowed.
- Operational reports, CSV exports, accessible supervisor review screens, and operational history visibility.

### Out of Scope

- Durable fulfilment, sales, or inventory state; direct SQL access; EF Core migrations.
- Operator task execution, label printing as an operator workflow, sales order authoring, stock balance mutation, PO authoring, courier contract management, returns/RMA, and finance postings.

## 4. Business Context

Fulfilment supervisors need a control surface for resolving blocked warehouse work and preventing unapproved changes to customer orders, stock, and courier activity. The application must present cross-domain context while letting Order Fulfilment enforce approval, self-approval checks, and lifecycle state.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Fulfilment Supervisor | Fulfilment control user. | Monitor queues, approve/reject exceptions, review partial fulfilment and reversals. | Exception dashboard, decision context, operational history, filters, CSV export. |

## 6. User Journeys and Workflows

- **Monitor workload**: supervisor opens dashboard and reviews released, in-progress, blocked, aging, and completed fulfilment work.
- **Review pick exception**: supervisor opens exception, reviews required/picked quantities, product/SKU/serial context, operator reason, Inventory state, and Sales impact.
- **Approve partial fulfilment**: supervisor reviews remaining quantities and customer/order impact before approving partial completion/backorder.
- **Resolve shipping/label issue**: supervisor reviews provider error, previous attempts, available override/retry actions, and approves or rejects exception.
- **Approve cancellation/reversal**: supervisor reviews task progress, stock effects, Sales state, and business reason before submitting decision to Order Fulfilment.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| FSU-APP-001 | Workload dashboard | The application shall display fulfilment workload and exception queues from Order Fulfilment. | Must | Given authorized supervisor access, when the dashboard loads, then queues show status, age, exception type, SKU, operator, and task/order references. |
| FSU-APP-002 | Context display | The application shall show Sales and Inventory Management context needed for exception decisions without local persistence. | Must | Given an exception references Sales or Inventory context, when opened, then the UI displays available read-only context or marks it stale/unavailable. |
| FSU-APP-003 | Exception decisions | The application shall allow authorized supervisors to approve or reject pick exceptions, short picks, substitutions, partial fulfilment release, shipping overrides, cancellation after picking starts, and completion reversals through Order Fulfilment. | Must | Given a valid decision, when submitted, then Order Fulfilment records the outcome; invalid state or self-approval denial is shown. |
| FSU-APP-004 | Self-approval prevention | The application shall prevent or surface self-approval denials when Order Fulfilment reports a self-approval conflict. | Must | Given the supervisor created/requested the exception, when approval is attempted, then the action is denied and the UI explains the conflict. |
| FSU-APP-005 | Filtering/reporting | The application shall support filtering by exception type, SKU, operator, date, courier, order, status, age, and channel. | Should | Given filters are applied, when results load, then paginated domain results are shown and export is available where permitted. |
| FSU-APP-006 | History | The application shall display fulfilment task history, supervisor decision history, shipping attempts, label references, and completion/reversal history where authorized. | Should | Given a task is opened, when history loads, then entries include actor/service, action, timestamp, outcome, and reason where available. |

## 8. UI, Accessibility, and Usability Requirements

- Supervisor dashboards shall prioritize exception age, business impact, and blocked tasks without hiding lower-priority queues.
- Decision screens shall show required evidence, previous attempts, domain-provided allowed actions, and reason entry.
- Long error, product, courier, and reason text shall wrap without overlapping decision controls.
- Screens shall target WCAG 2.2 AA and support keyboard navigation, focus management, and readable status indicators.
- Denial, stale context, and already-resolved states shall be clear and prevent duplicate decision attempts.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Fulfilment task/exception | Order Fulfilment | Review and decisions. | Yes | Show current state and allowed actions. |
| Pick/pack/ship details | Order Fulfilment | Evidence. | Conditional | Show quantities, provider errors, label references. |
| Sales order context | Sales/Order Fulfilment | Customer/order impact. | Conditional | Display minimum necessary customer data. |
| Inventory context | Inventory Management | Stock impact. | Conditional | Mark stale/unavailable state. |
| Decision reason | User input to Order Fulfilment | Approval/rejection. | Conditional | Required for controlled decisions. |
| Operational history | Order Fulfilment | Review traceability. | Conditional | Read-only and role-scoped. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| FSU-INT-001 | Load dashboard | Order Fulfilment | Filters, queue/status data. | Show unavailable/stale state. | Correlate request. |
| FSU-INT-002 | Load Sales context | Sales/Order Fulfilment | Sales order status and delivery context. | Show unavailable linked context. | Correlate query. |
| FSU-INT-003 | Load Inventory context | Inventory Management | Reservation/consumption/stock exception context. | Show stale/unavailable linked context. | Correlate query. |
| FSU-INT-004 | Submit decision | Order Fulfilment | Approval/rejection, reason, exception ID. | Show self-approval/authorization/invalid-state denial. | Idempotency key for decision. |
| FSU-INT-005 | Export queue | Order Fulfilment reporting | Filters and report fields. | Show export denial/failure. | Correlate request. |

## 11. Reporting, Search, and Dashboard Requirements

| View / Report | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Fulfilment Workload | Fulfilment Supervisor | Monitor work volume and aging. | Status, age, SKU, channel, operator. | CSV. |
| Exception Queue | Fulfilment Supervisor | Resolve blocked tasks. | Exception type, courier, SKU, operator, date, order. | CSV. |
| Partial Fulfilment Review | Fulfilment Supervisor, Sales | Track backorder decisions. | Order, customer, SKU, date, status. | CSV optional. |
| Shipping/Label Exceptions | Fulfilment Supervisor | Resolve provider/label issues. | Courier, error type, date, task, status. | CSV optional. |
| Completion/Reversal History | Fulfilment Supervisor | Review controlled outcomes. | Actor, date, order, status, exception. | CSV for operational review. |

## 12. Security and Permissions

The application shall enforce Fulfilment Supervisor route and screen access. Order Fulfilment remains authoritative for exception approval, override state, completion reversal state, cancellation-after-picking state, courier records, and operational history. Sales and Inventory context is read-only unless explicit domain actions are exposed.

## 13. Operational History and Traceability

The application shall display Order Fulfilment-provided task history, exception history, approval decisions, shipping purchase details, label references, and completion/reversal history. Supervisor decisions shall include user identity, reason, source application, and correlation ID for domain operational history. CSV outputs shall use authorized Order Fulfilment query endpoints.

## 14. Non-Functional Requirements

- Dashboards shall use paginated queries and stable filters/sorting.
- Decision commands shall be idempotent to avoid duplicate approvals after retry.
- The API shall propagate correlation IDs across Order Fulfilment, Sales, and Inventory calls.
- Linked context unavailability shall not block primary exception review but must be visible.
- The application shall not store fulfilment, sales, or inventory records locally.

## 15. Dependencies

- Order Fulfilment for workload, exceptions, approvals, shipping/label references, lifecycle, and operational history.
- Sales for order/customer impact and status context.
- Inventory Management for reservation, consumption, and stock exception context.
- Authentik and Gravitee for identity, ingress, role claims, route policy, and correlation metadata.

## 16. Assumptions and MVP Defaults

- Fulfilment Supervisor users are internal authenticated users with explicit approval authority.
- CSV export is sufficient for MVP operational reporting.
- Supervisor decisions are recorded in Order Fulfilment, not locally.
- Fulfilment workload priority uses status and age as the default ordering inputs.
- Supervisors may view recipient name, delivery address, order reference, delivery instructions, SKU/quantity, and fulfilment status where needed for decisions; wider customer account data is not shown.
- Partial fulfilment approval is allowed for short pick or unavailable inventory scenarios reported by Order Fulfilment and does not require customer confirmation in MVP.

## 17. Acceptance Summary

The Fulfilment Supervisor requirements are complete for MVP when they define workload monitoring, exception review, controlled approvals, cross-domain context, reporting/export, security, operational history visibility, and explicit MVP defaults without assigning durable fulfilment, sales, or inventory state to the application.
