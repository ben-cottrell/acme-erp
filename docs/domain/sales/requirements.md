# Domain Requirements: Sales

## 1. Purpose

The Sales bounded context owns the durable business record for MVP customer account reference data, sales orders, sales order lines, sales channels, buyer request origination, release-to-fulfilment decisions, sales status history, and sales operational history records.

Sales provides the authoritative sales demand record for internal sales-assisted ordering and authenticated customer ordering. It exposes WebAPI contracts, owns the Sales database, and remains responsible for sales validation, authorization, state transitions, idempotency, and operational history. User-facing order capture, customer self-service, dashboards, and review screens are owned by application services.

## 2. Domain Scope

### In Scope

- Sales order creation, amendment, submission, confirmation, cancellation, release, completion visibility, and exception state.
- MVP customer account reference data needed for B2B order capture and customer-scoped order visibility.
- Sales channel recording for internal sales assistant and authenticated customer ordering sources.
- Buyer request origination for non-routinely stocked products and copied buyer request status visibility.
- Availability and product validation requests to Inventory Management during order validation and fulfilment release.
- Fulfilment release contracts to Order Fulfilment and copied fulfilment status, shipment reference, partial fulfilment, backorder, and exception visibility.
- Sales status history, operational history records, reporting queries, and CSV source data for sales workflows.

### Out of Scope

- Razor Pages UI, screen flow, navigation, presentation validation, or user-facing dashboards.
- Physical picking, packing, shipping purchase, label printing, shipment execution, or courier account management.
- Purchase order authoring, supplier management, buyer workbench presentation, and goods receipt booking.
- Product master ownership, inventory balance updates, stock checks, reservations outside release, and stock adjustments.
- Pricing, promotions, tax, payment capture, invoicing, credit control, returns/RMA, revenue recognition, and finance postings for the MVP.

## 3. Business Context

ACME needs a consistent sales order record across internal sales-assisted ordering and customer-originated website ordering. Sales must coordinate with Inventory Management for availability, Purchasing for non-stocked product requests, and Order Fulfilment for warehouse execution, while keeping sales state and customer-facing status consistent.

The MVP outcome is a traceable sales workflow where orders can be captured, validated, routed for purchasing where needed, released for fulfilment when eligible, updated from fulfilment progress, and searched or reported without applications owning durable sales state.

## 4. Stakeholders and Roles

| Role | Description | Responsibilities | Domain Permissions |
|---|---|---|---|
| Sales Assistant | Internal user who captures and monitors customer orders. | Create, amend before release, submit, review availability, request buyer action, release eligible orders. | Create/update sales orders, query order status, request release where Sales policy allows. |
| Sales Supervisor | Sales control role for exceptions and approvals. | Approve controlled overrides, post-confirmation cancellations, and released-order amendments. | Approve/reject controlled sales actions; view sales change history. |
| Authenticated Customer | B2B customer user submitting and viewing own orders through Customer Ordering. | Submit website-originated orders and view own order status. | Create customer-scoped orders and query own orders only. |
| Buyer | Purchasing user responding to non-stocked product requests. | Review Sales-originated buyer requests through Purchasing. | Read buyer request context exposed by Sales; update decisions only through Purchasing integration. |
| Fulfilment Operator/Supervisor | Warehouse fulfilment users executing released orders. | Execute fulfilment tasks and report exceptions/completion through Order Fulfilment. | Read released order payloads and send fulfilment status via Order Fulfilment contracts. |

## 5. Domain Capabilities and Workflows

