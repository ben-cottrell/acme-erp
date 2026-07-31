# Application Requirements: Warehouse Operator

## 1. Purpose

The Warehouse Operator application supports warehouse users who perform stock counts and book received goods against purchase orders. It provides scanner-friendly and keyboard-friendly workflows over Inventory Management and Purchasing without owning stock or purchase order state.

The MVP outcome is a practical warehouse data-entry application for counts and receipts that sends authoritative commands to Inventory Management, uses Purchasing lookup for purchase order context, and routes exceptions to supervisor review.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.WarehouseOperator.Ui` |
| API | `Acme.Erp.WarehouseOperator.Api` |
| Primary users | Warehouse Operator |
| Database | None |
| Domain APIs consumed | Inventory Management, Purchasing |

The Warehouse Operator UI calls only the Warehouse Operator API. The Warehouse Operator API owns no durable business state, uses no EF Core migrations, and does not connect to SQL Server.

## 3. User-Facing Scope

### In Scope

- Start/open stock count tasks and record actual counted quantities through Inventory Management.
- Display recorded stock quantities, product/SKU/barcode/location context, and count status returned by Inventory Management.
- Capture product, SKU, barcode, location, count date, receipt date, quantity, condition, and operator context.
- Select or scan purchase orders available for receipt using Purchasing-backed lookup.
- Display expected products, SKU/barcodes, ordered quantities, supplier, and expected arrival information.
- Record received goods and submit receipt commands to Inventory Management for PO matching and stock booking.
- Display receipt mismatch, under-receipt, over-receipt, damaged, quarantine, rejected, and discrepancy states.
- Route discrepancy and receipt exception review to Inventory Supervisor workflows.

### Out of Scope

- Durable inventory or purchasing state, direct SQL access, EF Core migrations, PO authoring, supplier updates, stock adjustment approval, receipt exception approval, fulfilment picking, shipping, and finance posting.
- Warehouse automation hardware integration beyond scanner-friendly input behavior for MVP.

## 4. Business Context

Warehouse users need quick, reliable capture of physical counts and received goods. The application must reduce entry errors and show immediate domain validation while preserving Inventory as the stock authority and Purchasing as the PO authority.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Warehouse Operator | Warehouse user performing physical tasks. | Count stock, scan/enter products and locations, receive goods, record condition and quantities. | Large clear forms, keyboard/scanner flow, minimal navigation, field-level errors. |
| Inventory Supervisor | Escalation user, not primary in this app. | Reviews discrepancies and receipt exceptions in separate application. | Link/route to supervisor-owned workflows only. |

## 6. User Journeys and Workflows

- **Stock count**: operator starts or opens count task, scans/selects product/SKU/barcode/location, views recorded quantity where allowed, enters actual quantity, submits count, and sees no-variance or discrepancy state.
- **Goods receipt**: operator searches/scans/selects PO, reviews expected lines, enters received quantities and condition, submits receipt to Inventory, and sees booked or exception state.
- **Exception capture**: operator records mismatch, missing item, over/under receipt, damaged goods, quarantine, or rejected goods; Inventory creates exception state for supervisor review.
- **Correction before submit**: operator can correct unsent form entries; after submission, corrections are domain-controlled commands rather than local edits.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| WHO-APP-001 | Stock checks | The application shall allow authorized warehouse operators to start or open stock checks through Inventory Management. | Must | Given a valid operator opens a count, when Inventory accepts the request, then the UI displays the count task and current recorded stock where permitted. |
| WHO-APP-002 | Count entry | The application shall display recorded stock and allow actual quantity entry without storing inventory balances locally. | Must | Given an operator submits actual count, when Inventory processes it, then the UI shows no variance or discrepancy state returned by Inventory. |
| WHO-APP-003 | Product/location capture | The application shall allow operators to select or scan products, SKUs, barcodes, and locations for count and receipt workflows. | Must | Given an unknown or inactive identifier is entered, when validation runs, then the UI shows Inventory validation errors and blocks invalid submission where required. |
| WHO-APP-004 | PO receipt | The application shall allow operators to start goods receipts against purchase orders by orchestrating Purchasing lookup and Inventory receipt commands. | Must | Given an eligible PO is selected, when goods are submitted, then Inventory validates against PO details and returns booked or exception state. |
| WHO-APP-005 | Receipt exceptions | The application shall display PO matching results and receipt exceptions returned by Inventory Management. | Must | Given over-receipt, under-receipt, damage, quarantine, or mismatch occurs, when Inventory responds, then the UI shows exception state and supervisor route. |
| WHO-APP-006 | Supervisor routing | The application shall route discrepancy and receipt exception review to supervisor applications rather than approving them locally. | Must | Given an exception requires approval, when the operator views it, then approval controls are absent and the supervisor review state is shown. |
| WHO-APP-007 | Accessibility/scanner use | The application shall provide accessible warehouse data-entry screens suitable for keyboard and scanner-assisted operation. | Must | Given scanner input sends value plus enter/tab behavior, when a field is focused, then the workflow advances predictably without losing data. |

## 8. UI, Accessibility, and Usability Requirements

- Count and receipt forms shall minimize required navigation and preserve in-progress entries until submitted or explicitly cancelled.
- Barcode/SKU/location fields shall support keyboard-only and scanner-assisted entry.
- Validation errors shall be displayed beside the relevant field and summarized at the top of the form.
- The UI shall clearly distinguish booked stock, pending exception, rejected receipt, quarantine, and discrepancy states.
- Screens shall target WCAG 2.2 AA and support high-contrast, focus visibility, and assistive technology labels.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Product/SKU/barcode | Inventory Management | Count and receipt item identification. | Yes | Show active/inactive/unknown state. |
| Location | Inventory Management | Count and stock placement. | Conditional | Required where location tracking is enabled. |
| Recorded stock | Inventory Management | Count comparison. | Conditional | Display according to role/policy. |
| Actual count | User input to Inventory | Stock check. | Yes for count | Non-negative numeric. |
| Purchase order | Purchasing | Receipt selection. | Yes for PO receipt | Show eligible/current status. |
| Received quantity/condition | User input to Inventory | Receipt booking. | Yes | Non-negative quantity; condition required for damage/quarantine/rejection. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Validation / Result |
|---|---|---|---|---|
| WHO-INT-001 | Open/start count | Inventory Management | Product, location, and count context. | Show validation and authorization errors. |
| WHO-INT-002 | Submit actual count | Inventory Management | Actual quantity, product/SKU/barcode, location, and operator context. | Show no-variance or discrepancy state. |
| WHO-INT-003 | Lookup PO | Purchasing via app API | PO number/search filters and eligible receipt status. | Show returned eligible purchase orders. |
| WHO-INT-004 | Submit receipt | Inventory Management | PO reference, received lines, quantities, and condition. | Show booked, business exception, or rejected state. |
| WHO-INT-005 | View exception | Inventory Management | Receipt or discrepancy status. | Show supervisor route with no local approval. |

## 11. Worklist and Exception Queue Requirements

| View | Audience | Purpose | Filters |
|---|---|---|---|
| Count Task List | Warehouse Operator | Find open counts. | Location, SKU, status, date. |
| Receipt Worklist | Warehouse Operator | Receive expected POs. | PO, supplier, expected arrival, status. |
| Receipt Exceptions | Warehouse Operator | See items routed to supervisor. | Exception type, PO, SKU, status. |

## 12. Security and Permissions

The application shall enforce Warehouse Operator route and screen access. Inventory Management remains authoritative for stock checks, receipts, discrepancies, stock movements, authorization, and approval rules. Purchasing remains authoritative for PO data. The app shall not expose approval actions for discrepancies or receipt exceptions.

## 13. Non-Functional Requirements

- Primary count and receipt workflows shall remain usable with intermittent validation failures by preserving unsent input.
- The application shall not maintain a local stock cache or PO cache beyond request/session needs.

## 14. Dependencies

- Inventory Management for stock checks, product/location validation, receipts, and exceptions.
- Purchasing for PO lookup and receipt eligibility context.
- Authentik and Gravitee for identity, ingress, and route policy.

## 15. Assumptions and MVP Defaults

- Warehouse automation hardware integrations are out of scope; scanner-friendly input is sufficient for MVP.
- Warehouse Operators cannot approve discrepancies or receipt exceptions.
- Application does not persist offline work in MVP.
- MVP scanner support assumes keyboard-wedge barcode scanners that submit text into focused fields; Code 128 labels are the default barcode format.
- Recorded stock is visible during counts to minimize MVP complexity; blind counts are deferred.
- MVP uses the single logical warehouse and simple location codes defined by Inventory Management.
- MVP receipt condition choices are Good, Damaged, Quarantine, and Rejected.

## 16. Acceptance Summary

The Warehouse Operator requirements are complete for MVP when they define stock count and goods receipt workflows, scanner-friendly input, Inventory/Purchasing orchestration, exception routing, security, and explicit MVP defaults without assigning inventory or purchasing state to the application.
