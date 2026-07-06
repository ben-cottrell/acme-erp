# Requirements Specification: Sales Order Management

## 1. Purpose

The purpose of the Sales Order Management module is to support customer detail capture and sales order creation across internal and customer-facing channels. The module shall allow sales assistants and website customers to create sales orders based on available products and current inventory levels, while routing requests for non-routinely stocked products to buyers.

## 2. Scope

### In Scope

- Customer detail capture for sales order creation.
- Sales order creation by sales assistants across different channels.
- Sales order intake from a customer-facing website.
- Product selection based on available products and current inventory levels.
- Request creation or handoff to buyers for products not routinely stocked.
- Sales order status tracking and fulfillment release dependencies.
- Sales reporting, audit history, role-based access, and cross-module integration controls.

### Out of Scope

- Physical picking, packing, courier shipping purchase, and label printing, which are owned by Order Fulfilment.
- Purchase order creation and buyer workflow, which are owned by Purchasing.
- Actual stock counting, receipt booking, and inventory adjustment, which are owned by Inventory Management.
- Detailed pricing, promotions, discounts, tax, payment capture, invoicing, returns/RMA, credit management, and revenue recognition for the initial release.

## 3. Business Context

Sales assistants gather customer details and create sales orders across different channels. Sales orders can also be placed through a customer-facing website. Sales depend on available product data and current inventory levels. Products not routinely stocked may be ordered by placing a request with buyers. The Sales module must therefore coordinate with Inventory Management for availability, Purchasing for non-stocked product requests, and Order Fulfilment for release and completion of sales orders.

## 4. Stakeholders and User Roles

| Role | Description | Key Responsibilities | Access Level |
|---|---|---|---|
| Sales Assistant | Internal sales user who captures customer details and creates orders. | Create sales orders, select products, review inventory availability, submit buyer requests. | Create and update sales orders within assigned channels. |
| Customer | External user placing orders through the website. | Provide customer details and submit website orders. | Customer-facing access to own order activity where supported. |
| Sales Supervisor | Sales control owner. | Review sales order exceptions, approve controlled changes where required, monitor order activity. | Review and approval access according to configured policy. |
| Buyer | Purchasing user receiving non-stocked product requests. | Review requests from Sales and determine purchasing action. | Read request details and update request status where integrated. |
| Warehouse / Fulfilment Operator | User responsible for fulfilling released sales orders. | Pick, pack, and ship order components through Order Fulfilment. | Read released order details needed for fulfillment. |
| Inventory Supervisor | Inventory control user. | Monitor stock availability and inventory exceptions affecting sales. | Read order demand and inventory availability impacts. |
| Finance / Accounts Receivable User | Finance user dependent on sales order data where invoicing is in scope. | Review sales order information for invoicing or AR processing if applicable. | Read sales order data required for finance processes. |
| System Administrator | Technical administrator for configuration and access. | Maintain sales roles, channels, integration settings, and reference data. | Administrative access, excluding business approval authority unless assigned. |
| Auditor | Assurance user. | Review sales order creation, changes, cancellations, and request history. | Read-only access to audit and control reports. |

## 5. Business Process Overview

The sales process begins when a sales assistant captures customer details or an authenticated customer submits an order through the website. The system identifies the sales channel, validates customer and order data, presents available products and current inventory levels, and supports sales order creation. If a selected product is routinely stocked and available according to inventory policy, the order proceeds toward fulfillment release. If a product is not routinely stocked, the system supports a request to buyers. Sales order status is tracked through creation, confirmation, fulfillment release, partial fulfillment, backorder, completion, cancellation, or exception.

Primary statuses include Draft, Submitted, Confirmed, Pending Inventory, Pending Buyer Request, Released to Fulfilment, Partially Fulfilled, Backordered, Completed, Cancelled, and Exception. Inventory is reserved when an eligible sales order is released to Order Fulfilment.

