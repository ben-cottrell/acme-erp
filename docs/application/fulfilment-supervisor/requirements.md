# Application Requirements: Fulfilment Supervisor

## 1. Purpose

The Fulfilment Supervisor application supports fulfilment control users who monitor workload, resolve pick/pack/ship/completion exceptions, approve controlled overrides, review partial fulfilment, and oversee completion reversals or cancellations after picking starts.

The MVP outcome is a supervisory control application that gives fulfilment leaders enough Sales, Inventory, and fulfilment context to make decisions while Order Fulfilment remains authoritative for lifecycle and approvals.

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
- Review of pick exceptions, short picks, substitutions, damaged components, packing issues, partial fulfilment, cancellation, reversal, and policy decisions.
- Approval/rejection of controlled fulfilment exceptions through Order Fulfilment.
- Review of partial fulfilment/backorder proposals and cancellation after picking starts.
- Read-only Sales order/customer delivery context and Inventory reservation/consumption context where needed and allowed.
- Operational reports, CSV exports, and accessible supervisor review screens.

### Out of Scope

- Durable fulfilment, sales, or inventory state; direct SQL access; EF Core migrations.
- Operator task execution, label printing as an operator workflow, sales order authoring, stock balance mutation, PO authoring, courier contract management, returns/RMA, and finance postings.

## 4. Business Context

Fulfilment supervisors need a control surface for resolving blocked warehouse work and preventing unapproved changes to customer orders, stock, and courier activity. The application must present cross-domain context while letting Order Fulfilment enforce approval, self-approval checks, and lifecycle state.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Fulfilment Supervisor | Fulfilment control user. | Monitor queues, approve/reject exceptions, review partial fulfilment and reversals. | Exception dashboard, decision context, filters, and CSV export. |

## 6. User Journeys and Workflows

- **Monitor workload**: supervisor opens dashboard and reviews released, in-progress, blocked, and aging fulfilment work.
- **Review pick exception**: supervisor opens exception, reviews required/picked quantities, product/SKU/serial context, operator reason, Inventory state, and Sales impact.
- **Approve partial fulfilment**: supervisor reviews remaining quantities and customer/order impact before approving partial completion/backorder.
- **Approve cancellation/reversal**: supervisor reviews task progress, stock effects, Sales state, and business reason before submitting decision to Order Fulfilment.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| FSU-APP-001 | Workload dashboard | The application shall display fulfilment workload and exception queues from Order Fulfilment. | Must | Given authorized supervisor access, when the dashboard loads, then queues show status, age, exception type, SKU, operator, and task/order references. |
| FSU-APP-002 | Context display | The application shall show Sales and Inventory Management context returned for exception decisions without local persistence. | Must | Given an exception includes Sales or Inventory business references, when opened, then the UI displays the returned read-only context. |
| FSU-APP-003 | Exception decisions | The application shall allow authorized supervisors to approve or reject pick exceptions, short picks, substitutions, partial fulfilment release, cancellation after picking starts, and completion reversals through Order Fulfilment. | Must | Given a valid decision, when submitted, then Order Fulfilment records the outcome; invalid state or self-approval denial is shown. |
| FSU-APP-004 | Self-approval prevention | The application shall prevent or surface self-approval denials when Order Fulfilment reports a self-approval conflict. | Must | Given the supervisor created/requested the exception, when approval is attempted, then the action is denied and the UI explains the conflict. |
| FSU-APP-005 | Filtering/reporting | The application shall support filtering by exception type, SKU, operator, date, courier, order, status, age, and channel. | Should | Given filters are applied, when results load, then paginated domain results are shown and export is available where permitted. |

## 8. UI, Accessibility, and Usability Requirements

