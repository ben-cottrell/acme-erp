# Application Requirements: Customer Ordering

## Purpose

The Customer Ordering application supports authenticated B2B customer users who submit website-originated sales orders and view their own order status where customer account access is enabled.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.CustomerOrdering.Ui` |
| API | `Acme.Erp.CustomerOrdering.Api` |
| Primary users | Authenticated Customer |
| Database | None |
| Domain APIs consumed | Sales, Inventory Management |

The Customer Ordering UI calls only the Customer Ordering API. The Customer Ordering API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Authenticate customers through Authentik/OIDC as routed by Gravitee.
- Display active products and availability indicators appropriate for customer ordering.
- Capture customer order details, billing/shipping details, product lines, quantities, and submission context.
- Submit orders to the Sales domain API with website channel and idempotency context.
- Display customer-visible order statuses for the authenticated customer's own orders.
- Prevent guest checkout and anonymous order tracking for the MVP.

## Functional Requirements

| ID | Requirement |
|---|---|
| CO-APP-001 | The application shall require authenticated customer identity before order submission or customer-specific order visibility. |
| CO-APP-002 | The application shall submit customer orders to Sales without directly owning sales order data. |
| CO-APP-003 | The application shall provide idempotency or submission correlation data for duplicate website submission detection. |
| CO-APP-004 | The application shall show only the authenticated customer's own order status information. |
| CO-APP-005 | The application shall display Submitted, Confirmed, Pending Inventory, Pending Buyer Request, Released to Fulfilment, Partially Fulfilled, Backordered, Completed, Cancelled, and Exception statuses when exposed by Sales. |
| CO-APP-006 | The application shall provide accessible customer order submission and order status screens. |

## Security and Audit

The application must protect customer personal data through customer-scoped queries, route authorization, and privacy-conscious presentation. Sales remains authoritative for customer order persistence, duplicate detection, audit records, and customer data access decisions.