## 6. Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|
| SAL-001 | The system shall allow authorized sales assistants to capture customer details for sales orders. | Must | Given an authorized sales assistant creates an order, when customer details are entered, then the system shall store the required customer information with the sales order. |
| SAL-002 | The system shall allow customer-facing website orders to be submitted into Sales Order Management. | Must | Given a customer submits an order through the website, when required order data is valid, then the system shall create a sales order with website as the order channel. |
| SAL-003 | The system shall record the sales channel for each sales order. | Must | Given a sales order is created, when the order is saved or submitted, then the system shall store the originating channel. |
| SAL-004 | The system shall allow authorized sales users to create sales order lines from available products. | Must | Given product master data contains active products, when a sales user adds a product to an order, then the system shall store the product and quantity on the order line. |
| SAL-005 | The system shall display current inventory levels or availability indicators for products during sales order creation. | Must | Given a product is selected during order creation, when inventory data is available, then the system shall display current availability or availability status for that product. |
| SAL-006 | The system shall validate sales order quantities against current inventory availability according to configured policy. | Must | Given a sales order line is submitted, when the requested quantity exceeds available inventory according to policy, then the system shall apply the configured insufficient-inventory handling and record the result. |
| SAL-007 | The system shall prevent confirmation of sales orders missing required customer, channel, product, or quantity data. | Must | Given a sales order is missing required fields, when the user attempts to confirm the order, then the system shall block confirmation and identify the missing information. |
| SAL-008 | The system shall support buyer requests for products that are not routinely stocked. | Must | Given a requested product is not routinely stocked, when the sales user submits a buyer request, then the system shall create or transmit a request containing customer/order context and product details required by Purchasing. |
| SAL-009 | The system shall track buyer request status for non-routinely stocked products. | Should | Given a buyer request has been submitted, when Purchasing updates request status, then the system shall show the latest request status to authorized sales users. |
| SAL-010 | The system shall release eligible sales orders to Order Fulfilment. | Must | Given a sales order meets release criteria, when the order is released, then the system shall make order components and required fulfillment details available to Order Fulfilment. |
| SAL-011 | The system shall track sales order status throughout the order lifecycle. | Must | Given a sales order progresses through creation, release, fulfillment, completion, or cancellation, when each event occurs, then the system shall update the order status and retain status history. |
| SAL-012 | The system shall allow authorized users to cancel sales orders according to configured rules. | Should | Given a sales order is cancellable, when an authorized user cancels it, then the system shall update the status to Cancelled and notify dependent modules where applicable. |
| SAL-013 | The system shall receive fulfillment completion updates from Order Fulfilment. | Must | Given Order Fulfilment completes an order, when completion status is transmitted, then the system shall update the sales order status to Completed or the configured equivalent. |
| SAL-014 | The system shall provide search and filtering for sales orders. | Should | Given an authorized user searches orders, when the user filters by customer, channel, product, status, date, or request state, then the system shall return matching orders. |

## 7. Business Rules

| ID | Rule | Applies To | Notes |
|---|---|---|---|
| SAL-BR-001 | Sales orders shall capture customer details before confirmation. | Sales order creation | Required details are customer account, customer contact, billing address, shipping address, product, SKU where applicable, quantity, and channel. |
| SAL-BR-002 | Sales orders shall identify the originating channel. | Multi-channel sales | Source context states orders may be created across different channels and via website. |
| SAL-BR-003 | Sales order lines shall be based on available products unless a non-routinely stocked product request is created. | Product selection | Defined in source context. |
| SAL-BR-004 | Sales order creation shall use current inventory levels to determine availability according to configured policy. | Availability validation | Availability is checked during order entry and rechecked at fulfilment release; stock is reserved at fulfilment release. |
| SAL-BR-005 | Non-routinely stocked products shall be routed to buyers through a request process. | Buyer request | Defined in source context. |
| SAL-BR-006 | Sales orders shall not be released to Order Fulfilment until required order and availability conditions are satisfied. | Fulfillment release | Release requires valid customer data, at least one fulfilment-eligible line, current availability validation, and no unresolved approval hold. |

## 8. Data Requirements

| Entity / Field | Description | Required | Validation / Constraints | Source |
|---|---|---|---|---|
| Sales Order ID | Unique sales order identifier. | Yes | System generated and unique. | System generated |
| Customer | Customer associated with the order. | Yes | Must identify an active ACME business customer account. | Sales assistant/Website/Customer master |
| Customer Contact Details | Contact information for order communication. | Yes | Format validation for email, phone, and address where applicable. | Sales assistant/Website |
| Sales Channel | Originating order channel. | Yes | Controlled values such as internal channel, website, or other configured channels. | Sales system |
| Sales Order Status | Current order lifecycle status. | Yes | Controlled status values. | System generated |
| Product | Product ordered. | Yes | Must be active and available from product master, or handled as non-stocked request. | Product master |
| SKU | Stock keeping unit. | Yes for stocked products | Must map to product master and inventory. | Product master |
| Quantity Ordered | Quantity requested by customer. | Yes | Must be positive numeric value. | Sales assistant/Website |
| Inventory Availability | Current inventory level or availability status. | Yes for stocked products | Provided by Inventory Management according to availability policy. | Inventory Management |
| Buyer Request ID | Reference for non-routinely stocked product request. | Conditional | Required when order includes non-stocked product request. | Sales/Purchasing integration |
| Fulfilment Reference | Link to fulfillment task or shipment process. | Conditional | Required when order is released to Order Fulfilment. | Order Fulfilment |
| Audit Metadata | User/source, timestamp, changes, status history, comments. | Yes | Must be retained according to audit policy. | System generated |

