# Application Requirements: Fulfilment Supervisor

## Purpose

The Fulfilment Supervisor application supports fulfilment control users who monitor fulfilment workload, resolve pick/pack/ship/completion exceptions, approve overrides, review partial fulfilment, and oversee completion reversals or cancellations after picking starts.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.FulfilmentSupervisor.Ui` |
| API | `Acme.Erp.FulfilmentSupervisor.Api` |
| Primary users | Fulfilment Supervisor |
| Database | None |
| Domain APIs consumed | Order Fulfilment, Sales, Inventory Management |

The Fulfilment Supervisor UI calls only the Fulfilment Supervisor API. The Fulfilment Supervisor API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Monitor fulfilment queues by status, age, SKU, channel, and exception type.
- Review pick exceptions, short picks, substitutions, damaged components, shipping overrides, label failures, and completion exceptions.
- Approve or reject controlled fulfilment exceptions through Order Fulfilment.
- Review inventory consumption failures and coordinate with Inventory Management state.
- Review released sales order and customer delivery context where needed and allowed.
- Provide pick exception, shipping purchase, label printing exception, completed orders, and inventory consumption reports.

## Functional Requirements

| ID | Requirement |
|---|---|
| FSU-APP-001 | The application shall display fulfilment workload and exception queues from Order Fulfilment. |
| FSU-APP-002 | The application shall show Sales and Inventory Management context needed for exception decisions without local persistence. |
| FSU-APP-003 | The application shall allow authorized supervisors to approve or reject pick exceptions, short picks, substitutions, partial fulfilment release, shipping overrides, cancellation after picking starts, and completion reversals. |
| FSU-APP-004 | The application shall prevent self-approval actions when Order Fulfilment reports a SoD conflict. |
| FSU-APP-005 | The application shall support filtering by exception type, SKU, operator, date, courier, order, and status. |
| FSU-APP-006 | The application shall provide accessible supervisor review and exception handling screens. |

## Security and Audit

Order Fulfilment remains authoritative for exception approval, override state, completion reversal state, cancellation-after-picking state, courier records, and audit history.