- **Order intake** starts when an application API submits a sales order command with customer, channel, line, quantity, and idempotency context. It ends in Draft, Submitted, Confirmed, Pending Inventory, Pending Buyer Request, or validation failure.
- **Availability review** starts when Sales validates stocked order lines against Inventory Management. It ends with availability accepted, Pending Inventory, or a sales exception visible to consuming applications.
- **Buyer request workflow** starts when an order line is non-routinely stocked or cannot be satisfied from stocked inventory. It ends when Purchasing accepts, links to a purchase order, rejects, returns for clarification, or closes the request.
- **Fulfilment release** starts when Sales evaluates a confirmed order for release. It ends when Order Fulfilment accepts the release, rejects the release payload, or Sales records a release exception.
- **Fulfilment status synchronization** starts when Order Fulfilment sends progress, partial fulfilment, completion, backorder, shipment reference, or exception updates. It ends when Sales updates copied visibility and status history.
- **Amendment and cancellation** starts when an authorized actor requests a change. It ends with amendment/cancellation applied, rejected by policy, queued for supervisor approval, or blocked because fulfilment state no longer allows the change.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| SAL-DOM-001 | Order intake | The system shall accept sales order create commands from authorized application APIs only when customer account, contact, billing address, shipping address, channel, order lines, quantities, and idempotency or correlation data are present. | Must | Given a complete authorized command, when Sales validates it, then a sales order is created with status history and operational metadata; given missing required data, then Sales rejects the command with field-level errors and no durable partial order. |
| SAL-DOM-002 | Channel control | The system shall record the originating sales channel for every order and preserve it through status changes, reports, and integration payloads. | Must | Given an order is submitted from Sales Assistant or Customer Ordering, when the order is persisted or released, then the originating channel is queryable and included in operational reporting output. |
| SAL-DOM-003 | Product validation | The system shall validate stocked order lines against active product, SKU, and stocked-product data owned by Inventory Management. | Must | Given an order line references inactive, unknown, or non-stocked product data, when Sales validates the order, then the line is rejected or routed to the buyer request workflow according to Inventory response. |
| SAL-DOM-004 | Availability review | The system shall request availability from Inventory Management during order validation and again before fulfilment release. | Must | Given availability changes after order entry, when release is requested, then Sales rechecks Inventory and either releases, moves to Pending Inventory, or records a release exception. |
| SAL-DOM-005 | Buyer request origination | The system shall create and track buyer requests for non-routinely stocked products without writing Purchasing-owned queue decisions. | Must | Given a sales order contains a non-stocked product request, when the request is submitted, then Sales records originating request context and sends Purchasing a correlated request; when Purchasing updates status, then Sales updates copied visibility. |
| SAL-DOM-006 | Order lifecycle | The system shall maintain an explicit status lifecycle for Draft, Submitted, Confirmed, Pending Inventory, Pending Buyer Request, Released to Fulfilment, Partially Fulfilled, Backordered, Completed, Cancelled, and Exception. | Must | Given any status transition request, when the transition is not allowed by the state model, then Sales rejects it and records no state change; allowed transitions append status history. |
| SAL-DOM-007 | Fulfilment release | The system shall release only eligible confirmed orders to Order Fulfilment with customer delivery context, order lines, quantities, channel, correlation ID, and idempotency key. | Must | Given an order satisfies customer, approval, availability, and buyer request conditions, when release is requested, then Sales sends a release contract and records Released to Fulfilment only after Order Fulfilment accepts or records a release exception if the handoff fails. |
| SAL-DOM-008 | Fulfilment updates | The system shall consume Order Fulfilment updates for progress, completion, partial fulfilment, backorder, shipment references, cancellations, and exceptions. | Must | Given Order Fulfilment sends a correlated update, when Sales accepts it, then copied fulfilment visibility and sales status history are updated without Sales modifying fulfilment-owned state. |
| SAL-DOM-009 | Amendment and cancellation | The system shall support authorized amendments and cancellations according to order status, fulfilment state, approval policy, and business reason. | Must | Given an authorized user requests an amendment before release, when policy permits it, then Sales applies the change and records the reason; given the order is released, then supervisor approval and fulfilment coordination are required before Sales accepts the change. |
| SAL-DOM-010 | Duplicate submission protection | The system shall detect duplicate customer website submissions using customer account, source channel, idempotency key or submission correlation ID, timestamp window, and matching lines. | Must | Given the same customer submission is retried with the same idempotency key, when Sales receives it, then Sales returns the original result rather than creating a duplicate order. |
| SAL-DOM-011 | Sales queries | The system shall expose query contracts for order search, status history, buyer request state, fulfilment visibility, exception queues, and sales history reporting. | Should | Given an authorized query with filters, when Sales processes it, then results are scoped by role and include stale integration indicators where applicable. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| SAL-BR-001 | Customer account, contact, billing address, shipping address, channel, product/SKU where applicable, and quantity are required before confirmation. | Sales order | Sales API command validation | Customer account reference data is Sales-owned for MVP. |
| SAL-BR-002 | Quantity must be positive and numeric for every order line. | Sales order line | Sales API command validation | Unit-of-measure rules come from Inventory where applicable. |
| SAL-BR-003 | Stocked products must be active in Inventory Management before confirmation. | Stocked order line | Sales and Inventory integration | Sales stores external product/SKU IDs, not product master state. |
| SAL-BR-004 | Inventory is reserved only when Sales releases an eligible order to Order Fulfilment. | Fulfilment release | Sales release workflow and Inventory reservation contract | Sales does not mutate inventory balances directly. |
| SAL-BR-005 | Non-routinely stocked products must be routed through the buyer request workflow before release. | Non-stocked lines | Sales and Purchasing integration | Purchasing owns queue decisions and PO linkage. |
| SAL-BR-006 | Orders cannot be released until required customer, channel, product, quantity, availability, approval, and buyer request conditions are satisfied. | Fulfilment release | Sales release policy | Failed handoff creates visible release exception state. |
| SAL-BR-007 | Sales overrides and post-confirmation cancellations over the configured policy threshold require Sales Supervisor approval. | Overrides/cancellations | Sales authorization and approval policy | Existing docs mention 5,000; threshold remains configurable and stakeholder-confirmed. |
| SAL-BR-008 | Confirmed orders may be amended before fulfilment release by authorized users; released-order amendments require Sales Supervisor approval and coordination with Order Fulfilment. | Amendments | Sales state model | Coordination avoids divergence with active fulfilment tasks. |
| SAL-BR-009 | Customer Ordering users may view and submit orders only for their authenticated customer account scope. | Customer-originated orders | Sales authorization | Application routing does not replace domain authorization. |
| SAL-BR-010 | Every controlled action must produce a sales activity history record containing actor, action, prior state, new state, outcome, reason where supplied, timestamp, and correlation ID. | Controlled actions | Sales API and persistence | Applies to create, amend, cancel, approve, release, buyer request, and fulfilment update handling. |