## 9. Workflow and Approval Requirements

### Sales Order Creation Workflow

1. Sales assistant or website customer starts an order.
2. System records the originating channel.
3. User enters or selects customer details.
4. User selects products and quantities.
5. System retrieves current inventory availability for stocked products.
6. System validates required order fields and availability according to configured policy.
7. Eligible order is confirmed and prepared for fulfillment release.
8. Order status changes are recorded until completion, cancellation, or exception.

### Non-Routinely Stocked Product Request Workflow

1. Sales user identifies that requested product is not routinely stocked.
2. Sales user records required product and customer/order context.
3. System creates or transmits a request to buyers.
4. Buyer reviews the request in Purchasing or related process.
5. Request status is made visible to authorized sales users where integration supports status feedback.

Sales discounts, payment capture, invoicing, and credit checks are out of scope for the initial release. Sales overrides and post-confirmation cancellations over 5,000 require Sales Supervisor approval. Confirmed orders may be amended by authorized sales users before fulfilment release; released orders require Sales Supervisor approval and coordination with Order Fulfilment.

## 10. Integration Requirements

| System | Direction | Data Exchanged | Frequency | Failure Handling |
|---|---|---|---|---|
| Customer-Facing Website | Inbound to Sales | Customer details, order header, order lines, channel, submission timestamp. | On website order submission. | The system shall reject invalid submissions with validation errors and log failed intake attempts. |
| Inventory Management | Inbound to Sales | Product availability and current inventory levels. | During product selection, order validation, and release checks. | The system shall prevent confirmation or apply configured exception handling when inventory availability cannot be verified. |
| Purchasing | Outbound from Sales | Non-routinely stocked product requests with product and customer/order context. | On request submission. | The system shall retain failed requests in exception status for retry or manual review. |
| Purchasing | Inbound to Sales | Buyer request status updates. | On buyer status change where supported. | The system shall keep the last known request status and log failed updates. |
| Order Fulfilment | Outbound from Sales | Released sales order details and components required for picking and packing. | On fulfillment release. | The system shall keep the order in release exception status if fulfillment handoff fails. |
| Order Fulfilment | Inbound to Sales | Fulfillment status, completion, shipment references where applicable. | On status changes. | The system shall log failed status updates and allow reconciliation. |
| Product Master | Inbound to Sales | Product list, stocking indicator, SKU, description, barcode, status. | On product lookup or master data update. | The system shall prevent use of inactive or unknown products unless handled through the non-stocked request process. |
| Finance / Accounts Receivable | Outbound from Sales | Sales order data for invoicing or AR where applicable. | On confirmation, fulfillment, or completion depending on finance policy. | The system shall queue or flag finance updates if AR integration is unavailable. |

## 11. Reporting and Analytics Requirements

| Report / Dashboard | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Sales Order Status Dashboard | Sales Assistants, Sales Supervisor | Monitor orders by lifecycle status. | Channel, customer, status, date range, product. | CSV and spreadsheet export. |
| Website Order Intake Report | Sales Supervisor | Review website-originated orders and exceptions. | Date range, status, customer, failure reason. | CSV export. |
| Inventory Availability Exceptions | Sales, Inventory Supervisor | Identify orders affected by insufficient or unavailable stock. | Product, SKU, status, date, channel. | CSV export. |
| Non-Stocked Product Request Aging | Sales, Buyers | Track requests sent to buyers and pending outcomes. | Request status, buyer, product, age, customer. | CSV and dashboard export. |
| Sales Order Change History | Sales Supervisor, Auditor | Review order amendments, cancellations, and status changes. | User, date range, order, field changed. | Audit-ready PDF and CSV export. |

## 12. Security, Roles, and Permissions

- The system shall restrict internal sales order creation and amendment to authorized sales users.
- The system shall restrict website customers to creating and viewing only their own website order information where customer account access exists.
- The system shall restrict cancellation, controlled order amendments, and release override actions to authorized roles.
- The system shall provide buyers access only to non-stocked product request information needed for purchasing action.
- The system shall provide fulfillment users access only to sales order details required to fulfill released orders.
- The system shall separate sales order creation from approval activities where segregation of duties policy requires it.
- The system shall protect customer data according to applicable privacy and security policies.

## 13. Audit and Compliance Requirements

