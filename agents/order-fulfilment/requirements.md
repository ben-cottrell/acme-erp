# Requirements Specification: Order Fulfilment

## 1. Purpose

The purpose of the Order Fulfilment module is to support warehouse operators in identifying sales order components, packing those components, purchasing courier shipping, printing courier shipping labels, and marking orders as completed. The module shall ensure fulfilled components are taken from inventory and that fulfillment activity is traceable, controlled, and visible to Sales and Inventory Management.

## 2. Scope

### In Scope

- Receipt or access to sales orders released for fulfillment.
- Identification of components required for a sales order.
- Picking components from inventory.
- Packing picked components.
- Purchasing shipping from a courier.
- Printing courier shipping labels.
- Marking orders as completed.
- Updating inventory consumption and fulfillment status.
- Fulfillment reporting, audit trail, role-based access, and exception handling.

### Out of Scope

- Sales order creation and customer detail capture, which are owned by Sales.
- Purchase order creation and supplier purchasing, which are owned by Purchasing.
- Regular stock checks, goods receipt booking, and discrepancy adjustments, which are owned by Inventory Management.
- Detailed courier contract management, shipping rate negotiation, returns/RMA, failed delivery processing, customer refunds, tax, and invoicing for the initial release.

## 3. Business Context

Warehouse operators use the ERP module to identify the components of a sales order, pack the components, purchase shipping from a courier, print the courier shipping label, and mark the order as completed. Components of a sales order are taken from inventory. This module is therefore dependent on Sales for released order information, Inventory Management for stock availability and consumption, and courier services for shipment purchase and label generation.

## 4. Stakeholders and User Roles

| Role | Description | Key Responsibilities | Access Level |
|---|---|---|---|
| Warehouse Operator | Operational user responsible for fulfillment tasks. | Pick components, pack orders, purchase courier shipping, print labels, complete orders. | Create and update fulfillment records for assigned work. |
| Fulfilment Supervisor | Warehouse control owner. | Monitor fulfillment workload, resolve exceptions, approve overrides where required. | Review and supervisory action access. |
| Sales Assistant | Sales user dependent on fulfillment status. | View fulfillment progress and customer-impacting exceptions. | Read-only fulfillment status access for related sales orders. |
| Inventory Supervisor | Inventory control user. | Monitor stock consumption and fulfillment-related inventory exceptions. | Read fulfillment consumption events and exceptions. |
| Customer Service User | User supporting customer inquiries. | View shipment and completion status where applicable. | Read-only access to order shipment status. |
| Courier Integration User / Service Account | Technical identity for courier service interaction. | Purchase shipping and retrieve label data through integration. | Restricted integration access only. |
| System Administrator | Technical administrator for configuration and access. | Maintain fulfillment roles, courier settings, printer settings, and integration configuration. | Administrative access, excluding business approval authority unless assigned. |
| Auditor | Assurance user. | Review fulfillment activity, inventory consumption, courier transactions, and completion history. | Read-only access to audit and control reports. |

## 5. Business Process Overview

The fulfillment process begins when Sales releases a sales order for fulfillment. A warehouse operator identifies the components required for the order, picks components from inventory, records or confirms picked quantities, packs the order, purchases shipping from a courier, prints the courier shipping label, and marks the order as completed. The module updates Sales with fulfillment status and updates Inventory Management with reservation, consumption, or reversal events according to configured timing.

Primary statuses include Released, Picking, Pick Exception, Picked, Packing, Packed, Shipping Purchase Pending, Shipping Purchased, Label Printed, Partially Fulfilled, Completed, Cancelled, and Exception. Partial fulfilment is allowed when only part of an order can be shipped and the remaining quantity is returned to Sales as backordered.

