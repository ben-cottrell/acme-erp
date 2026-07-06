# Requirements Specification: Purchasing

## 1. Purpose

The purpose of the Purchasing module is to allow buyers to create and manage purchase orders that record supplier ordering information and support downstream inventory receipt matching. The module shall provide controlled purchase order records containing product, SKU, barcode, quantity, unit cost, purchase date, and expected arrival date so that inventory and financial processes can rely on accurate purchasing data.

## 2. Scope

### In Scope

- Buyer creation of purchase orders.
- Purchase order capture of specific items ordered, SKU, barcode, quantity ordered, unit cost price, purchase date, and expected arrival date.
- Purchase order status tracking for operational visibility.
- Purchase order availability to Inventory Management for goods receipt validation.
- Purchase order reporting, audit trail, and role-based access.
- Controls for PO amendments, cancellations, approvals, and exception handling.

### Out of Scope

- Physical goods receipt and stock booking, which are owned by Inventory Management.
- Sales order capture and non-stocked product customer communication, which are owned by Sales.
- Supplier onboarding, contract management, tendering, and supplier performance scoring unless separately requested.
- Detailed accounts payable posting, invoice matching, tax calculation, landed cost allocation, and payment processing for the initial release.

## 3. Business Context

Buyers require an ERP module to create purchase orders that capture the items being ordered and the key commercial and logistical details needed by the organization. Purchase orders are used as part of Inventory Management, where received goods are verified against the purchase order before being booked into stock. Accurate purchasing data reduces receiving errors, supports supplier accountability, and provides the foundation for later financial controls.

## 4. Stakeholders and User Roles

| Role | Description | Key Responsibilities | Access Level |
|---|---|---|---|
| Buyer | Purchasing user responsible for creating purchase orders. | Create POs, record item and cost details, manage expected arrival dates, respond to inventory receipt questions. | Create and update purchase orders within assigned purchasing scope. |
| Purchasing Manager | Purchasing control owner. | Review purchasing activity, approve POs or amendments where policy requires, monitor exceptions. | Review and approval access according to configured authority. |
| Warehouse Operator | Inventory user dependent on purchase orders for receipt booking. | View PO details needed to receive goods. | Read-only access to PO data required for goods receipt. |
| Inventory Supervisor | Inventory control user. | Review receipt mismatches and coordinate with Purchasing. | Read-only PO access and exception collaboration. |
| Finance / Accounts Payable User | Finance user dependent on PO and receipt data. | Review PO cost data and support invoice matching where applicable. | Read-only access to PO and receipt-related data. |
| Sales Assistant | Sales user who may trigger requests for non-routinely stocked products. | Submit or track requests that may require buyer action. | Read request status where integrated with Sales. |
| System Administrator | Technical administrator for configuration and access. | Maintain purchasing roles, reference data configuration, and integration settings. | Administrative access, excluding business approval authority unless assigned. |
| Auditor | Assurance user. | Review PO history, changes, approvals, and exceptions. | Read-only access to audit and control reports. |

## 5. Business Process Overview

The purchasing process begins when a buyer identifies the need to order specific items. The buyer creates a purchase order, records item identifiers and commercial details, submits the PO according to the configured workflow, and maintains the PO status through order placement, expected receipt, receipt matching, closure, or cancellation. Inventory Management uses the purchase order as the reference document when goods arrive and validates the received product and quantity against the PO.

Primary statuses include Draft, Submitted, Pending Approval, Approved, Ordered, Partially Received, Received, Closed, Cancelled, and Exception. Purchase orders over 10,000 require Purchasing Manager approval, and buyers may not approve their own purchase orders.

