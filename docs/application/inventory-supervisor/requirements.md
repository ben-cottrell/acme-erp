# Application Requirements: Inventory Supervisor

## Purpose

The Inventory Supervisor application supports inventory control users who review stock discrepancies, approve adjustments where authorized, monitor goods receipt exceptions, and review inventory accuracy and stock movement history.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.InventorySupervisor.Ui` |
| API | `Acme.Erp.InventorySupervisor.Api` |
| Primary users | Inventory Supervisor |
| Database | None |
| Domain APIs consumed | Inventory Management, Purchasing, Order Fulfilment |

The Inventory Supervisor UI calls only the Inventory Supervisor API. The Inventory Supervisor API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Review stock count discrepancies, variance calculations, adjustment reasons, and approval requirements.
- Review goods receipt mismatches, under-receipts, over-receipts, damaged goods, quarantine, and rejected receipt states.
- Approve or reject inventory adjustments and receipt exceptions through Inventory Management.
- View related purchase order context from Purchasing where needed for receipt exception decisions.
- Monitor fulfilment-driven consumption exceptions from Order Fulfilment and Inventory Management.
- Provide discrepancy, goods receipt exception, stock movement, and pending review dashboards.

## Functional Requirements

| ID | Requirement |
|---|---|
| ISU-APP-001 | The application shall display inventory discrepancies and receipt exceptions requiring supervisor review. |
| ISU-APP-002 | The application shall show related PO context without copying Purchasing data into a local database. |
| ISU-APP-003 | The application shall submit approval, rejection, or investigation outcomes to Inventory Management. |
| ISU-APP-004 | The application shall prevent self-approval actions when Inventory Management reports a SoD conflict. |
| ISU-APP-005 | The application shall support filtering by age, status, location, SKU, variance, supplier, PO, and exception type. |
| ISU-APP-006 | The application shall provide accessible supervisor review and approval screens. |

## Security and Audit

Inventory Management remains authoritative for discrepancy approval, adjustment posting, receipt exception resolution, stock movements, SoD checks, and audit records.
