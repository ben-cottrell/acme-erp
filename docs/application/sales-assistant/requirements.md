# Application Requirements: Sales Assistant

## Purpose

The Sales Assistant application supports internal sales users who capture customer details, create sales orders, review inventory availability, submit non-stocked product requests, release eligible orders, and monitor fulfilment status.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.SalesAssistant.Ui` |
| API | `Acme.Erp.SalesAssistant.Api` |
| Primary users | Sales Assistant, Sales Supervisor |
| Database | None |
| Domain APIs consumed | Sales, Inventory Management, Purchasing, Order Fulfilment |

The Sales Assistant UI calls only the Sales Assistant API. The Sales Assistant API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Capture customer account, order contact, billing address, shipping address, customer reference, and sales channel.
- Search active products, SKUs, and barcodes using Inventory Management data surfaced through the application API.
- Display current availability or availability status during order entry.
- Submit and amend sales orders through the Sales domain API.
- Submit non-routinely stocked product requests to Sales, which coordinates with Purchasing.
- Release eligible sales orders to fulfilment through the Sales domain API.
- Display buyer request status, fulfilment status, backorder state, exceptions, and completion status.
- Provide sales order search, filtering, order change history, and exception dashboards.

## Functional Requirements

| ID | Requirement |
|---|---|
| SA-APP-001 | The application shall allow authorized sales assistants to create and update sales orders by orchestrating Sales and Inventory Management APIs. |
| SA-APP-002 | The application shall display inventory availability during order entry without storing inventory balances locally. |
| SA-APP-003 | The application shall allow sales users to submit non-routinely stocked product requests without directly writing Purchasing data. |
| SA-APP-004 | The application shall expose order release actions only when the Sales domain reports that release criteria are satisfied. |
| SA-APP-005 | The application shall show fulfilment status and exceptions from Sales and Order Fulfilment read contracts. |
| SA-APP-006 | The application shall support search and filtering by customer, channel, product, status, date, and request state. |
| SA-APP-007 | The application shall provide accessible order entry and review screens for keyboard and assistive technology use. |

## Security and Audit

The application enforces route-level and screen-level authorization for user experience, but the Sales, Inventory Management, Purchasing, and Order Fulfilment domain APIs remain authoritative for business authorization, SoD, validation, persistence, and audit decisions.