- The system shall record creator, channel, customer data source, timestamps, and status changes for each sales order.
- The system shall record changes to customer details, products, quantities, cancellations, fulfillment release, and buyer request submissions.
- The system shall record website-originated submissions with source and correlation identifiers where available.
- The system shall retain sales order audit history for 7 years for operational review and compliance reporting.
- The system shall protect personally identifiable customer information according to confirmed privacy requirements.

## 14. Non-Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|
| SAL-NFR-001 | The system shall validate required sales order data before confirmation. | Must | Given a user attempts to confirm an order, when required customer, channel, product, or quantity data is missing, then the system shall block confirmation and identify the missing data. |
| SAL-NFR-002 | The system shall retrieve inventory availability within an agreed response threshold during order entry. | Must | Given a product is selected, when inventory service is available, then availability shall be returned within the agreed service level. |
| SAL-NFR-003 | The system shall support website order intake during agreed customer-facing availability windows. | Must | Given the website ordering channel is operational, when a customer submits valid order data, then the Sales module shall accept the submission according to the agreed availability target. |
| SAL-NFR-004 | The system shall preserve sales order and audit data through backup and disaster recovery processes. | Must | Given a recovery event occurs, when sales data is restored, then sales orders and audit history shall remain consistent. |
| SAL-NFR-005 | The system shall provide accessible sales order entry and review functions for internal users. | Should | Given an internal user uses keyboard navigation or assistive technology, when creating or reviewing an order, then required controls shall be operable and identifiable. |

## 15. Exceptions and Edge Cases

- Customer details are incomplete or invalid.
- Website order submission fails validation.
- Website submits duplicate order data.
- Product is inactive, unknown, or not routinely stocked.
- Inventory availability cannot be retrieved.
- Requested quantity exceeds available inventory.
- Inventory changes after order creation but before fulfillment release.
- Buyer request fails to transmit to Purchasing.
- Fulfillment release fails.
- Order is cancelled after release to Order Fulfilment.
- Fulfillment completion update conflicts with Sales order status.
- Customer data privacy restrictions prevent access by a user role.

## 16. Dependencies

- Product master must provide available product list, SKU, barcode, and stocking indicator.
- Inventory Management must provide current availability and inventory levels.
- Purchasing must receive and process non-routinely stocked product requests from Sales.
- Order Fulfilment must receive released sales order details and return fulfillment status.
- Customer-facing website must submit valid customer and order data to Sales.
- Finance / Accounts Receivable integration and automated finance event export are future scope for MVP.
- Customer master or CRM may be required if customer data is centrally managed; ownership remains an architecture decision.

## 17. Assumptions

- Sales assistants are authorized internal users who can create sales orders.
- Website orders require authenticated customer accounts and are part of the Sales module intake flow, but the website UI itself is outside this module specification.
- Initial sales channels are internal sales assistants and authenticated customer website orders.
- Product availability depends on product master and Inventory Management data.
- Non-routinely stocked products require buyer involvement through a request process.
- Insufficient stocked inventory may result in partial fulfilment and backorder. Non-routinely stocked products are routed to Purchasing through buyer requests.
- Pricing, tax, payment, credit checks, invoicing, returns, refunds, exchanges, and revenue recognition are out of scope for the initial release.

## 18. Sales Decisions

- Mandatory customer details are customer account, order contact, billing address, shipping address, and customer reference where supplied.
- Supported initial channels are internal sales assistants and authenticated customer website orders.
- Requested stocked inventory that is insufficient may be partially fulfilled with remaining quantity placed on backorder. Non-routinely stocked products create buyer requests.
- Inventory is reserved at fulfilment release.
- Website duplicate submissions shall be detected using customer account, source channel, idempotency key or submission correlation identifier, order timestamp, and matching order lines.
- Website customers may see Submitted, Confirmed, Pending Inventory, Pending Buyer Request, Released to Fulfilment, Partially Fulfilled, Backordered, Completed, Cancelled, and Exception statuses for their own orders.

## 19. MVP Scope Decisions

- Sales owns MVP customer account reference data. A centralized customer master or CRM integration is future scope.
- Finance integration is fully deferred for MVP. Sales provides operational reports and CSV exports for finance visibility where needed.

## 20. Acceptance Summary

The Sales Order Management requirements shall be considered complete when authorized sales assistants and authenticated website customers can create sales orders with required customer, channel, product, and quantity data; Sales can use product and inventory availability during order creation; non-routinely stocked product requests can be routed to buyers; eligible orders can be released to Order Fulfilment with stock reserved at release; partial fulfilment and backorder statuses are maintained; order statuses and audit history are retained; and customer-master centralization plus Finance integration remain outside MVP scope.