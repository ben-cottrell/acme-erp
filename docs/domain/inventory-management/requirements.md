# Domain Requirements: Inventory Management

## Purpose

The Inventory Management domain owns the stock system of record, product/SKU/barcode/stocking configuration for the MVP, stock balances, reservations, goods receipts, stock checks, discrepancy state, stock movements, and inventory audit records.

Inventory Management is a domain bounded context. It exposes WebAPI contracts and owns the Inventory database. It does not own a UI. Warehouse, supervisor, sales, fulfilment, and reporting experiences belong to application services.

## Domain Scope

### In Scope

- Product, SKU, barcode, stocking, and serialized-product configuration for MVP.
- Recorded stock balances, availability, reservations, non-available stock states, and stock movement history.
- Stock checks, actual count capture, variance calculation, discrepancy review state, and authorized adjustment posting.
- Goods receipt state, purchase order matching, receipt exception state, and stock booking.
- Availability, reservation, consumption, and reversal contracts for Sales and Order Fulfilment.
- Inventory audit records and inventory reporting endpoints.

### Out of Scope

- Razor Pages UI or warehouse data-entry screens.
- Purchase order authoring and supplier purchasing workflow.
- Sales order authoring and customer-facing order intake.
- Physical picking, packing, courier shipping purchase, and label printing.
- Accounting postings, landed cost calculations, returns/RMA, tax handling, and warehouse automation hardware integration for the MVP.

## Domain API Responsibilities

| Area | Requirement |
|---|---|
| Stock checks | Maintain stock check records, actual counts, variance calculations, discrepancy state, and adjustment posting. |
| Goods receipts | Validate received product identifiers and quantities against Purchasing PO data before booking stock. |
| Stock system of record | Maintain non-negative recorded balances, non-available states, reservations, and immutable stock movements. |
| Availability | Provide real-time or near-real-time availability to Sales and Order Fulfilment. |
| Reservation and consumption | Reserve stock at fulfilment release and consume stock at fulfilment completion. |
| Product master for MVP | Own product/SKU/barcode/stocking and serialized-product configuration until a dedicated product master is introduced. |
| Authorization and audit | Enforce inventory permissions, discrepancy/receipt approval rules, SoD rules, idempotency, and inventory audit events. |

## Domain Business Rules

| ID | Rule |
|---|---|
| INV-DOM-001 | Inventory checks shall compare actual stock against recorded stock for the same product, SKU, barcode, and location. |
| INV-DOM-002 | Goods receipt booking shall validate products and quantities against purchase orders before increasing available inventory. |
| INV-DOM-003 | Unmatched receipt exceptions shall not update available inventory until resolved or authorized according to configured policy. |
| INV-DOM-004 | Inventory discrepancies shall not update recorded stock until reviewed or resolved according to configured authority. |
| INV-DOM-005 | Adjustments over 2,000 value or 10 percent variance require Inventory Supervisor approval according to configurable policy. |
| INV-DOM-006 | The user who recorded a count or receipt exception may not approve the related adjustment. |
| INV-DOM-007 | Every inventory balance change shall be traceable to a source document or authorized manual adjustment. |
| INV-DOM-008 | Negative inventory balances are prohibited. |
| INV-DOM-009 | Reservations reduce available-to-promise quantity at fulfilment release. |
| INV-DOM-010 | Fulfilment consumption creates stock movement records at fulfilment completion. |
| INV-DOM-011 | Damaged goods, quarantine stock, and rejected receipts are non-available stock states pending review or supplier return/disposal action. |
| INV-DOM-012 | Serial number tracking is required for serialized computer systems and serialized components; lot and expiry tracking are out of scope unless later configured for specific products. |

## Data Ownership

| Entity / Field | Ownership |
|---|---|
| Product, SKU, Barcode, Stocking Configuration, Serial Configuration | Owned by Inventory Management for MVP. |
| Recorded Quantity, Available Quantity, Reservation, Stock Movement | Owned by Inventory Management. |
| Stock Check, Actual Count, Variance, Discrepancy, Adjustment | Owned by Inventory Management. |
| Goods Receipt and Receipt Status | Owned by Inventory Management. |
| Purchase Order Reference | Owned by Purchasing; Inventory stores external PO IDs and copied receipt-matching data. |
| Fulfilment Task Reference and Sales Order Reference | Owned by Order Fulfilment and Sales respectively; Inventory stores external IDs for reservation/consumption traceability. |
| Audit Metadata | Inventory Management owns inventory audit events and movement history. |

## Integration Contracts

| Target or source | Direction | Contract responsibility |
|---|---|---|
| Purchasing | Inbound to Inventory | Purchase order header, PO lines, item, SKU, barcode, ordered quantity, unit cost, purchase date, expected arrival date, and PO status. |
| Purchasing | Outbound from Inventory | Receipt status, received quantities, receipt exceptions, and receipt dates. |
| Sales | Outbound from Inventory | Product availability and current inventory levels during order entry, validation, and release checks. |
| Order Fulfilment | Bidirectional | Availability, reservation, stock consumption, and reversal contracts. |
| Application APIs | Inbound to Inventory | Commands and queries from Warehouse Operator, Inventory Supervisor, Sales Assistant, Fulfilment Operator, and reporting applications. |

## Application Requirements Moved Out

Warehouse stock-count screens, goods-receipt screens, barcode entry UX, inventory supervisor review dashboards, pending review queues, search/filter presentation, and accessibility requirements for inventory screens are documented under `docs/application/`.