## 6. Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|
| FUL-001 | The system shall allow authorized warehouse operators to view sales orders released for fulfillment. | Must | Given Sales releases an eligible order, when an authorized warehouse operator views the fulfillment queue, then the system shall display the released order and required fulfillment details. |
| FUL-002 | The system shall identify the components required for each released sales order. | Must | Given a sales order is released, when the operator opens the fulfillment task, then the system shall display the products, SKUs, quantities, and available component information required for the order. |
| FUL-003 | The system shall allow authorized warehouse operators to record picked components for a sales order. | Must | Given a fulfillment task is in Picking status, when the operator records picked quantities, then the system shall save the picked products, quantities, user, and timestamp. |
| FUL-004 | The system shall validate picked components against the sales order requirements. | Must | Given picked components are recorded, when the picked product or quantity differs from the sales order requirement, then the system shall flag a pick exception. |
| FUL-005 | The system shall update Inventory Management when components are consumed by fulfillment according to configured timing. | Must | Given components are picked, packed, or completed according to policy, when the consumption event occurs, then the system shall send inventory consumption details to Inventory Management. |
| FUL-006 | The system shall allow authorized warehouse operators to mark a sales order as packed after required components are confirmed. | Must | Given required components are picked or exceptions are resolved, when the operator packs the order, then the system shall update the fulfillment status to Packed. |
| FUL-007 | The system shall support purchasing shipping from a courier for a packed order. | Must | Given an order is ready for shipping, when an authorized operator purchases courier shipping, then the system shall submit required shipment details to the courier and record the shipping purchase result. |
| FUL-008 | The system shall support printing the courier shipping label. | Must | Given courier shipping has been purchased and label data is available, when the operator prints the label, then the system shall send the label to the configured printer or make it available for printing. |
| FUL-009 | The system shall allow authorized warehouse operators to mark an order as completed. | Must | Given required packing and shipping label steps are complete, when the operator marks the order completed, then the system shall update the fulfillment status and notify Sales of completion. |
| FUL-010 | The system shall track fulfillment status throughout the pick, pack, ship, and completion lifecycle. | Must | Given a fulfillment task changes status, when each operational step is completed or fails, then the system shall update status and retain status history. |
| FUL-011 | The system shall allow authorized users to record fulfillment exceptions. | Should | Given an issue occurs during picking, packing, shipping purchase, label printing, or completion, when the user records the exception, then the system shall store the exception type, details, user, timestamp, and current status. |
| FUL-012 | The system shall provide search and filtering for fulfillment tasks. | Should | Given an authorized user opens fulfillment tasks, when the user filters by sales order, status, SKU, shipment, courier status, or date, then the system shall return matching tasks. |

## 7. Business Rules

| ID | Rule | Applies To | Notes |
|---|---|---|---|
| FUL-BR-001 | Fulfillment shall begin only for sales orders released by Sales. | Fulfillment intake | Sales owns order creation and release. |
| FUL-BR-002 | Components of a sales order shall be taken from inventory. | Picking | Defined in source context. |
| FUL-BR-003 | Picked components shall be validated against sales order requirements before packing or completion. | Picking/Packing | Supports operational accuracy. |
| FUL-BR-004 | Courier shipping shall be purchased before a courier shipping label is printed, unless a manual exception process is authorized. | Shipping | MVP supports one courier provider path. UPS is the default first provider unless ACME supplies a different existing courier account before implementation starts. |
| FUL-BR-005 | Orders shall not be marked completed until required fulfillment steps are complete or authorized exceptions are recorded. | Completion | Completion requires picked quantities, packing confirmation, courier shipment purchase, label availability or approved manual exception, and successful or queued Sales and Inventory updates. |
| FUL-BR-006 | Inventory consumption shall be traceable to the fulfillment task and sales order. | Inventory integration | Supports auditability and stock control. |

## 8. Data Requirements

| Entity / Field | Description | Required | Validation / Constraints | Source |
|---|---|---|---|---|
| Fulfillment Task ID | Unique identifier for fulfillment work. | Yes | System generated and unique. | System generated |
| Sales Order Reference | Sales order being fulfilled. | Yes | Must reference a released sales order. | Sales |
| Product / Component | Item required for the sales order. | Yes | Must match sales order line or configured component definition. | Sales/Product master |
| SKU | Stock keeping unit picked from inventory. | Yes | Must map to product and inventory record. | Product master/Inventory |
| Required Quantity | Quantity required for fulfillment. | Yes | Derived from sales order. | Sales |
| Picked Quantity | Quantity picked by warehouse operator. | Yes when picking | Must be numeric and compared to required quantity. | Warehouse operator |
| Pack Status | Packing state of order. | Yes | Controlled values. | System generated |
| Courier | Shipping provider used. | Yes when shipping purchased | Must be valid configured courier. | Courier integration/configuration |
| Shipping Purchase Reference | Courier transaction or shipment reference. | Yes when shipping purchased | Must be unique or traceable to courier response. | Courier integration |
| Shipping Label | Label data or print reference. | Yes when label generated | Must be linked to shipping purchase reference. | Courier integration |
| Completion Status | Fulfillment completion state. | Yes | Controlled status values. | System generated |
| Inventory Consumption Reference | Link to inventory stock movement event. | Conditional | Required when stock consumption is posted. | Inventory Management |
| Audit Metadata | User, timestamp, status history, comments, exception details. | Yes | Must be retained according to audit policy. | System generated |

