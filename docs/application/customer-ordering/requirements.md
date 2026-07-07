# Application Requirements: Customer Ordering

## 1. Purpose

The Customer Ordering application supports authenticated B2B customer users who submit website-originated sales orders and view status for their own orders.

The MVP outcome is a customer-facing ordering workflow that captures valid sales demand through Sales, presents Inventory-backed availability responsibly, and protects customer data without the application owning sales or inventory state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.CustomerOrdering.Ui` |
| API | `Acme.Erp.CustomerOrdering.Api` |
| Primary users | Authenticated Customer |
| Database | None |
| Domain APIs consumed | Sales, Inventory Management |

The Customer Ordering UI calls only the Customer Ordering API. The Customer Ordering API owns no durable business state, uses no EF Core migrations, and does not connect to SQL Server.

## 3. User-Facing Scope

### In Scope

- Authenticated customer access through Gravitee and Authentik-backed identity.
- Customer-scoped product discovery, stocked-product availability indicators, and validation feedback.
- Customer order capture for account, contact, billing/shipping details, product lines, quantities, and customer reference.
- Website channel order submission to Sales with idempotency/correlation data.
- Customer-visible order status for the authenticated customer's own orders.
- Accessible order entry, confirmation, status search, validation messaging, and privacy-conscious presentation.

### Out of Scope

- Guest checkout, anonymous order tracking, public self-registration, account recovery, payment capture, credit checks, tax calculation, invoicing, returns/RMA, and customer master administration.
- Durable sales or inventory state, direct database access, product master updates, inventory mutation, buyer workbench behavior, fulfilment execution, and internal approval workflows.

## 4. Business Context

ACME wants customers to submit orders without rekeying by internal sales staff while still preserving B2B controls, customer scoping, duplicate submission protection, and domain-owned sales validation. Customers need understandable status without exposure to internal operational details.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Authenticated Customer | B2B customer account user. | Browse active products, submit orders, view own order status. | Simple forms, clear availability/status, privacy protection, accessible responsive UI. |
| Customer Account Administrator | Optional customer-side role if enabled later. | Manage customer users or addresses. | Out of scope for MVP unless ACME confirms. |
| Support User | Internal read-only helper where approved. | Help customers troubleshoot submitted orders. | Not a primary Customer Ordering role; access must be separately authorized. |

## 6. User Journeys and Workflows

- **Sign in and customer scope**: customer authenticates, the application resolves allowed customer account scope through identity/Sales context, and denies access if no active customer scope exists.
- **Create order**: customer searches/selects products, views availability indicator, enters quantities and references, confirms billing/shipping details, and submits the order.
- **Prevent duplicate submission**: customer retries or refreshes after submit; the application reuses idempotency/submission correlation so Sales returns the original result.
- **View order status**: customer searches or opens own orders and sees customer-safe statuses such as Submitted, Confirmed, Pending Inventory, Pending Buyer Request, Released to Fulfilment, Partially Fulfilled, Backordered, Completed, Cancelled, or Exception where Sales exposes them.
- **Handle validation failure**: domain validation or availability change is shown with clear next action while preserving entered data.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| CO-APP-001 | Authentication | The application shall require authenticated customer identity before order submission or customer-specific order visibility. | Must | Given a user is unauthenticated, when they access order submission or status, then access is denied or redirected to authentication. |
| CO-APP-002 | Customer scoping | The application shall show and submit only data for the authenticated customer's authorized customer account scope. | Must | Given a customer requests another customer's order, when Sales evaluates the query, then access is denied and the UI shows no cross-customer data. |
| CO-APP-003 | Product discovery | The application shall display active products and customer-appropriate availability indicators from Inventory Management. | Should | Given Inventory returns active stocked products, when the customer searches, then product and availability status are displayed without local product persistence. |
| CO-APP-004 | Order submission | The application shall submit customer orders to Sales with website channel, customer account, contact, billing/shipping details, lines, quantities, and correlation data. | Must | Given required data is valid, when the customer submits, then Sales creates the order and the UI shows confirmation; validation errors are shown without local order storage. |
| CO-APP-005 | Duplicate protection | The application shall provide idempotency or submission correlation data for duplicate website submission detection. | Must | Given the customer resubmits after timeout with the same submission key, when Sales receives it, then the original result is returned and the UI does not display a duplicate order as new. |
| CO-APP-006 | Status visibility | The application shall display only customer-visible Sales statuses for the authenticated customer's own orders. | Must | Given Sales exposes status updates, when the customer opens order status, then status, dates, and customer-safe exception wording are displayed. |
| CO-APP-007 | Accessibility | The application shall provide accessible order submission and status screens. | Must | Given a keyboard or assistive technology user, when they complete primary workflows, then focus order, labels, errors, and confirmations are perceivable and operable. |

## 8. UI, Accessibility, and Usability Requirements

- Order forms shall clearly indicate required fields and preserve customer input on validation failure.
- Status wording shall be customer-safe and must not expose internal users, internal exception details, or supplier/courier configuration beyond what Sales permits.
- Availability shall be presented as an indicator and timestamp/freshness where returned, not as a guaranteed reservation until Sales confirms release policy.
- The application shall be responsive for desktop and mobile browsers and target WCAG 2.2 AA.
- Error messages shall distinguish authentication, authorization, validation, unavailable downstream service, and duplicate/retry outcomes.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Customer identity/scope | Authentik/Sales | Access and order scoping. | Yes | No order actions without active customer scope. |
| Product/SKU | Inventory Management | Product selection. | Yes for stocked lines | Show active/customer-visible products only. |
| Availability indicator | Inventory Management | Customer order guidance. | Conditional | Mark stale/unavailable state; do not promise reservation. |
| Billing/shipping/contact | Sales | Order submission. | Yes | Show Sales validation errors. |
| Customer reference | Sales | Customer order tracking. | Optional | Preserve and display if supplied. |
| Order status | Sales | Status view. | Yes for submitted orders | Customer-safe statuses only. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| CO-INT-001 | Authenticate customer | Authentik/Gravitee | Token, claims, route metadata. | Deny access if invalid or no customer scope. | Correlation ID per request. |
| CO-INT-002 | Search products | Inventory Management via app API | Search filters, active/customer-visible flag. | Show unavailable message if Inventory cannot respond. | Correlate request. |
| CO-INT-003 | Submit order | Sales | Customer scope, order details, website channel. | Show validation/authorization/downstream errors. | Submission idempotency key required. |
| CO-INT-004 | View status | Sales | Customer scope, order ID/reference/date filters. | Show no data for unauthorized scope; mark stale status where returned. | Correlate request. |

## 11. Reporting, Search, and Dashboard Requirements

| View / Report | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Order Status List | Authenticated Customer | Review own orders. | Date range, customer reference, status, order number. | No bulk export in MVP. |
| Order Detail | Authenticated Customer | Review submitted order and status. | Order ID/reference. | Browser print optional; no compliance export. |
| Product Search | Authenticated Customer | Find orderable products. | Search text, SKU/category if available, active. | None. |

## 12. Security and Permissions

The application shall require authenticated customer identity and customer account scope for all order submission and status workflows. Sales remains authoritative for customer-scoped order access, duplicate detection, validation, persistence, and operational history. Inventory remains authoritative for product and availability data. Application presentation shall not reveal cross-customer data or internal-only exception detail.

## 13. Operational History and Traceability

The application shall provide Sales with submission channel, customer identity/scope, correlation ID, and idempotency key so Sales can record customer order submissions. Customer-visible order history comes from Sales. Any customer personal data displayed must be limited to the authenticated customer's scope.

## 14. Non-Functional Requirements

- Customer submission shall tolerate browser retry/refresh through idempotency.
- The UI shall present clear progress, success, validation, and retry states for order submission.
- The application shall not cache sensitive customer data beyond normal request/session needs.
- Search/status queries shall be paginated where result sets can grow.
- Correlation IDs shall be propagated to Sales and Inventory calls.

## 15. Dependencies

- Sales for customer account reference, order submission, duplicate detection, customer-scoped status, and operational history.
- Inventory Management for active products and availability indicators.
- Authentik and Gravitee for authentication, customer identity claims, ingress, and correlation metadata.
- Sales-owned customer data access rules for customer-scoped privacy and visibility.

## 16. Assumptions and MVP Defaults

- Customer Ordering is authenticated-only for MVP.
- Guest checkout, anonymous order tracking, self-registration, payment capture, and account recovery are excluded.
- Availability shown to customers is indicative until Sales confirms order state; it is not a reservation guarantee.
- Customer account scope is resolved from the Authentik group or claim mapped to a Sales customer account reference.
- Customer-safe status wording uses Sales status names, with internal technical detail hidden by the application.
- Customers cannot cancel or amend submitted orders in MVP; they must contact ACME through existing support channels.

## 17. Acceptance Summary

The Customer Ordering requirements are complete for MVP when they define authenticated order entry, customer scoping, product/availability display, duplicate-safe Sales submission, customer-visible status, privacy/security, and explicit MVP defaults without assigning sales or inventory ownership to the application.