## 6. Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|
| PUR-001 | The system shall allow authorized buyers to create purchase orders. | Must | Given an authorized buyer is logged in, when the buyer creates a purchase order, then the system shall create a PO record with a unique purchase order identifier and Draft status. |
| PUR-002 | The system shall allow authorized buyers to add purchase order lines for specific items. | Must | Given a purchase order is in an editable status, when the buyer adds an item line, then the system shall store the item reference on the PO line. |
| PUR-003 | The system shall capture SKU for each purchase order line. | Must | Given a buyer enters a PO line, when the SKU is provided, then the system shall validate and store the SKU with the line. |
| PUR-004 | The system shall capture barcode for each purchase order line where available. | Must | Given a product has a barcode, when the buyer creates the PO line, then the system shall store the barcode or derive it from product master data. |
| PUR-005 | The system shall capture quantity ordered for each purchase order line. | Must | Given a buyer enters a PO line, when the quantity is entered, then the system shall require a positive numeric ordered quantity. |
| PUR-006 | The system shall capture unit cost price for each purchase order line. | Must | Given a buyer enters a PO line, when the unit cost is entered, then the system shall store the unit cost with currency or configured default currency. |
| PUR-007 | The system shall capture purchase date for each purchase order. | Must | Given a buyer creates or submits a PO, when the purchase date is entered or defaulted, then the system shall store the purchase date on the PO. |
| PUR-008 | The system shall capture expected arrival date for each purchase order or purchase order line. | Must | Given a buyer creates a PO, when expected arrival information is known, then the system shall store the expected arrival date for receipt planning. |
| PUR-009 | The system shall track purchase order status throughout the purchasing lifecycle. | Must | Given a purchase order changes from draft through ordering and receipt, when a status transition occurs, then the system shall update the PO status and retain status history. |
| PUR-010 | The system shall make approved or orderable purchase order data available to Inventory Management for receipt matching. | Must | Given a purchase order is eligible for receipt, when Inventory Management requests PO details, then the system shall provide PO header and line data needed to validate received products and quantities. |
| PUR-011 | The system shall prevent submission of purchase orders missing required item, SKU, quantity, unit cost, purchase date, or expected arrival data unless an authorized exception exists. | Must | Given a purchase order is missing required fields, when the buyer attempts to submit the PO, then the system shall block submission and identify the missing fields. |
| PUR-012 | The system shall record amendments to purchase order lines. | Should | Given a PO line is changed after initial save, when the change is submitted, then the system shall record the previous value, new value, user, timestamp, and reason where required. |
| PUR-013 | The system shall support purchase order cancellation according to configured authorization rules. | Should | Given a PO is not fully received or closed, when an authorized user cancels it, then the system shall update the status to Cancelled and prevent further receipt unless reopened by authorized action. |
| PUR-014 | The system shall provide search and filtering for purchase orders. | Should | Given an authorized user searches purchase orders, when the user filters by PO number, SKU, barcode, expected arrival date, status, or buyer, then the system shall return matching purchase orders. |

## 7. Business Rules

| ID | Rule | Applies To | Notes |
|---|---|---|---|
| PUR-BR-001 | Purchase orders shall contain item, SKU, barcode where available, quantity ordered, unit cost price, purchase date, and expected arrival date. | PO creation | Defined in source context. |
| PUR-BR-002 | Purchase orders used for inventory booking shall be available to Inventory Management. | Integration | Defined in source context. |
| PUR-BR-003 | Quantity ordered shall be positive and numeric. | PO lines | Assumption based on purchase order integrity. |
| PUR-BR-004 | Unit cost price shall be captured for each purchased item line. | PO lines | Initial release uses the configured company currency unless multi-currency is later enabled. |
| PUR-BR-005 | Purchase order changes after submission shall be auditable. | Amendments | Supports operational and financial controls. |
| PUR-BR-006 | Purchase order approval requirements shall follow configured purchasing policy. | Workflow | Purchase orders over 10,000 require Purchasing Manager approval. |

## 8. Data Requirements

| Entity / Field | Description | Required | Validation / Constraints | Source |
|---|---|---|---|---|
| Purchase Order ID | Unique identifier for the PO. | Yes | System generated and unique. | System generated |
| Buyer | User responsible for the PO. | Yes | Must be an authorized purchasing user. | User directory |
| Supplier | Supplier from whom goods are ordered. | Yes | Must identify an active supplier from supplier master or approved supplier seed data. | Supplier master dependency |
| Purchase Date | Date the purchase order is placed or recorded. | Yes | Must be a valid date. | Buyer/System |
| Expected Arrival Date | Expected date goods will arrive. | Yes | Captured at PO header and optionally overridden per line when line arrivals differ. | Buyer |
| PO Status | Current lifecycle status. | Yes | Controlled status values. | System generated |
| Item / Product | Specific item ordered. | Yes | Must align to product master unless exception process is defined. | Product master |
| SKU | Stock keeping unit. | Yes | Must map to product master. | Product master/Buyer |
| Barcode | Barcode for item ordered. | Yes where available | Must map to SKU where used. | Product master/Buyer |
| Quantity Ordered | Ordered quantity. | Yes | Must be positive numeric value. | Buyer |
| Unit Cost Price | Cost per unit. | Yes | Must be numeric and use configured currency handling. | Buyer |
| Received Quantity | Quantity received against PO. | No in Purchasing, referenced | Maintained by Inventory Management. | Inventory Management |
| Amendment Reason | Reason for PO change. | Conditional | Required for post-submission changes if policy requires. | Buyer/Approver |
| Audit Metadata | User, timestamp, status history, and change history. | Yes | Must be retained according to audit policy. | System generated |