## 9. Workflow and Approval Requirements

1. Sales releases a sales order to Order Fulfilment.
2. Warehouse operator opens the fulfillment task.
3. System displays required components and quantities.
4. Warehouse operator picks components from inventory.
5. System validates picked components against sales order requirements.
6. Warehouse operator packs the order.
7. Warehouse operator purchases shipping from a courier.
8. System receives courier shipment and label information.
9. Warehouse operator prints the shipping label.
10. Warehouse operator marks the order as completed.
11. System updates Sales and Inventory Management according to integration rules.

Fulfilment Supervisor approval is required for pick exceptions, short picks, substitutions, partial fulfilment release, shipping overrides, cancellation after picking has started, and completion reversal. The operator who records the exception may not approve the related override.

## 10. Integration Requirements

| System | Direction | Data Exchanged | Frequency | Failure Handling |
|---|---|---|---|---|
| Sales | Inbound to Fulfilment | Released sales order, customer delivery context where needed, products, quantities, order status. | On fulfillment release. | The system shall reject incomplete release messages and log exceptions for reconciliation. |
| Sales | Outbound from Fulfilment | Fulfillment status, completion status, shipment references where applicable. | On fulfillment status changes. | The system shall queue or flag status updates if Sales is unavailable. |
| Inventory Management | Inbound to Fulfilment | Stock availability and component validation data. | At task opening, picking, and exception review. | The system shall prevent or flag picking if inventory validation cannot be completed. |
| Inventory Management | Outbound from Fulfilment | Stock consumption or reversal events linked to sales order and fulfillment task. | At configured consumption timing. | The system shall flag fulfillment tasks for review if inventory consumption posting fails. |
| Courier Service | Bidirectional | Shipment purchase request, service selection data, shipping purchase result, label data, tracking reference. | During shipping purchase and label generation. | The system shall place fulfillment task in courier exception status if purchase or label generation fails. |
| Product Master | Inbound to Fulfilment | Product, SKU, barcode, component attributes, handling instructions where applicable. | On fulfillment task creation or lookup. | The system shall flag unknown or inactive product data for review. |

## 11. Reporting and Analytics Requirements

| Report / Dashboard | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Fulfillment Queue Dashboard | Warehouse Operators, Fulfilment Supervisor | Show released orders awaiting pick, pack, ship, or completion. | Status, order age, SKU, channel, priority if defined. | Dashboard and CSV export. |
| Pick Exception Report | Fulfilment Supervisor, Inventory Supervisor | Track short picks, wrong items, damaged components, and unresolved exceptions. | Exception type, SKU, operator, date, status. | CSV export. |
| Shipping Purchase Report | Fulfilment Supervisor, Finance if applicable | Review courier shipping purchases and failures. | Courier, date, status, order, cost if provided. | CSV and spreadsheet export. |
| Label Printing Exception Report | Warehouse Operations | Track failed or reprinted labels. | Printer, courier, order, date, status. | CSV export. |
| Completed Orders Report | Sales, Warehouse, Auditor | Review orders marked completed. | Date range, operator, courier, status, sales order. | CSV and audit-ready PDF export. |
| Inventory Consumption Report | Inventory Supervisor, Auditor | Trace fulfillment-driven stock consumption. | SKU, order, task, operator, date. | CSV export. |

## 12. Security, Roles, and Permissions

- The system shall restrict fulfillment task updates to authorized warehouse users.
- The system shall restrict fulfillment exception overrides, completion reversals, and cancellation after picking to authorized supervisory roles.
- The system shall provide Sales users read-only visibility to fulfillment status for related orders.
- The system shall restrict courier service credentials to system-managed integration identities.
- The system shall prevent unauthorized users from purchasing courier shipping or printing labels.
- The system shall separate fulfillment completion from exception approval where segregation of duties policy requires it.

## 13. Audit and Compliance Requirements

- The system shall record user, timestamp, sales order reference, picked items, picked quantities, packing status, courier purchase status, label print status, and completion status.
- The system shall record all fulfillment exceptions, override actions, cancellation events, and completion reversals.
- The system shall record courier transaction references and label generation results where provided by the courier.
- The system shall record inventory consumption events with correlation to the sales order and fulfillment task.
- The system shall retain fulfillment operational audit records for 3 years and retain financially relevant shipping or completion evidence for 7 years.

