# Domain Requirements: Order Fulfilment

## Purpose

The Order Fulfilment domain owns fulfilment task state, pick/pack/ship/completion rules, courier shipment purchase records, label references, fulfilment exceptions, fulfilment status history, and fulfilment audit records.

Order Fulfilment is a domain bounded context. It exposes WebAPI contracts and owns the Fulfilment database. It does not own a UI. Fulfilment operator, supervisor, sales visibility, and reporting experiences belong to application services.

## Domain Scope

### In Scope

- Receipt of released sales order details from Sales.
- Fulfilment task creation and lifecycle state.
- Component requirement, picked quantity, packing, shipping purchase, label reference, completion, partial fulfilment, cancellation, and exception state.
- Courier integration records for the MVP provider path.
- Inventory reservation, consumption, and reversal request contracts.
- Fulfilment status updates to Sales.
- Fulfilment audit records and fulfilment reporting endpoints.

### Out of Scope

- Razor Pages UI or warehouse operator screens.
- Sales order creation and customer detail capture.
- Purchase order creation and supplier purchasing.
- Stock balance authority, regular stock checks, goods receipt booking, and discrepancy adjustment.
- Courier contract management, shipping rate negotiation, returns/RMA, failed delivery processing, refunds, tax, and invoicing for the MVP.

## Domain API Responsibilities

| Area | Requirement |
|---|---|
| Fulfilment intake | Accept released sales order contracts from Sales and create fulfilment tasks. |
| Pick/pack/ship lifecycle | Maintain Released, Picking, Pick Exception, Picked, Packing, Packed, Shipping Purchase Pending, Shipping Purchased, Label Printed, Partially Fulfilled, Completed, Cancelled, and Exception states. |
| Picking validation | Validate picked components against sales order requirements and inventory data. |
| Courier records | Record shipping purchase result, label data/reference, tracking reference, and courier exceptions. |
| Completion | Complete only when required steps or approved exceptions are present, then update Sales and Inventory Management. |
| Partial fulfilment | Report remaining quantities to Sales as backordered. |
| Authorization and audit | Enforce fulfilment permissions, exception approval rules, SoD rules, idempotency, and fulfilment audit events. |

## Domain Business Rules

| ID | Rule |
|---|---|
| FUL-DOM-001 | Fulfilment shall begin only for sales orders released by Sales. |
| FUL-DOM-002 | Components of a sales order shall be taken from Inventory Management. |
| FUL-DOM-003 | Picked components shall be validated against sales order requirements before packing or completion. |
| FUL-DOM-004 | Courier shipping shall be purchased before a courier shipping label is printed unless a manual exception process is authorized. |
| FUL-DOM-005 | Orders shall not be marked completed until picked quantities, packing confirmation, courier shipment purchase, label availability or approved manual exception, and required Sales/Inventory updates are successful or queued with visible exception state. |
| FUL-DOM-006 | Inventory consumption shall be traceable to fulfilment task and sales order. |
| FUL-DOM-007 | Inventory is consumed at fulfilment completion after pick, pack, shipping purchase, and label generation are complete or an approved manual exception exists. |
| FUL-DOM-008 | Partial fulfilment is allowed and must report remaining quantity to Sales as backordered. |
| FUL-DOM-009 | Fulfilment Supervisor approval is required for pick exceptions, short picks, substitutions, partial fulfilment release, shipping overrides, cancellation after picking starts, and completion reversal. |
| FUL-DOM-010 | The operator who records an exception may not approve the related override. |
| FUL-DOM-011 | MVP supports one courier provider path. Royal Mail is the default first provider unless ACME supplies a different existing courier account before implementation starts. |

## Data Ownership

| Entity / Field | Ownership |
|---|---|
| Fulfilment Task, Pick, Pack, Shipment Purchase, Label Reference, Completion Status | Owned by Order Fulfilment. |
| Sales Order Reference and Sales Order Line Reference | Owned by Sales; Order Fulfilment stores external IDs and release payload data. |
| Product/SKU/component reference data | Owned by Inventory Management for MVP; Order Fulfilment stores external IDs or copied task data. |
| Inventory Reservation and Stock Movement Reference | Owned by Inventory Management; Order Fulfilment stores external IDs for traceability. |
| Courier transaction and label reference | Owned by Order Fulfilment as operational fulfilment evidence. |
| Audit Metadata | Order Fulfilment owns fulfilment audit events and status history. |

## Integration Contracts

| Target or source | Direction | Contract responsibility |
|---|---|---|
| Sales | Inbound to Fulfilment | Released sales order, customer delivery context where needed, products, quantities, and order status. |
| Sales | Outbound from Fulfilment | Fulfilment status, completion, partial fulfilment, backorder, shipment references, and exceptions. |
| Inventory Management | Inbound to Fulfilment | Stock availability, reservation status, and component validation data. |
| Inventory Management | Outbound from Fulfilment | Stock consumption and reversal events linked to sales order and fulfilment task. |
| Courier Service | Bidirectional | Shipment purchase request, service selection data, shipping purchase result, label data, and tracking reference. |
| Application APIs | Inbound to Fulfilment | Commands and queries from Fulfilment Operator, Fulfilment Supervisor, Sales Assistant, Inventory Supervisor, and reporting applications. |

## Application Requirements Moved Out

Fulfilment queue screens, pick/pack/ship/label/complete task flows, supervisor exception screens, shipping purchase presentation, label printing UX, search/filter presentation, and accessibility requirements for fulfilment screens are documented under `docs/application/`.