## 9. Workflow and Approval Requirements

1. Buyer creates a purchase order in Draft status.
2. Buyer enters item, SKU, barcode where available, quantity ordered, unit cost price, purchase date, and expected arrival date.
3. System validates required data before submission.
4. Buyer submits the purchase order.
5. If approval is required by policy, the PO enters Pending Approval.
6. Authorized approver approves or rejects the PO.
7. Approved or orderable PO data becomes available for Inventory Management receipt matching.
8. Inventory receipt events update PO receipt status where integrated.
9. PO is closed when receipt and closure rules are satisfied.

Purchase orders over 10,000 require Purchasing Manager approval. Buyers may amend draft purchase orders without approval. Post-submission amendments to supplier, quantity, unit cost, expected arrival date, or cancellation require audit reason and Purchasing Manager approval when the PO has already been approved, ordered, or partially received. Buyers may not approve their own purchase orders.

## 10. Integration Requirements

| System | Direction | Data Exchanged | Frequency | Failure Handling |
|---|---|---|---|---|
| Inventory Management | Outbound from Purchasing | PO header, PO lines, item, SKU, barcode, quantity ordered, unit cost, purchase date, expected arrival date, PO status. | On PO status change and receipt lookup. | The system shall log failed PO data transmission and allow authorized users to retry or view the failure. |
| Inventory Management | Inbound to Purchasing | Received quantities, receipt status, receipt exceptions, receipt dates. | On goods receipt booking or exception update. | The system shall retain the prior PO receipt status and flag the update for review if receipt updates fail. |
| Sales | Inbound to Purchasing | Non-routinely stocked product requests requiring buyer action. | On request submission from Sales. | The system shall log failed request intake and notify responsible users where notification rules exist. |
| Product Master | Inbound to Purchasing | Product, SKU, barcode, unit of measure, product status. | On product lookup or master data update. | The system shall prevent PO submission for invalid or inactive products unless an authorized exception exists. |
| Finance / Accounts Payable | Outbound from Purchasing | PO cost data and status for invoice matching where applicable. | On PO approval, amendment, receipt, or closure. | The system shall queue or flag finance updates if the finance integration is unavailable. |

## 11. Reporting and Analytics Requirements

| Report / Dashboard | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Open Purchase Orders | Buyers, Purchasing Manager, Warehouse | Monitor POs awaiting receipt or closure. | Buyer, supplier, SKU, expected arrival date, status. | CSV and spreadsheet export. |
| Expected Arrivals | Warehouse, Inventory Supervisor | Plan receiving workload. | Date range, supplier, SKU, location if known. | CSV export. |
| PO Amendment History | Purchasing Manager, Auditor | Review changes to PO quantities, costs, dates, and status. | PO, buyer, date range, field changed. | Audit-ready PDF and CSV export. |
| PO Receipt Exceptions | Buyers, Inventory Supervisor | Track receipt mismatches requiring purchasing input. | PO, SKU, exception type, status, age. | CSV export. |
| Purchase Cost Report | Purchasing Manager, Finance | Review unit cost prices captured on POs. | SKU, supplier, buyer, date range. | CSV and spreadsheet export. |

## 12. Security, Roles, and Permissions

- The system shall restrict purchase order creation and amendment to authorized buyers.
- The system shall restrict purchase order approval to users with purchasing approval authority where approval is configured.
- The system shall provide read-only PO access to Inventory users for receipt matching.
- The system shall provide read-only PO cost and receipt-relevant data to Finance users where AP processes require it.
- The system shall prevent buyers from approving their own purchase orders where segregation of duties policy requires separate approval.
- The system shall restrict administrative configuration access from business approval privileges unless explicitly granted.

## 13. Audit and Compliance Requirements

