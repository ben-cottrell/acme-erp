# Application Requirements: Warehouse Operator

## Purpose

The Warehouse Operator application supports warehouse users who perform stock counts and book in received goods. This workload crosses Inventory Management and Purchasing because goods receipt requires purchase order details and stock updates.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.WarehouseOperator.Ui` |
| API | `Acme.Erp.WarehouseOperator.Api` |
| Primary users | Warehouse Operator |
| Database | None |
| Domain APIs consumed | Inventory Management, Purchasing |

The Warehouse Operator UI calls only the Warehouse Operator API. The Warehouse Operator API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Create or open stock count tasks and record actual counted quantities.
- Display recorded stock quantities returned by Inventory Management.
- Capture product, SKU, barcode, location, count date, and operator identity through Inventory commands.
- Select purchase orders available for receipt through Purchasing-backed lookup.
- Display expected products, SKUs, barcodes, quantities, and expected arrival data for receiving.
- Record received goods and submit them to Inventory Management for PO matching and stock booking.
- Show receipt mismatch, under-receipt, over-receipt, damaged goods, quarantine, and rejected receipt states.

## Functional Requirements

| ID | Requirement |
|---|---|
| WHO-APP-001 | The application shall allow authorized warehouse operators to start stock checks through Inventory Management. |
| WHO-APP-002 | The application shall display recorded stock and allow actual count entry without storing inventory balances locally. |
| WHO-APP-003 | The application shall allow operators to select or scan products, SKUs, barcodes, and locations for count and receipt workflows. |
| WHO-APP-004 | The application shall allow operators to start goods receipts against purchase orders by orchestrating Purchasing lookup and Inventory receipt commands. |
| WHO-APP-005 | The application shall display PO matching results and receipt exceptions returned by Inventory Management. |
| WHO-APP-006 | The application shall route discrepancy and receipt exception review to supervisor applications rather than approving them locally. |
| WHO-APP-007 | The application shall provide accessible warehouse data-entry screens suitable for keyboard and scanner-assisted operation. |

## Security and Audit

Inventory Management remains authoritative for stock check, receipt, stock movement, discrepancy, and audit records. Purchasing remains authoritative for purchase order data. The application shall not bypass domain approval rules for discrepancies or receipt exceptions.