## 8. State Model

| State | Allowed Transitions | Triggering Events | Guards / Notes |
|---|---|---|---|
| Draft | Submitted, Cancelled | Order saved or abandoned by authorized application | Draft orders require customer and at least one line before submission. |
| Submitted | Confirmed, Pending Inventory, Pending Buyer Request, Cancelled, Exception | Validation, availability check, buyer request routing | Confirmation requires required data and valid products. |
| Confirmed | Released to Fulfilment, Pending Inventory, Pending Buyer Request, Cancelled, Exception | Release evaluation or cancellation request | Release requires availability and approval conditions. |
| Pending Inventory | Confirmed, Cancelled, Exception | Inventory availability changes or user review | No release until Inventory indicates sufficient available-to-promise or policy allows backorder path. |
| Pending Buyer Request | Confirmed, Cancelled, Exception | Purchasing status update | Buyer rejection requires reason visible to sales users. |
| Released to Fulfilment | Partially Fulfilled, Backordered, Completed, Cancelled, Exception | Order Fulfilment status update | Sales does not directly execute fulfilment state. |
| Partially Fulfilled | Backordered, Completed, Exception | Fulfilment partial/completion update | Remaining quantities are visible to Sales and Customer Ordering where allowed. |
| Backordered | Released to Fulfilment, Completed, Cancelled, Exception | Inventory or fulfilment update | Backorder release requires renewed availability/release decision. |
| Completed | Exception | Fulfilment completion update or correction | Terminal for normal workflow. |
| Cancelled | Exception | Authorized cancellation | Terminal unless correction process is explicitly approved. |
| Exception | Submitted, Confirmed, Pending Inventory, Pending Buyer Request, Released to Fulfilment, Cancelled | Manual or integration recovery | Recovery path depends on prior state and approval policy. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Sales Order | Sales | Yes | Unique sales order number, customer account, channel, status, timestamps, created-by context. | Customer account reference owned by Sales for MVP. |
| Sales Order Line | Sales | Yes | Positive quantity, product/SKU or buyer-request description, line status. | Product/SKU/barcode external IDs from Inventory Management. |
| Customer Account Reference | Sales | Yes for B2B orders | Active customer, scoped customer users, billing/shipping details. | Authentik user/customer mapping where applicable. |
| Sales Channel | Sales | Yes | Must identify internal, customer ordering, or other approved source. | Application source and correlation ID. |
| Buyer Request Context | Sales | Conditional | Required for non-stocked product request lines. | Purchasing buyer request ID and copied status. |
| Fulfilment Reference | Sales copy | Conditional | Required after release acceptance. | Order Fulfilment task ID, status, shipment/tracking reference. |
| Availability Result | Inventory Management | Conditional | Used for validation and release decisions; stale state must be detectable. | Inventory product/SKU/location availability response. |
| Sales Activity History | Sales | Yes | Actor/service, action, prior/new values, outcome, timestamp, correlation ID. | Sales-owned operational history. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Failure Handling |
|---|---|---|---|---|---|---|
| SAL-INT-001 | Sales | Inventory Management | Outbound request / inbound response | Product/SKU validation, stocked flag, availability, stale timestamp. | Order validation and release evaluation. | Reject line, mark Pending Inventory, or record exception with retryable correlation. |
| SAL-INT-002 | Sales | Purchasing | Outbound command | Buyer request ID, customer/order context, requested product details, quantity, reason, correlation ID, idempotency key. | Non-stocked product request submission. | Keep request in exception or pending retry state; do not create duplicate requests on retry. |
| SAL-INT-003 | Purchasing | Sales | Inbound update | Buyer request status, PO linkage where allowed, rejection/clarification reason, timestamps. | Buyer decision changes. | Ignore duplicates by idempotency key; reject unknown request IDs; record stale/failed status. |
| SAL-INT-004 | Sales | Order Fulfilment | Outbound command | Released order header, lines, quantities, delivery context, channel, correlation ID, idempotency key. | Fulfilment release. | Keep order in release exception state until accepted or cancelled by authorized user. |
| SAL-INT-005 | Order Fulfilment | Sales | Inbound update | Fulfilment status, completed quantities, backorder quantities, shipment/tracking reference, exception state. | Fulfilment task changes. | Reject out-of-order updates that violate state model; preserve failed update history. |
| SAL-INT-006 | Application APIs | Sales | Inbound command/query | Order commands, customer-scoped queries, sales search filters, approval actions. | User actions. | Domain authorization and validation errors returned without partial state changes. |

