# Domain Requirements: Sales

## Purpose

The Sales domain owns sales order state, customer account reference data for the MVP, order channels, buyer request state, fulfilment release decisions, sales status history, and sales audit records.

Sales is a domain bounded context. It exposes WebAPI contracts and owns the Sales database. It does not own a UI. User-facing order entry, customer ordering, dashboards, and review screens belong to application services.

## Domain Scope

### In Scope

- Sales order creation, validation, status transitions, cancellation rules, and release-to-fulfilment state.
- MVP customer account reference data required for B2B order capture.
- Sales channel recording for internal and customer-originated orders.
- Buyer request state for non-routinely stocked products.
- Availability and product lookup contracts consumed during sales workflows.
- Fulfilment status read models and reconciliation state.
- Sales audit records and domain reporting endpoints.

### Out of Scope

- Razor Pages UI or user-facing order entry flow.
- Physical picking, packing, courier shipping purchase, and label printing.
- Purchase order authoring and buyer workbench behaviour.
- Stock balance updates, stock checks, goods receipt booking, and inventory adjustment.
- Pricing, promotions, tax, payment capture, invoicing, credit management, returns/RMA, and revenue recognition for the MVP.

## Domain API Responsibilities

| Area | Requirement |
|---|---|
| Sales order intake | Accept validated sales order commands from application APIs and authenticated integration channels. |
| Status lifecycle | Maintain Draft, Submitted, Confirmed, Pending Inventory, Pending Buyer Request, Released to Fulfilment, Partially Fulfilled, Backordered, Completed, Cancelled, and Exception states. |
| Availability decisions | Query Inventory Management for stocked-product availability during validation and release checks. |
| Buyer requests | Create and track non-routinely stocked product requests and exchange status with Purchasing. |
| Fulfilment release | Release eligible sales orders to Order Fulfilment and retain release exception state when handoff fails. |
| Completion updates | Receive fulfilment completion, partial fulfilment, shipment references, and exception updates from Order Fulfilment. |
| Authorization and audit | Enforce sales permissions, controlled amendment/cancellation approval rules, SoD rules, idempotency, and sales audit events. |

## Domain Business Rules

| ID | Rule |
|---|---|
| SAL-DOM-001 | Sales orders shall capture customer account, customer contact, billing address, shipping address, product, SKU where applicable, quantity, and channel before confirmation. |
| SAL-DOM-002 | Sales orders shall identify the originating channel. |
| SAL-DOM-003 | Stocked sales order lines shall use active product/SKU data from Inventory Management. |
| SAL-DOM-004 | Sales shall check availability during order entry and recheck availability at fulfilment release. |
| SAL-DOM-005 | Inventory shall be reserved only when Sales releases an eligible order to Order Fulfilment. |
| SAL-DOM-006 | Non-routinely stocked products shall be routed to Purchasing through a buyer request process. |
| SAL-DOM-007 | Sales orders shall not be released to Order Fulfilment until required customer, channel, product, quantity, availability, and approval conditions are satisfied. |
| SAL-DOM-008 | Sales overrides and post-confirmation cancellations over 5,000 require Sales Supervisor approval according to configurable policy. |
| SAL-DOM-009 | Confirmed orders may be amended before fulfilment release by authorized users; released-order amendments require Sales Supervisor approval and coordination with Order Fulfilment. |
| SAL-DOM-010 | Duplicate customer website submissions shall be detected using customer account, source channel, idempotency key or submission correlation identifier, order timestamp, and matching order lines. |

## Data Ownership

| Entity / Field | Ownership |
|---|---|
| Sales Order, Sales Order Line, Sales Channel, Sales Order Status | Owned by Sales. |
| Customer account reference data for MVP | Owned by Sales until a dedicated customer master is introduced. |
| Buyer Request ID and status read model | Sales owns originating request context; Purchasing owns buyer queue decision state. |
| Fulfilment Reference and fulfilment status read model | Sales stores external fulfilment IDs and copied status needed for sales visibility. |
| Inventory availability | Owned by Inventory Management; Sales stores only transient validation results or explicit read models where needed. |
| Audit Metadata | Sales owns sales audit events and status history. |

## Integration Contracts

| Target or source | Direction | Contract responsibility |
|---|---|---|
| Inventory Management | Inbound to Sales | Product availability and stocked-product status for validation and release checks. |
| Purchasing | Outbound from Sales | Non-routinely stocked product request with customer/order context and requested product details. |
| Purchasing | Inbound to Sales | Buyer request status updates. |
| Order Fulfilment | Outbound from Sales | Released sales order details and components required for fulfilment. |
| Order Fulfilment | Inbound to Sales | Fulfilment status, completion, partial fulfilment, backorder, shipment reference, and exception updates. |
| Application APIs | Inbound to Sales | Commands and queries from Sales Assistant, Customer Ordering, and other authorized applications. |

## Application Requirements Moved Out

Sales Assistant order-entry screens, customer ordering screens, customer order status views, sales dashboards, search/filter UX, website intake presentation, and accessibility requirements for user screens are documented under `docs/application/`.
