# Application Requirements: Buyer

## 1. Purpose

The Buyer application supports buyers and purchasing managers who create purchase orders, process non-stocked product requests, maintain expected arrival information, review receipt visibility, and approve controlled purchasing actions.

The MVP outcome is a purchasing workbench that lets authorized users complete purchase-order and buyer-request workflows through Purchasing while using Inventory and Sales context without the application owning durable state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.Buyer.Ui` |
| API | `Acme.Erp.Buyer.Api` |
| Primary users | Buyer, Purchasing Manager |
| Database | None |
| Domain APIs consumed | Purchasing, Sales, Inventory Management |

The Buyer UI calls only the Buyer API. The Buyer API owns no durable business state, uses no EF Core migrations, and does not connect to SQL Server.

## 3. User-Facing Scope

### In Scope

- Purchase order creation, amendment, submission, cancellation/request-cancellation, and status review through Purchasing.
- Supplier selection from Purchasing and product/SKU/barcode validation from Inventory Management surfaced through the app API.
- Capture of item, SKU/barcode where available, quantity, unit cost, purchase date, expected arrival date, and reason/comments where required.
- Purchasing Manager approval/rejection of controlled purchasing actions through Purchasing.
- Sales-originated buyer request queue handling through Purchasing, including accept, reject, clarify, and link to PO.
- Receipt status, partial receipt, and receipt exception visibility copied from Inventory Management through Purchasing.
- Search, filters, dashboards, CSV export, accessible PO entry, and approval review screens.

### Out of Scope

- Durable purchase order, supplier, inventory, or sales state ownership.
- Direct database access, EF Core migrations, goods receipt booking, stock mutation, supplier onboarding, contract management, accounts payable, invoice matching, tax, landed cost, and payment processing.
- UI workflows for warehouse receipt entry, sales order capture, fulfilment, or finance.

## 4. Business Context

Buyers need a focused workbench for supplier ordering and Sales buyer requests while Purchasing remains authoritative for PO and approval state. Inventory context is needed to validate purchased items and receipt status, but Inventory remains the stock system of record.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Buyer | User who creates and manages POs. | Create/amend POs, process buyer requests, review receipt visibility, monitor expected arrivals. | Efficient line entry, supplier/product lookup, validation, queue filters. |
| Purchasing Manager | Approval/control user. | Approve/reject controlled POs and amendments, review exceptions. | Approval queue, self-approval denial visibility, decision context, CSV export. |

## 6. User Journeys and Workflows

- **Create PO**: Buyer selects supplier, adds item/SKU/barcode lines, quantity, unit cost, purchase and expected arrival dates, then saves or submits to Purchasing.
- **Approve PO**: Purchasing Manager opens approval queue, reviews threshold/reason/context, approves or rejects through Purchasing.
- **Process buyer request**: Buyer opens Sales-originated request, accepts, rejects with reason, returns for clarification, or creates/links a purchase order.
- **Monitor receipts**: Buyer searches POs and sees receipt status, partial receipt, and receipt exceptions copied from Inventory through Purchasing.
- **Amend/cancel PO**: Buyer requests changes; Purchasing applies draft changes or routes controlled changes for approval.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| BYR-APP-001 | PO creation | The application shall allow authorized buyers to create and update purchase orders through Purchasing. | Must | Given required PO data is complete, when submitted, then Purchasing creates/updates the PO; validation errors are shown by field/action without local persistence. |
| BYR-APP-002 | Product validation | The application shall display product/SKU/barcode validation results from Inventory Management without storing product master data locally. | Must | Given a SKU is inactive or unknown, when the buyer adds it, then validation state is shown and Purchasing determines whether submission is allowed. |
| BYR-APP-003 | Approval | The application shall allow Purchasing Managers to review, approve, or reject controlled purchasing actions where Purchasing reports approval is required. | Must | Given a PO requires approval, when an authorized manager approves, then Purchasing records the decision; self-approval is denied and displayed. |
| BYR-APP-004 | Buyer requests | The application shall allow buyers to process Sales-originated non-stocked product requests through Purchasing. | Must | Given a request is pending, when the buyer accepts/rejects/returns/links it, then Purchasing records the decision and status returned to Sales. |
| BYR-APP-005 | Receipt visibility | The application shall display receipt status, partial receipt, and receipt exceptions returned through Purchasing. | Must | Given Inventory has reported receipt status, when the PO is opened, then the UI shows copied receipt visibility and stale indicators where present. |
| BYR-APP-006 | Search | The application shall support search and filtering by PO number, supplier, SKU, barcode, expected arrival date, status, buyer, request state, and receipt exception. | Should | Given filters are supplied, when results load, then the API queries Purchasing/Inventory contracts and returns paginated data. |
| BYR-APP-007 | Amend/cancel | The application shall support PO amendment and cancellation requests according to Purchasing state and approval requirements. | Must | Given controlled fields change after approval/order, when submitted, then the UI routes to approval or displays a Purchasing denial. |

## 8. UI, Accessibility, and Usability Requirements

- PO line entry shall support adding, editing, and removing multiple lines without losing validation state.
- Approval queues shall show requester, threshold/reason context, changed fields, receipt status, and self-approval denial reason where applicable.
- Buyer request queues shall prioritize age/status and expose request reason and Sales context allowed by policy.
- Screens shall target WCAG 2.2 AA, support keyboard operation, and present validation errors near affected fields.
- Long supplier, item, and reason values shall wrap without overlapping actions.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Supplier | Purchasing | PO creation. | Yes | Show active/inactive state. |
| Item/SKU/barcode | Inventory Management/Purchasing | PO line validation. | Yes where available | Show unknown/inactive status. |
| Quantity/unit cost/dates | Purchasing | PO submission. | Yes | Positive quantity; unit cost required; date validation from Purchasing. |
| Buyer request | Purchasing/Sales context | Non-stocked workflow. | Conditional | Show request state and reason. |
| Receipt status | Purchasing/Inventory visibility | PO monitoring. | Conditional | Show partial, exception, stale state. |
| Approval history | Purchasing | Control review. | Conditional | Show requester, approver, date, decision, reason. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| BYR-INT-001 | Create/update PO | Purchasing | Supplier, lines, quantities, costs, dates, comments. | Show validation/authorization errors. | Correlation ID; idempotency for submit. |
| BYR-INT-002 | Validate item | Inventory Management via app API/Purchasing | SKU/barcode/item lookup. | Show unavailable or stale validation. | Correlate request. |
| BYR-INT-003 | Approval decision | Purchasing | Approval/rejection, reason/comment. | Show self-approval or authorization denial. | Correlate decision. |
| BYR-INT-004 | Process buyer request | Purchasing | Request decision, linked PO, clarification/rejection reason. | Show retryable status update failure. | Idempotency for decision action. |
| BYR-INT-005 | View receipt status | Purchasing | PO receipt visibility and exception data. | Mark stale if Inventory update is unavailable. | Correlate query. |

## 11. Reporting, Search, and Dashboard Requirements

| View / Report | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Open PO Workbench | Buyer | Manage active POs. | Supplier, SKU, date, status, buyer, expected arrival. | CSV. |
| Expected Arrivals | Buyer, Purchasing Manager | Plan inbound purchases. | Date range, supplier, SKU, receipt state. | CSV. |
| Buyer Request Queue | Buyer | Process Sales requests. | Request state, age, Sales order, SKU/description. | CSV optional. |
| Approval Queue | Purchasing Manager | Review controlled actions. | Requester, threshold, status, age. | CSV optional for manager review. |
| Receipt Exceptions | Buyer, Purchasing Manager | Monitor PO-related receipt issues. | Supplier, PO, SKU, exception type, age. | CSV optional. |

## 12. Security and Permissions

The application shall enforce route and screen access for Buyer and Purchasing Manager roles. Purchasing remains authoritative for PO validation, approval authority, self-approval restrictions, persistence, buyer request decisions, and operational history. Inventory remains authoritative for product data and receipt booking. The app shall show denial reasons from domains and shall not bypass self-approval restrictions.

## 13. Operational History and Traceability

The application shall display Purchasing-provided PO status history, approval history, amendment history, buyer request decisions, and receipt visibility. CSV outputs for purchasing data shall use authorized Purchasing query endpoints.

## 14. Non-Functional Requirements

- PO workbench and queues shall be paginated and filterable.
- The API shall propagate correlation IDs to Purchasing, Sales, and Inventory calls.
- The app shall remain stateless and shall not persist PO drafts beyond request/session behavior unless a domain API owns the draft.
- Validation and denial messages shall be clear enough for corrective user action.
- Downstream unavailability shall be shown as unavailable/stale state rather than blank success.

## 15. Dependencies

- Purchasing for supplier data, PO lifecycle, approvals, buyer request decisions, receipt visibility, and operational history.
- Inventory Management for product/SKU/barcode validation and receipt status source data.
- Sales for originating buyer request context through Purchasing/Sales contracts.
- Authentik and Gravitee for identity, ingress, role claims, and correlation metadata.

## 16. Assumptions and MVP Defaults

- Supplier reference data is Purchasing-owned for MVP.
- Buyer application users are authenticated internal users.
- MVP uses one configured company currency and CSV exports.
- Accounts payable, invoice matching, tax, landed cost, supplier onboarding, and payment processing are excluded.
- The application displays the Purchasing domain MVP approval threshold of 10,000 in the configured company currency and uses Purchasing Manager as the approval role.
- Buyer request screens show Sales order reference, requested product description, quantity, requested-by role, request date, and reason; customer personal data is not shown unless Purchasing/Sales explicitly authorizes it.
- Buyers may close partially received purchase orders only when Purchasing reports a close action is available; no additional application-specific approval flow is added for MVP.

## 17. Acceptance Summary

The Buyer requirements are complete for MVP when they define PO authoring, approvals, buyer request handling, product validation, receipt visibility, search/reporting, security, operational history visibility, and explicit MVP defaults without assigning durable purchasing, inventory, or sales state to the application.