## 11. Reporting and Query Requirements

| Report / Query | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Sales Order Search | Sales Assistant, Sales Supervisor | Find and manage orders. | Customer, channel, product/SKU, status, date range, buyer request state, fulfilment state. | CSV for operational review. |
| Exception Queue | Sales Assistant, Sales Supervisor | Identify orders blocked by availability, buyer request, release, or fulfilment update issues. | Exception type, age, channel, customer, owner. | CSV optional for supervisor review. |
| Customer Order Status | Authenticated Customer | Show customer-visible state for own orders. | Customer account, order number, date range, status. | No bulk export in MVP unless approved. |
| Sales Change History | Sales Supervisor | Review controlled changes and approvals. | Actor, action, date range, order, channel, outcome. | CSV for operational review. |
| Buyer Request Status | Sales Assistant, Buyer-facing integrations | Track non-stocked requests. | Request state, customer, product, date range, Purchasing status. | CSV for buyer coordination. |

## 12. Security, Authorization, and Approval Controls

Sales shall enforce domain-level authorization for create, amend, cancel, release, approve, query, and export actions. Application route or screen checks are usability controls only and must not replace Sales API decisions.

Sales Supervisor approval is required for controlled overrides, configured high-value cancellations, released-order amendments, and release exceptions where policy requires review. The user who requests a controlled action shall not approve the same action. Customer-scoped users shall access only orders linked to their authenticated customer account. Service-to-service calls shall be authenticated, scoped, correlated, and authorized for the target operation.