- Supervisor dashboards shall prioritize exception age, business impact, and blocked tasks without hiding lower-priority queues.
- Decision screens shall show required evidence, domain-provided allowed actions, and reason entry.
- Long product, courier, and reason text shall wrap without overlapping decision controls.
- Screens shall target WCAG 2.2 AA and support keyboard navigation, focus management, and readable status indicators.
- Denial and already-resolved states shall be clear and disable invalid decision actions.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Fulfilment task/exception | Order Fulfilment | Review and decisions. | Yes | Show current state and allowed actions. |
| Pick/pack/ship details | Order Fulfilment | Evidence. | Conditional | Show quantities and accepted shipment, tracking, and label references. |
| Sales order context | Sales/Order Fulfilment | Customer/order impact. | Conditional | Display minimum necessary customer data. |
| Inventory context | Inventory Management | Stock impact. | Conditional | Show accepted reservation and stock movement references. |
| Decision reason | User input to Order Fulfilment | Approval/rejection. | Conditional | Required for controlled decisions. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Validation / Result |
|---|---|---|---|---|
| FSU-INT-001 | Load dashboard | Order Fulfilment | Filters and queue/status data. | Show the returned workload and business exception states. |
| FSU-INT-002 | Load Sales context | Sales/Order Fulfilment | Sales order status and delivery context. | Show returned Sales business context. |
| FSU-INT-003 | Load Inventory context | Inventory Management | Accepted reservation and stock movement references. | Show returned Inventory business context. |
| FSU-INT-004 | Submit decision | Order Fulfilment | Approval/rejection, reason, and exception ID. | Show self-approval, authorization, or invalid-state denial. |
| FSU-INT-005 | Export queue | Order Fulfilment reporting | Filters and report fields. | Show authorization denial or the completed export. |

## 11. Reporting, Search, and Dashboard Requirements

| View / Report | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Fulfilment Workload | Fulfilment Supervisor | Monitor work volume and aging. | Status, age, SKU, channel, operator. | CSV. |
| Exception Queue | Fulfilment Supervisor | Resolve blocked tasks. | Exception type, courier, SKU, operator, date, order. | CSV. |
| Partial Fulfilment Review | Fulfilment Supervisor, Sales | Track backorder decisions. | Order, customer, SKU, date, status. | CSV optional. |
| Shipment References | Fulfilment Supervisor | Review accepted shipment, tracking, and label references. | Courier, date, task, status. | CSV optional. |

## 12. Security and Permissions

The application shall enforce Fulfilment Supervisor route and screen access. Order Fulfilment remains authoritative for exception approval, override state, completion reversal state, cancellation-after-picking state, and courier records. Sales and Inventory context is read-only unless explicit domain actions are exposed.

## 13. Non-Functional Requirements

- Dashboards shall use paginated queries and stable filters/sorting.
- The application shall not store fulfilment, sales, or inventory records locally.

## 14. Dependencies

- Order Fulfilment for workload, exceptions, approvals, shipping/label references, and lifecycle.
- Sales for order/customer impact and status context.
- Inventory Management for accepted reservation and stock movement context.
- Authentik and Gravitee for identity, ingress, role claims, and route policy.

## 15. Assumptions and MVP Defaults

- Fulfilment Supervisor users are internal authenticated users with explicit approval authority.
- CSV export is sufficient for MVP operational reporting.
- Supervisor decisions are recorded in Order Fulfilment, not locally.
- Fulfilment workload priority uses status and age as the default ordering inputs.
- Supervisors may view recipient name, delivery address, order reference, delivery instructions, SKU/quantity, and fulfilment status where needed for decisions; wider customer account data is not shown.
- Partial fulfilment approval is allowed for short pick or unavailable inventory scenarios reported by Order Fulfilment and does not require customer confirmation in MVP.

## 16. Acceptance Summary

The Fulfilment Supervisor requirements are complete for MVP when they define workload monitoring, exception review, controlled approvals, cross-domain context, reporting/export, security, and explicit MVP defaults without assigning durable fulfilment, sales, or inventory state to the application.
