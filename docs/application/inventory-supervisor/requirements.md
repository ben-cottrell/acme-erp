# Application Requirements: Inventory Supervisor

## 1. Purpose

The Inventory Supervisor application supports inventory control users who review stock discrepancies, approve or reject controlled adjustments, monitor goods receipt exceptions, and review inventory accuracy and stock movement history.

The MVP outcome is a focused supervisory workflow for inventory exceptions and oversight, using Inventory Management as the stock authority and Purchasing/Order Fulfilment context where needed.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.InventorySupervisor.Ui` |
| API | `Acme.Erp.InventorySupervisor.Api` |
| Primary users | Inventory Supervisor |
| Database | None |
| Domain APIs consumed | Inventory Management, Purchasing, Order Fulfilment |

The Inventory Supervisor UI calls only the Inventory Supervisor API. The Inventory Supervisor API owns no durable business state, uses no EF Core migrations, and does not connect to SQL Server.

## 3. User-Facing Scope

### In Scope

- Review stock count discrepancies, variance calculations, adjustment reasons, approval requirements, and self-approval status.
- Approve, reject, return for investigation, or close inventory adjustments through Inventory Management.
- Review goods receipt mismatches, under-receipts, over-receipts, damaged goods, quarantine, rejected receipt states, and PO context.
- View related purchase order data from Purchasing and fulfilment-driven stock exception context from Order Fulfilment/Inventory.
- Search/filter discrepancy, receipt exception, stock movement, reservation/consumption exception, and pending review dashboards.
- Accessible supervisor review and approval screens with operational history context and CSV export where appropriate.

### Out of Scope

- Durable inventory, purchasing, or fulfilment state; direct SQL access; EF Core migrations.
- Warehouse count/receipt entry, PO authoring, sales order capture, fulfilment task execution, accounting postings, and advanced BI.

## 4. Business Context

Inventory supervisors need to keep stock trustworthy by reviewing exceptions created by warehouse activity, receipts, and fulfilment stock activity. The application must present enough context for decisions while Inventory Management remains authoritative for adjustments, receipt resolution, self-approval checks, and operational history.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Inventory Supervisor | Inventory control user. | Review discrepancies, approve/reject adjustments, resolve receipt exceptions, monitor stock movement history. | Exception queues, decision context, self-approval warnings, operational history, CSV outputs. |

## 6. User Journeys and Workflows

- **Review discrepancy**: supervisor opens pending discrepancy, reviews recorded vs actual quantity, variance/value, recorder, location, history, and policy decision requirement.
- **Approve/reject adjustment**: supervisor enters decision and reason; Inventory Management enforces authorization and self-approval rules before posting or rejecting adjustment.
- **Review receipt exception**: supervisor opens receipt mismatch/damage/quarantine/rejection, reviews PO context, quantities, condition, and Inventory-recommended options.
- **Resolve receipt exception**: supervisor approves booking, rejects receipt, returns for investigation, or routes supplier/PO follow-up according to Inventory responses.
- **Monitor stock history**: supervisor searches movements and exceptions to understand recurring issues.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| ISU-APP-001 | Discrepancy queue | The application shall display inventory discrepancies and receipt exceptions requiring supervisor review. | Must | Given pending exceptions exist, when the supervisor opens the dashboard, then queues show status, age, SKU, location, variance/exception type, and priority context. |
| ISU-APP-002 | PO context | The application shall show related PO context from Purchasing without copying Purchasing data into a local database. | Must | Given a receipt exception references a PO, when opened, then supplier, PO line, ordered quantity, and expected arrival context are displayed if authorized. |
| ISU-APP-003 | Adjustment decision | The application shall submit approval, rejection, investigation, or closure outcomes to Inventory Management. | Must | Given a supervisor submits a decision, when Inventory accepts it, then the UI shows updated state and history reference; denial or self-approval conflict is shown. |
| ISU-APP-004 | Self-approval prevention | The application shall prevent or clearly surface self-approval denials when Inventory Management reports a self-approval conflict. | Must | Given the supervisor recorded the count/exception, when they attempt approval, then the action is denied by Inventory and the UI shows conflict reason. |
| ISU-APP-005 | Search/filter | The application shall support filtering by age, status, location, SKU, variance, supplier, PO, exception type, recorder, and approver. | Should | Given filters are applied, when results load, then paginated domain results are shown with no local persistence. |
| ISU-APP-006 | Stock history | The application shall display stock movement history and reservation/consumption exceptions available from Inventory Management. | Should | Given a user opens movement history, when authorized, then movements include source document, quantity, date, actor/service, and reason where available. |

## 8. UI, Accessibility, and Usability Requirements

- Decision screens shall show the evidence needed for approval without requiring navigation across unrelated screens.
- Approval/rejection forms shall require a reason where Inventory policy requires one.
- Self-approval conflicts and authorization denials shall be visible and actionable.
- Tables shall support keyboard navigation, clear status badges/text, and filters that do not reset unexpectedly.
- Screens shall target WCAG 2.2 AA and keep long product, supplier, and reason text readable without overlapping actions.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Discrepancy | Inventory Management | Adjustment review. | Yes | Show recorded/actual/variance, location, recorder, status. |
| Receipt exception | Inventory Management | Receipt resolution. | Conditional | Show exception type, condition, received/expected quantity. |
| PO context | Purchasing | Receipt decision context. | Conditional | Read-only; show returned supplier, order, line, and quantity context. |
| Stock movement | Inventory Management | Traceability. | Conditional | Show source document and actor/service. |
| Fulfilment stock exception | Inventory/Order Fulfilment | Consumption/reservation review. | Conditional | Show task/order references, not mutable locally. |
| Decision reason | User input to Inventory | Approval/rejection. | Conditional | Required where policy says; preserve on validation failure. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Validation / Result |
|---|---|---|---|---|
| ISU-INT-001 | Load discrepancy queue | Inventory Management | Filters, status, and paging. | Show returned discrepancy and receipt-exception states. |
| ISU-INT-002 | Load PO context | Purchasing | PO reference and supplier/line context. | Show returned purchase-order business context. |
| ISU-INT-003 | Submit adjustment decision | Inventory Management | Decision, reason, and exception ID. | Show self-approval, authorization, or validation denial. |
| ISU-INT-004 | Resolve receipt exception | Inventory Management | Resolution outcome, reason, and condition. | Show the accepted resolution or Inventory validation denial. |
| ISU-INT-005 | View fulfilment exception | Inventory Management/Order Fulfilment | Reservation, consumption, and task references. | Show returned fulfilment stock context. |

## 11. Reporting, Search, and Dashboard Requirements

| View / Report | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Discrepancy Review Queue | Inventory Supervisor | Approve/reject variances. | Age, SKU, location, variance, status, recorder. | CSV. |
| Receipt Exception Queue | Inventory Supervisor | Resolve receipt problems. | Supplier, PO, SKU, exception type, age, status. | CSV. |
| Stock Movement Search | Inventory Supervisor | Trace stock changes. | SKU, location, source, date, actor, movement type. | CSV. |
| Adjustment Approval History | Inventory Supervisor | Review decisions. | Approver, requester, date, status, variance. | CSV for operational review. |
| Fulfilment Stock Exceptions | Inventory Supervisor | Resolve reservation/consumption issues. | Task, sales order, SKU, exception type, date. | CSV optional. |

## 12. Security and Permissions

The application shall enforce Inventory Supervisor route and screen access. Inventory Management remains authoritative for discrepancy approval, adjustment posting, receipt exception resolution, stock movements, self-approval checks, and operational history. Purchasing and Order Fulfilment context is read-only unless their domains expose explicit actions.

## 13. Operational History and Traceability

The application shall display Inventory-provided status and activity history for discrepancies, adjustments, receipt exceptions, and movements where authorized. Supervisor decisions shall include user identity, reason, and source application for Inventory operational history. CSV outputs shall use authorized Inventory query endpoints.

## 14. Non-Functional Requirements

- Review queues shall be paginated, sortable, and filterable.
- The application shall not store local exception, PO, or movement data.

## 15. Dependencies

- Inventory Management for discrepancies, adjustments, receipts, stock movements, reservation/consumption exceptions, self-approval checks, and operational history.
- Purchasing for purchase order receipt context.
- Order Fulfilment for fulfilment task context where stock exceptions require it.
- Authentik and Gravitee for identity, ingress, role claims, and route policy.

## 16. Assumptions and MVP Defaults

- Inventory Supervisor users are internal authenticated users with explicit approval authority.
- The application displays the Inventory Management MVP adjustment thresholds of 2,000 in the configured company currency or 10 percent variance, whichever is reached first.
- Inventory Supervisor is the MVP approval role for discrepancy adjustments and receipt exception resolution.
- The application can show read-only linked context from Purchasing and Order Fulfilment but cannot mutate those domains unless explicit contracts are added.
- CSV export is sufficient for MVP operational oversight.
- Recorded stock is visible to supervisors during discrepancy review to minimize MVP workflow complexity.
- MVP receipt exception resolution options are Approve Booking, Reject Receipt, Quarantine, and Return for Investigation.

## 17. Acceptance Summary

The Inventory Supervisor requirements are complete for MVP when they define discrepancy review, adjustment approval, receipt exception review, PO/fulfilment context, search/reporting, security, operational history visibility, and explicit MVP defaults without assigning durable inventory, purchasing, or fulfilment state to the application.