- The system shall record the creator, submitter, approver, timestamps, status changes, and comments for each purchase order.
- The system shall record all changes to PO line item, SKU, barcode, quantity, unit cost, purchase date, and expected arrival date.
- The system shall retain PO status history from Draft through Closed, Cancelled, or other final status.
- The system shall support audit review of POs used for inventory receipt matching.
- The system shall retain purchasing audit records for 7 years.

## 14. Non-Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|
| PUR-NFR-001 | The system shall validate purchase order required fields before submission without requiring downstream inventory interaction. | Must | Given a buyer submits a PO, when required fields are missing or invalid, then the system shall return validation feedback before the PO is made available for receipt. |
| PUR-NFR-002 | The system shall provide purchase order lookup to Inventory Management within an agreed service level. | Must | Given Inventory requests PO data for goods receipt, when the Purchasing module is available, then the system shall return eligible PO data within the agreed response threshold. |
| PUR-NFR-003 | The system shall preserve PO audit history during backup and disaster recovery. | Must | Given a recovery event occurs, when purchasing data is restored, then purchase orders and audit history shall remain consistent. |
| PUR-NFR-004 | The system shall support accessible PO entry and review functions. | Should | Given a user uses keyboard navigation or assistive technology, when creating or reviewing a PO, then the required controls shall be operable and identifiable. |
| PUR-NFR-005 | The system shall maintain purchase order data integrity across amendments, status changes, and receipt updates. | Must | Given a PO status or line update is processed, when any required update fails, then the system shall prevent partial inconsistent updates or flag the record for controlled recovery. |

## 15. Exceptions and Edge Cases

- Buyer enters SKU or barcode that does not exist in product master.
- Buyer enters zero, negative, or non-numeric quantity.
- Buyer omits unit cost price, purchase date, or expected arrival date.
- Expected arrival date changes after the PO is submitted.
- PO is partially received by Inventory Management.
- Received goods do not match the PO.
- PO is cancelled after goods have been partially received.
- Unit cost price is changed after submission.
- Sales submits a request for a non-routinely stocked product that cannot be matched to product master.
- Integration with Inventory, Product Master, Sales, or Finance is unavailable.

## 16. Dependencies

- Product master data must provide valid item, SKU, barcode, and unit of measure information.
- Inventory Management depends on Purchasing for PO data used during goods receipt matching.
- Inventory Management must return receipt status if Purchasing is expected to track partial or complete receipt.
- Sales may submit non-routinely stocked product requests requiring buyer action.
- Finance / Accounts Payable integration and automated finance event export are future scope for MVP.
- Supplier master data is required for PO supplier selection; ownership remains an architecture decision.

## 17. Assumptions

- Buyers are the primary users responsible for creating purchase orders.
- Purchase orders are required before goods can be booked into inventory, except for authorized receipt exceptions approved by an Inventory Supervisor and reviewed by Purchasing.
- Product, SKU, and barcode information is maintained through product master data.
- Unit cost price must be captured, but detailed accounting treatment is not defined.
- ACME works with approximately 10 to 20 active suppliers.
- Blanket purchase orders, recurring purchase orders, and partial release contracts are out of scope for the initial release.

## 18. Purchasing Decisions

- Purchase orders shall identify a supplier.
- Purchase orders over 10,000 require Purchasing Manager approval.
- Buyers cannot approve their own purchase orders.
- Expected arrival date is captured at PO header level and may be overridden at line level.
- Non-routinely stocked product requests from Sales enter a buyer review queue. The buyer may create a linked purchase order, reject the request with reason, or return the request for clarification.
- AP, invoice matching, tax, and payment processing are out of scope for the initial release except for optional event export.

## 19. MVP Scope Decisions

- Purchasing owns MVP supplier reference data for the 10 to 20 active ACME suppliers. Supplier onboarding, supplier lifecycle management, and a centralized supplier master are future scope.
- Finance/AP integration is fully deferred for MVP. Purchasing provides operational reports and CSV exports for finance visibility where needed.

## 20. Acceptance Summary

The Purchasing requirements shall be considered complete when authorized buyers can create supplier-backed purchase orders with required item, SKU, barcode, quantity, unit cost, purchase date, and expected arrival date data; PO statuses, approvals, amendments, and changes are auditable; PO data is available to Inventory Management for receipt matching; purchasing roles and controls are defined; purchasing reports support operational monitoring; and centralized supplier-master plus Finance/AP integration remain outside MVP scope.