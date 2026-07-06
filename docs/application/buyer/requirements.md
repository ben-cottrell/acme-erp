# Application Requirements: Buyer

## Purpose

The Buyer application supports buyers and purchasing managers who create purchase orders, maintain expected arrival information, review non-routinely stocked product requests, monitor receipt status, and approve controlled purchasing actions.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.Buyer.Ui` |
| API | `Acme.Erp.Buyer.Api` |
| Primary users | Buyer, Purchasing Manager |
| Database | None |
| Domain APIs consumed | Purchasing, Sales, Inventory Management |

The Buyer UI calls only the Buyer API. The Buyer API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Create and amend purchase orders through Purchasing.
- Select suppliers and products from Purchasing and Inventory Management contracts.
- Capture item, SKU, barcode where available, quantity, unit cost, purchase date, and expected arrival date.
- Submit purchase orders and route approval actions to Purchasing.
- Review non-routinely stocked product requests from Sales and create linked POs, reject requests, or return them for clarification.
- View receipt status, partial receipt state, and receipt exceptions returned from Inventory Management through Purchasing.
- Provide open PO, expected arrivals, amendment history, receipt exception, and purchase cost views.

## Functional Requirements

| ID | Requirement |
|---|---|
| BYR-APP-001 | The application shall allow authorized buyers to create and update purchase orders through the Purchasing domain API. |
| BYR-APP-002 | The application shall display product/SKU/barcode validation results from Inventory Management without storing product master data locally. |
| BYR-APP-003 | The application shall allow Purchasing Managers to review and approve controlled purchasing actions where Purchasing reports approval is required. |
| BYR-APP-004 | The application shall prevent buyer approval actions in the UI when Purchasing reports a self-approval conflict. |
| BYR-APP-005 | The application shall allow buyers to process Sales-originated non-stocked product requests through Purchasing. |
| BYR-APP-006 | The application shall support search and filtering by PO number, SKU, barcode, expected arrival date, status, supplier, and buyer. |
| BYR-APP-007 | The application shall provide accessible PO entry, approval, and review screens. |

## Security and Audit

The application can hide unavailable actions for usability, but Purchasing remains authoritative for purchase order validation, approval rules, SoD, persistence, and audit history.