## 14. Non-Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|
| FUL-NFR-001 | The system shall display released fulfillment tasks within an agreed response threshold. | Must | Given a warehouse operator opens the fulfillment queue, when the system is operational, then released tasks shall display within the agreed service level. |
| FUL-NFR-002 | The system shall maintain transactional integrity between fulfillment status and inventory consumption events. | Must | Given a stock consumption event is required, when the event fails, then the system shall not silently complete fulfillment without a recorded exception. |
| FUL-NFR-003 | The system shall handle courier service failures without losing fulfillment task state. | Must | Given courier purchase or label generation fails, when the failure occurs, then the system shall retain the task and record an actionable exception. |
| FUL-NFR-004 | The system shall support warehouse operation during agreed fulfillment working hours. | Must | Given fulfillment operations are active, when authorized users access core fulfillment functions, then the system shall be available according to agreed availability targets. |
| FUL-NFR-005 | The system shall support accessible fulfillment task entry and review. | Should | Given a user uses keyboard navigation or assistive technology, when reviewing or updating fulfillment tasks, then required controls shall be operable and identifiable. |

## 15. Exceptions and Edge Cases

- Sales order release message is incomplete or invalid.
- Required component is unavailable in inventory.
- Picked product differs from sales order requirement.
- Picked quantity is less than required quantity.
- Picked item is damaged.
- Inventory consumption posting fails.
- Courier shipping purchase fails.
- Courier label generation fails.
- Label printer is unavailable or label must be reprinted.
- Order is cancelled after picking or packing has started.
- Shipment is purchased but order completion fails.
- Fulfillment completion update fails to reach Sales.
- Inventory availability changes during picking.

## 16. Dependencies

- Sales must release eligible sales orders with required product and quantity details.
- Inventory Management must provide stock availability and accept stock consumption events.
- Product master must provide product, SKU, barcode, and component information.
- Courier service integration must support shipping purchase and label generation.
- Printer configuration must support shipping label output where physical labels are printed.
- Finance may require shipping cost data if courier cost accounting is in scope.

## 17. Assumptions

- Warehouse operators are the primary users of Order Fulfilment.
- Sales owns sales order creation and release decisions.
- Inventory Management owns stock balance updates, while Order Fulfilment initiates consumption events.
- Courier shipping purchase and label printing are required before order completion unless an authorized exception is defined.
- Shipping purchase requires ship-from, ship-to, package weight and dimensions, service level, customer contact, sales order reference, and package count where applicable.
- Label output shall support PDF for general browser or operating system printing in MVP. ZPL and printer-model-specific handling are future scope.
- Inventory is reserved at fulfilment release and consumed at fulfilment completion. Authorized reversals are required for cancellation or correction after consumption.

## 18. Fulfilment Decisions

- MVP supports one courier provider path. UPS is the default first provider unless ACME supplies a different existing courier account before implementation starts.
- Shipping purchase requires ship-from, ship-to, package weight and dimensions, service level, customer contact, sales order reference, and package count where applicable.
- Shipping costs and selected service levels shall be recorded for operational visibility. Customer delivery promise logic is out of scope for the initial release.
- Inventory is consumed at fulfilment completion after pick, pack, shipping purchase, and label generation are complete or an approved manual exception exists.
- Partial fulfilment is allowed and must report remaining quantity to Sales as backordered.
- Fulfilment Supervisors approve pick exceptions, short picks, substitutions, completion overrides, and cancellation after picking starts.
- Orders may be cancelled before picking by Sales. After picking starts, cancellation requires Fulfilment Supervisor approval and inventory reversal handling. After shipping purchase, cancellation requires courier cancellation support or manual exception handling.
- Returns, failed delivery, re-shipment, and shipment cancellation workflows are out of scope for the initial release except for recording a manual exception.
- Label printing shall support PDF/browser printing for MVP. ZPL and direct thermal-printer integration are future scope.

## 19. MVP Scope Decisions

- UPS is the default first courier provider unless ACME supplies a different existing courier account before implementation starts. Additional courier providers are future scope.
- Physical label printer model support is out of scope for MVP. MVP label printing uses PDF labels through browser or operating system print handling.

## 20. Acceptance Summary

The Order Fulfilment requirements shall be considered complete when authorized warehouse operators can view released sales orders, identify required components, pick and pack inventory components, purchase courier shipping through the MVP provider path, print PDF shipping labels, complete or partially fulfil orders, update Sales and Inventory Management, handle fulfillment exceptions, maintain auditable fulfillment and inventory consumption history, enforce role-based controls, report fulfillment activity, and keep multi-courier routing plus printer-model-specific handling outside MVP scope.