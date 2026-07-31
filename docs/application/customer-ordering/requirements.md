# Application Requirements: Customer Ordering

## 1. Purpose

The Customer Ordering application shall allow authenticated B2B customer users to discover orderable products, submit website-originated sales orders, and view their own order status.

The MVP outcome is a privacy-conscious ordering channel that presents Inventory Management availability and creates demand through Sales without owning durable sales or inventory state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.CustomerOrdering.Ui` |
| API | `Acme.Erp.CustomerOrdering.Api` |
| Primary users | Authenticated Customer |
| Database | None |
| Domain APIs consumed | Sales, Inventory Management |

The Customer Ordering UI shall call only the Customer Ordering API. The Customer Ordering API shall own no database, EF Core migrations, durable business state, or domain invariants.

## 3. User-Facing Scope

### In Scope

- Authenticated access through Gravitee and Authentik-backed identity.
- Customer-account scoping for every customer-specific query and command.
- Product discovery and indicative availability for active, customer-visible products.
- Order capture for account, contact, billing address, shipping address, product lines, quantities, and customer reference.
- Website-channel order submission to Sales and confirmation display.
- Customer-safe order list and detail views for the signed-in customer's own orders.
- Responsive desktop and mobile behavior, input validation, pagination, and recoverable technical error handling.

### Out of Scope

- Guest checkout, anonymous tracking, public registration, account recovery, customer-user administration, or customer master maintenance.
- Durable sales or inventory state, direct database access, EF Core migrations, product master maintenance, stock mutation, purchasing work, or fulfilment execution.
- Payment capture, credit checks, tax calculation, invoicing, returns, and finance workflows.

## 4. Business Context

ACME needs customers to enter routine B2B orders without internal rekeying. Customers need current product guidance and understandable status, while Sales remains authoritative for customer scope, order validation, lifecycle, and persistence and Inventory Management remains authoritative for product and availability data.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Authenticated Customer | B2B user associated with one permitted customer account scope. | Find products, submit orders, retain confirmation references, and review own order status. | Responsive forms, concise availability wording, clear validation, and strong privacy boundaries. |

## 6. User Journeys and Workflows

### 6.1 Sign In and Resolve Customer Scope

The journey starts at a protected route. Authentik authenticates the user, the application resolves permitted customer scope, and Sales validates that scope. The journey ends at the product or order view. Invalid identity or inactive scope shall deny access without exposing customer data.

### 6.2 Discover Products

The customer searches active products, opens product information, and views the availability indicator returned by Inventory Management. The indicator is guidance and shall not be presented as a reservation.

### 6.3 Create and Submit an Order

The customer selects products, enters quantities and a customer reference, confirms contact and address details, and submits once. The journey ends with a Sales order number, submitted date, and customer-visible status, or with retained input and correctable validation messages.

### 6.4 View Order Status

The customer searches their own orders and opens an order detail. The application displays only customer-visible Sales status, quantities, dates, and references permitted by Sales.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| CO-APP-001 | Authentication | The system shall require a valid authenticated customer identity for every application route. | Must | Given an unauthenticated request, when a protected route is requested, then the request shall be redirected to authentication or denied with no customer data. |
| CO-APP-002 | Customer scoping | The system shall query and mutate orders only within the authenticated user's permitted customer account scope. | Must | Given an order outside the permitted scope, when it is requested, then no order data shall be returned and no mutation shall occur. |
| CO-APP-003 | Product discovery | The system shall display active, customer-visible products returned by Inventory Management. | Must | Given search criteria, when product search completes, then matching products shall be paginated and displayed without local persistence. |
| CO-APP-004 | Availability | The system shall display the current availability indicator returned by Inventory Management. | Must | Given a selected product, when availability is loaded, then the UI shall show the returned indicator and query time without promising reservation. |
| CO-APP-005 | Order capture | The system shall allow the customer to capture contact, address, reference, line, and quantity data. | Must | Given a validation failure, when the response is displayed, then entered values shall remain available and messages shall identify the affected fields. |
| CO-APP-006 | Order submission | The system shall submit a website-channel order to Sales. | Must | Given valid data and customer scope, when submitted once, then Sales shall create one order and the UI shall display its order number, date, and customer-visible status. |
| CO-APP-007 | Confirmation recovery | The system shall recover the result of an uncertain submission before allowing another submission. | Must | Given the client times out after submit, when the confirmation view retries, then the API shall query by idempotency key and show the existing result if Sales accepted it. |
| CO-APP-008 | Order search | The system shall provide paginated search for orders in the current customer scope. | Must | Given supported filters, when search completes, then only scoped orders shall be returned using stable sorting. |
| CO-APP-009 | Status visibility | The system shall display only the customer-visible status and detail fields returned by Sales. | Must | Given a scoped order, when detail loads, then internal-only fields and users shall not be displayed. |

## 8. UI and Usability Requirements

- The UI shall support desktop and mobile browser widths without horizontal scrolling for primary forms and order lists.
- Forms shall mark required fields and preserve entered values after validation, authorization, conflict, timeout, or dependency failure responses.
- Validation messages shall appear beside affected fields and action-level messages in a stable summary region.
- The submit action shall prevent accidental repeated clicks while a request is in progress.
- Availability wording shall clearly distinguish indicative stock information from an accepted order.
- Long product names, addresses, references, and status text shall wrap without obscuring controls.
- The confirmation view shall prominently display the Sales order number and customer reference.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Authenticated identity and customer scope | Authentik and Sales | Access and data scoping | Yes | Never accept customer scope solely from editable browser input. |
| Product external ID and SKU | Inventory Management | Product selection | Yes | Display only active, customer-visible products. |
| Availability indicator | Inventory Management | Ordering guidance | Conditional | Display indicator and query time; do not promise reservation. |
| Contact, billing address, and shipping address | Sales | Order submission | Yes | Apply Sales format and required-field rules; avoid logging values. |
| Customer reference | Sales | Customer tracking | No | Trim whitespace and enforce Sales length rules. |
| Quantity | Sales | Order demand | Yes | Positive value using precision allowed for the product. |
| Order number, dates, and status | Sales | Confirmation and tracking | Yes after submission | Display only customer-visible values returned by Sales. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| CO-INT-001 | Authenticate and resolve scope | Authentik, Gravitee, and Sales | Token claims and customer external reference | Deny access on invalid identity or inactive scope; do not cache a failed scope resolution. | Propagate the ingress correlation ID. |
| CO-INT-002 | Search products | Inventory Management | Search criteria, active/customer-visible filters, paging | Show a temporary unavailable message and permit retry without stale substitution. | Propagate the request correlation ID. |
| CO-INT-003 | Load availability | Inventory Management | Product external ID and requested quantity | Retain selected lines and mark availability temporarily unavailable. | Correlate calls with the active order-entry request. |
| CO-INT-004 | Submit order | Sales | Customer scope, website channel, contact, addresses, reference, and lines | Map validation to fields; show authorization and conflict outcomes without local persistence. | Send one idempotency key for the submission and reuse it for uncertain-outcome recovery. |
| CO-INT-005 | Search or view orders | Sales | Customer scope, order ID, reference, date, status, and paging | Return no cross-scope data; identify temporary dependency failure separately from no results. | Propagate the request correlation ID. |

The paired API shall use bounded timeouts. Safe reads may be retried automatically. Order submission shall not be automatically repeated with a new idempotency key.

## 11. Operational View and Search Requirements

| View | Audience | Purpose | Filters |
|---|---|---|---|
| Product Search | Authenticated Customer | Find orderable products | Search text, SKU, category where supplied |
| My Orders | Authenticated Customer | Review scoped order history | Order number, customer reference, status, date range |
| Order Detail | Authenticated Customer | Review one submitted order | Order external ID within customer scope |

Order lists shall default to newest order date first, use deterministic secondary sorting, and provide pagination. The MVP shall not provide scheduled reports, data exports, or application-owned reporting storage.

## 12. Security and Permissions

- Authentik shall authenticate customer users and Gravitee shall enforce ingress and token policy.
- Every route shall require the Authenticated Customer role and a resolvable customer account scope.
- The paired API shall derive customer scope from trusted identity and Sales context, not from editable request fields.
- Sales shall remain authoritative for customer-scoped order access, allowed fields, validation, and persistence.
- Inventory Management shall remain authoritative for product visibility and availability data.
- Responses, caches, telemetry, and logs shall not reveal another customer's identifiers or data.
- Tokens, contact details, and addresses shall not be written to application logs.

## 13. Non-Functional Requirements

- **Performance:** Product and order lists shall be paginated; independent availability calls may load progressively without blocking line entry.
- **Reliability:** The application shall remain stateless beyond normal authenticated session and request context.
- **Consistency:** Uncertain submissions shall be resolved through Sales using the original idempotency key.
- **Observability:** Requests shall carry correlation IDs; logs and metrics shall record route, dependency, outcome class, and duration without personal data.
- **Availability:** Dependency outages shall produce retryable technical messages and preserve unsent order input in the browser session.
- **Maintainability:** Versioned Sales and Inventory Management clients shall be covered by contract tests.
- **Localization:** MVP text, dates, numbers, and configured currency shall use the ACME deployment locale; multiple locales are not required.
- **Supportability:** Unexpected technical errors shall display a support reference derived from the correlation ID.

## 14. Errors and Edge Cases

- Duplicate clicks or network retries shall create no more than one Sales order for one idempotency key.
- A customer scope that becomes inactive during entry shall block submission and reveal no additional account data.
- A product that becomes inactive shall be rejected by the owning domains and remain identified on the form for correction.
- Availability may change between display and submission; the Sales result shall be authoritative.
- An expired session shall preserve non-sensitive browser form values where practical and require sign-in before submission.
- A failed status query shall not be displayed as an empty order history.

## 15. Dependencies

- Sales for customer account scope, order creation, order lifecycle, customer-visible fields, validation, and persistence.
- Inventory Management for active product discovery and availability indicators.
- Authentik and Gravitee for identity, claims, ingress, and token policy.
- Versioned API contracts, external IDs, idempotency keys, and correlation IDs.

## 16. Assumptions

- Customer Ordering is authenticated-only for MVP.
- Each user is mapped by trusted identity claims to one permitted Sales customer account scope.
- Availability is indicative until Sales accepts the order; it is not a reservation guarantee.
- Guest checkout, anonymous tracking, registration, account recovery, payment capture, and customer-user administration are outside MVP.
- Product and order search use a default page size of 24 and 25 respectively; order search defaults to the most recent 90 days.
- Customer-visible status wording is supplied or permitted by Sales.

## 17. Open Questions

The production mapping between Authentik claims and Sales customer account references must be confirmed before release because an incorrect mapping could expose another customer's data.

## 18. Acceptance Summary

The Customer Ordering MVP is complete when an authenticated, correctly scoped customer can discover products, view indicative availability, submit one idempotent website order, recover its confirmation, and view only their own order status. Technical failures must preserve recoverable input, and all durable business state and validation must remain domain-owned.