## 13. Operational History and Traceability

Sales shall record operational history for order creation, submission, confirmation, amendment, cancellation, release attempts, release failures, buyer request origination, buyer request status updates, fulfilment updates, approval decisions, and authorization denials for controlled actions.

Operational history records shall include actor or service account, source application, action, entity identifiers, prior and new status where applicable, changed fields for amendments, reason/comments where supplied, outcome, timestamp, correlation ID, and idempotency key for retried commands. CSV outputs must clearly identify generated time, filters, and requesting user where relevant to sales operations.

## 14. Non-Functional Requirements

- Sales command APIs shall be idempotent for customer website submission, fulfilment release, and cross-service status updates.
- Query APIs shall support paginated search with stable sorting for operational screens.
- Integration failures shall be observable through structured logs, correlation IDs, health checks, and exception queries.
- Sales shall tolerate temporary downstream unavailability by preserving explicit pending or exception states rather than inferring success.
- Validation and authorization errors shall be deterministic and suitable for application-level field/error presentation.
- The Sales API shall be maintainable as a domain service with no dependency on application UI projects or application-owned persistence.
- Localization beyond invariant business values, currency formatting, and address display needs is deferred for MVP unless ACME confirms a locale requirement.

## 15. Dependencies

- Inventory Management for product/SKU/barcode validation, stocked status, availability, reservations initiated at release, and stale state indicators.
- Purchasing for buyer request queue decisions and non-stocked product outcomes.
- Order Fulfilment for release acceptance, fulfilment task state, shipment references, partial fulfilment, backorder, completion, and exceptions.
- Gravitee and Authentik for ingress, identity, service account authentication, customer scoping, and correlation metadata.
- Application APIs for user-facing order capture, customer ordering, dashboards, and report presentation.

## 16. Assumptions and MVP Defaults

- Sales owns MVP customer account reference data until a dedicated customer master is introduced.
- Customer Ordering is authenticated-only; guest checkout and anonymous tracking are not part of the MVP.
- Order prices, taxes, payment capture, invoicing, credit holds, returns, and finance postings are excluded from the MVP sales workflow.
- The MVP sales override and post-confirmation cancellation approval threshold is 5,000 in the configured company currency.
- Sales Supervisor is the MVP approval role for sales overrides, post-confirmation cancellations, and released-order amendments.
- Customer account scope is resolved from the authenticated user's Authentik group or claim mapped to a Sales customer account reference.
- Sales stores copied fulfilment and buyer request visibility only to support sales workflows and reporting, not to take ownership of fulfilment or purchasing state.
- Cross-service mutations use correlation IDs and idempotency keys supplied by callers or generated by Sales when Sales originates the mutation.
- Sales status and activity history are retained according to Sales-owned operational data policy; no central compliance-retention baseline applies in MVP.
- Customer-visible statuses use the Sales status names, with internal technical failure details hidden by application presentation.

## 17. Acceptance Summary

The Sales requirements are complete for MVP when they define authoritative sales state ownership, order lifecycle rules, buyer request and fulfilment release integrations, Inventory/Purchasing/Fulfilment boundaries, domain authorization, local approval controls, operational history, reporting/query needs, and explicit MVP defaults without assigning UI workflows or durable sales state to application services.