# Domain Requirements: Purchasing

## Purpose

The Purchasing domain owns supplier-backed purchase orders, supplier reference data for the MVP, purchasing approval state, buyer request queue state, purchase order receipt visibility, and purchasing audit records.

Purchasing is a domain bounded context. It exposes WebAPI contracts and owns the Purchasing database. It does not own a UI. Buyer, purchasing manager, warehouse, and reporting experiences belong to application services.

## Domain Scope

### In Scope

- Purchase order creation, validation, status transitions, amendments, cancellation, approval state, and audit history.
- Supplier reference data for the 10 to 20 active ACME suppliers in the MVP.
- Buyer request queue state for non-routinely stocked product requests from Sales.
- Purchase order lookup contracts for Inventory Management goods receipt matching.
- Receipt status read models and receipt exception visibility returned by Inventory Management.
- Purchasing reporting endpoints and CSV/export source data.

### Out of Scope

- Razor Pages UI or buyer workbench behaviour.
- Physical goods receipt and stock booking.
- Sales order capture and customer communication.
- Supplier onboarding, contract management, tendering, and supplier performance scoring unless separately requested.
- Accounts payable posting, invoice matching, tax calculation, landed cost allocation, and payment processing for the MVP.

## Domain API Responsibilities

| Area | Requirement |
|---|---|
| Purchase orders | Accept purchase order commands from authorized application APIs and maintain PO state. |
| Required PO data | Store supplier, item, SKU, barcode where available, quantity ordered, unit cost, purchase date, and expected arrival date. |
| Approval controls | Enforce configurable purchasing approval thresholds and self-approval prevention. |
| Buyer requests | Receive non-routinely stocked product requests from Sales and maintain buyer decision state. |
| Inventory receipt support | Provide eligible PO details to Inventory Management and consume receipt status updates. |
| Authorization and audit | Enforce purchasing permissions, controlled amendment/cancellation rules, SoD rules, idempotency, and purchasing audit events. |

## Domain Business Rules

| ID | Rule |
|---|---|
| PUR-DOM-001 | Purchase orders shall identify a supplier. |
| PUR-DOM-002 | Purchase orders shall contain item, SKU, barcode where available, quantity ordered, unit cost price, purchase date, and expected arrival date. |
| PUR-DOM-003 | Quantity ordered shall be positive and numeric. |
| PUR-DOM-004 | Unit cost price shall be captured for each purchased item line using the configured company currency unless multi-currency is later enabled. |
| PUR-DOM-005 | Purchase orders used for inventory booking shall be available to Inventory Management. |
| PUR-DOM-006 | Purchase orders over 10,000 require Purchasing Manager approval according to configurable policy. |
| PUR-DOM-007 | Buyers may not approve their own purchase orders. |
| PUR-DOM-008 | Buyers may amend draft purchase orders without approval. |
| PUR-DOM-009 | Post-submission amendments to supplier, quantity, unit cost, expected arrival date, or cancellation require audit reason and Purchasing Manager approval when the PO has already been approved, ordered, or partially received. |
| PUR-DOM-010 | Sales buyer requests may be accepted into the buyer queue, linked to a PO, rejected with reason, or returned for clarification. |

## Data Ownership

| Entity / Field | Ownership |
|---|---|
| Purchase Order, Purchase Order Line, PO Status, Amendment History | Owned by Purchasing. |
| Supplier reference data for MVP | Owned by Purchasing until a dedicated supplier master is introduced. |
| Buyer request queue state | Purchasing owns buyer review decisions; Sales owns originating sales request context. |
| Received Quantity and Receipt Status read model | Originates in Inventory Management; Purchasing stores copied receipt visibility where required. |
| Product/SKU/barcode reference data | Owned by Inventory Management for MVP; Purchasing stores external IDs or copied read models. |
| Audit Metadata | Purchasing owns purchasing audit events and status history. |

## Integration Contracts

| Target or source | Direction | Contract responsibility |
|---|---|---|
| Inventory Management | Outbound from Purchasing | PO header, PO lines, item, SKU, barcode, ordered quantity, unit cost, purchase date, expected arrival date, and PO status for receipt matching. |
| Inventory Management | Inbound to Purchasing | Received quantities, receipt status, receipt exceptions, and receipt dates. |
| Sales | Inbound to Purchasing | Non-routinely stocked product requests requiring buyer action. |
| Inventory Management | Inbound to Purchasing | Product, SKU, barcode, unit of measure, and active/inactive status for product validation where needed. |
| Application APIs | Inbound to Purchasing | Commands and queries from Buyer, Sales Assistant, Warehouse Operator, and reporting applications. |

## Application Requirements Moved Out

Buyer workbench screens, purchasing manager approval views, expected arrivals dashboards, open PO search/filter UX, warehouse-facing PO lookup presentation, and accessibility requirements for purchasing screens are documented under `docs/application/`.
