# Application Requirements: Sales Assistant

## 1. Purpose

The Sales Assistant application shall support internal sales users who capture customer orders, review product availability, submit buyer requests for non-routinely stocked items, release eligible orders, and monitor fulfilment progress.

The MVP outcome is a focused order-to-release workbench that coordinates Sales, Inventory Management, Purchasing, and Order Fulfilment without owning durable business state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.SalesAssistant.Ui` |
| API | `Acme.Erp.SalesAssistant.Api` |
| Primary users | Sales Assistant |
| Database | None |
| Domain APIs consumed | Sales, Inventory Management, Purchasing, Order Fulfilment |

The Sales Assistant UI shall call only the Sales Assistant API. The Sales Assistant API shall own no database, EF Core migrations, durable business state, or domain invariants. It shall orchestrate domain API calls and return workflow-focused responses to the UI.

## 3. User-Facing Scope

### In Scope

- Customer account lookup and capture of order contact, billing address, shipping address, customer reference, and sales channel.
- Product, SKU, barcode, and availability lookup.
- Sales order creation, editing while Draft, submission, and release when Sales reports the order as eligible.
- Buyer request submission for non-routinely stocked items and visibility of the resulting request state.
- Fulfilment task status, shipment reference, tracking reference, and completion visibility.
- Order search, release worklists, pagination, filtering, input validation, and recoverable technical error handling.

### Out of Scope

- Durable sales, inventory, purchasing, or fulfilment state.
- Direct database access, EF Core migrations, product master maintenance, stock mutation, purchase order authoring, picking, packing, shipping purchase, or label printing.
- Pricing calculation, tax, payment capture, invoicing, credit control, returns, and finance posting.

## 4. Business Context

Internal sales users need one workflow for turning customer requests into valid sales orders and released fulfilment work. The application shall combine current domain information while keeping Sales authoritative for order lifecycle and release, Inventory Management authoritative for product and availability data, Purchasing authoritative for buyer-request processing visibility, and Order Fulfilment authoritative for fulfilment progress.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Sales Assistant | Authenticated internal order-capture user. | Create and edit Draft orders, review availability, submit orders and buyer requests, release eligible orders, and monitor status. | Efficient form entry, keyboard operation, clear field validation, search, and concise action results. |

## 6. User Journeys and Workflows

### 6.1 Create, Edit, and Submit an Order

The journey starts when a Sales Assistant selects an active customer account and creates a Draft order. While the order remains Draft, the user may edit contact, address, reference, and line data, review availability, and submit the order. The journey ends with a Sales order reference and current non-Draft Sales status, or with correctable validation messages while entered values remain available.

### 6.2 Submit a Buyer Request

For a non-routinely stocked item, the user records a description, quantity, reason, and order context. Sales creates the request and returns its reference. The user may later view the current buyer-request state supplied through domain contracts.

### 6.3 Release an Order

The user opens an order that Sales reports as releasable and submits the release action. The journey ends when Sales returns `Released` and a fulfilment reference where available. A domain rejection shall display the reason and current order status without implying release succeeded.

### 6.4 Monitor Fulfilment

The user searches for an order and views the current fulfilment task status, shipment reference, tracking reference, and completion information returned by the domains.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| SA-APP-001 | Customer lookup | The system shall allow a Sales Assistant to search active customer accounts through Sales. | Must | Given an authenticated Sales Assistant, when customer criteria are submitted, then the system shall display only accounts returned within the user's Sales data scope. |
| SA-APP-002 | Product lookup | The system shall allow product lookup by description, SKU, or barcode through Inventory Management. | Must | Given valid search criteria, when the lookup completes, then the system shall display active matching products without persisting product data. |
| SA-APP-003 | Availability | The system shall display the current availability quantity and stock state returned by Inventory Management. | Must | Given a product and requested quantity, when availability is checked, then the system shall show the returned quantity, state, and query time and shall not describe the result as a reservation. |
| SA-APP-004 | Order capture | The system shall allow a Sales Assistant to create a Draft order with customer, channel, contact, address, reference, and line data through Sales. | Must | Given all required data is valid, when the user creates the order once, then Sales shall create one Draft and the UI shall display its reference, version, and status. |
| SA-APP-005 | Draft editing | The system shall allow a Sales Assistant to add, edit, or remove order data only while Sales reports the order as Draft. | Must | Given a Draft order and current version, when valid changes are submitted, then the system shall show the updated Draft and version; given a non-Draft order or stale version, then Sales shall reject the edit and the UI shall retain entered changes for review. |
| SA-APP-006 | Order submission | The system shall allow a Sales Assistant to submit a valid Draft order through Sales. | Must | Given a valid Draft and current version, when the user submits once, then the UI shall display the resulting Sales status; given validation errors, then the Draft shall remain editable and the errors shall be displayed against the affected fields. |
| SA-APP-007 | Buyer request | The system shall allow a Sales Assistant to submit a buyer request through Sales for a non-routinely stocked item. | Must | Given description, positive quantity, reason, and order context are valid, when submitted, then the UI shall display the Sales buyer-request reference and current state. |
| SA-APP-008 | Release | The system shall show the release action only when Sales reports the order as releasable. | Must | Given a releasable order, when release is submitted, then the UI shall display the returned released status and fulfilment reference; a rejected command shall not be shown as successful. |
| SA-APP-009 | Fulfilment visibility | The system shall display fulfilment status supplied by Sales and Order Fulfilment. | Must | Given fulfilment data exists, when the order is opened, then the UI shall display current task status, shipment reference, tracking reference, and completion date where supplied. |
| SA-APP-010 | Search | The system shall provide paginated order search and operational worklists without local persistence. | Must | Given one or more supported filters, when search is submitted, then the API shall query domain contracts and return a deterministic page with total or continuation information. |

## 8. UI and Usability Requirements

- Forms shall mark required fields and preserve entered values after validation, authorization, conflict, timeout, or dependency failure responses.
- Validation messages shall be placed beside the affected field; action-level messages shall be shown in a stable summary region.
- Draft order lines shall support add, edit, and remove operations before submission without unexpected page navigation.
- Long customer, product, reference, and address values shall wrap without obscuring controls.
- Disabled actions shall show the current domain-provided reason.
- Search filters shall be retained when moving between a result list and order detail during the same session.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Customer account reference | Sales | Customer selection and data scoping | Yes | Display active state; submit the external customer ID, not copied customer state. |
| Contact and addresses | Sales | Order submission | Yes | Required fields and formats are defined by Sales; preserve entered values on failure. |
| Sales channel | Sales | Order classification | Yes | Default to the internal sales channel and display the selected value. |
| Customer reference | Sales | Customer-provided tracking | No | Trim surrounding whitespace and display exactly as accepted by Sales. |
| Product, SKU, and barcode | Inventory Management | Line identification | Yes | Display active state and the external product ID. |
| Requested quantity | Sales | Order line demand | Yes | Accept positive whole or decimal quantities only as permitted for the SKU by the domains. |
| Availability | Inventory Management | Entry guidance | Conditional | Display quantity, state, and query time; do not persist or guarantee the result. |
| Buyer-request data | Sales and Purchasing visibility | Non-stocked item follow-up | Conditional | Display reference, requested description, quantity, created date, and current state. |
| Fulfilment data | Sales and Order Fulfilment | Order monitoring | Conditional | Display task status, shipment reference, tracking reference, and completion information permitted for the sales role. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| SA-INT-001 | Search customers | Sales | Search criteria, paging, user scope | Show an unavailable message and permit retry; do not substitute stale results. | Propagate the request correlation ID. |
| SA-INT-002 | Search products and availability | Inventory Management | Search criteria, product ID, requested quantity | Keep selected order data and permit retry when Inventory Management is unavailable. | Correlate all calls for the order-entry request. |
| SA-INT-003 | Create, edit, or submit Draft order | Sales | Customer ID, channel, version, addresses, references, lines, and requested Draft action | Map validation to fields; retain entered data and show authorization or version conflicts without local state change. | Send an idempotency key for each user submission and reuse it only when retrying that submission. |
| SA-INT-004 | Submit buyer request | Sales | Order ID, product description, quantity, and reason | Preserve input and show the domain result; retry only with the same idempotency key after an uncertain outcome. | Send an idempotency key and end-to-end correlation ID. |
| SA-INT-005 | Release order | Sales | Order ID and current version | Refresh current state after a conflict; never infer success from a timeout. | Send an idempotency key and correlation ID. |
| SA-INT-006 | View fulfilment | Sales and Order Fulfilment | Sales order ID or fulfilment external ID | Identify temporarily unavailable sections while retaining successfully loaded order data. | Propagate one correlation ID across the composed query. |

The application API shall use bounded timeouts. Automatic retries shall be limited to safe reads; mutation retries shall reuse the original idempotency key. Partial read failures shall be identified by section and shall not be presented as empty business data.

## 11. Operational View and Search Requirements

| View | Audience | Purpose | Filters |
|---|---|---|---|
| Order Search | Sales Assistant | Find and review orders | Order number, customer, customer reference, channel, date range, status, SKU |
| Release Worklist | Sales Assistant | Find orders Sales reports as ready for release | Ready state, customer, channel, order date |
| Buyer Request Worklist | Sales Assistant | Follow non-stocked item requests | Request reference, state, age, customer, product description |
| Fulfilment Status View | Sales Assistant | Review released order progress | Order number, fulfilment state, shipment reference, date range |

Results shall use stable sorting, defaulting to newest relevant date first, and shall provide pagination. The MVP shall not provide scheduled reports, data exports, or application-owned reporting storage.

## 12. Security and Permissions

- Authentik shall authenticate users and Gravitee shall enforce ingress policy before requests reach the application.
- The UI and paired API shall require the Sales Assistant role for every route and action.
- The paired API shall forward user identity and correlation context to each domain API.
- Sales shall remain authoritative for customer data scope, allowed order actions, validation, and persistence.
- Inventory Management, Purchasing, and Order Fulfilment shall remain authoritative for their data and action permissions.
- Authorization denial shall return no restricted data and shall not be converted into a successful or not-found result unless required to prevent identifier disclosure.
- Logs shall exclude address details, contact details, tokens, and free-text buyer-request content.

## 13. Non-Functional Requirements

- **Performance:** Lists shall be paginated and forms shall load independent read sections without waiting for unrelated sections where the workflow permits.
- **Reliability:** The application shall remain stateless beyond normal authenticated session and request context and shall not use local business-data caches.
- **Consistency:** Mutation responses shall be re-read from the owning domain when a timeout leaves the result uncertain.
- **Observability:** Every request shall carry a correlation ID through the paired API and domain calls; logs and metrics shall identify route, dependency, outcome class, and duration without sensitive payloads.
- **Availability:** A dependency outage shall affect only workflows that require that dependency and shall produce a retryable technical error.
- **Maintainability:** Domain contracts shall be consumed through versioned clients and contract tests.
- **Localization:** MVP text, dates, numbers, and the configured company currency shall use the ACME deployment locale; multi-locale content is not required.
- **Supportability:** The UI shall display a support reference derived from the correlation ID for unexpected technical errors.

## 14. Errors and Edge Cases

- Duplicate clicks or retries shall not create duplicate orders, buyer requests, submissions, or release actions.
- A stale order version shall require refresh before mutation resubmission.
- Availability changes between lookup and submission shall be resolved by Sales and Inventory Management validation; the UI shall display the returned result.
- A removed or inactive customer or product shall block submission and retain correctable user input.
- If one composed read fails, successfully retrieved sections may remain visible with a clear unavailable state for the failed section.
- Submission and release responses received after a client timeout shall be confirmed by querying Sales before another command is offered.

## 15. Dependencies

- Sales for customer references, Draft order editing, submission, buyer-request origination, lifecycle, release, validation, and data scope.
- Inventory Management for product, SKU, barcode, and availability data.
- Purchasing for buyer-request processing visibility exposed through agreed integration contracts.
- Order Fulfilment for fulfilment progress and shipment references.
- Authentik and Gravitee for identity, claims, ingress, and route policy.
- Versioned API contracts and external IDs for all cross-service references.

## 16. Assumptions

- The application is available only to authenticated internal Sales Assistant users.
- Sales exposes the current order state, version, release eligibility, and concise denial reasons.
- Buyer requests are a normal purchasing coordination path for non-routinely stocked items.
- Recorded availability is indicative until the owning domains accept the order and release actions.
- Pricing, tax, payment, invoicing, credit, returns, and finance workflows are outside MVP.
- Search defaults to the most recent 30 days and a page size of 50; users may change supported filters.
- The application presents domain status names with concise internal wording.

## 17. Open Questions

None. The remaining policy and contract details can use the stated MVP defaults and owning-domain rules.

## 18. Acceptance Summary

The Sales Assistant MVP is complete when an authenticated Sales Assistant can create and edit Draft orders, submit and search orders, review availability, submit and track buyer requests, release eligible orders, and view fulfilment task, shipment, tracking, and completion status through the paired application API. All mutations must be idempotent, technical failures must be recoverable, permissions must be enforced, and no durable business state may be owned by the application.
