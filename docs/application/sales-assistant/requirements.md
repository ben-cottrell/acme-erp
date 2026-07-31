# Application Requirements: Sales Assistant

## 1. Purpose

The Sales Assistant application supports internal sales users who capture customer details, create and amend sales orders, review inventory availability, submit non-stocked product requests, release eligible orders, and monitor fulfilment progress and exceptions.

The MVP outcome is a role-focused sales workbench that lets Sales Assistant and Sales Supervisor users complete the order-to-release workflow without the application owning sales, inventory, purchasing, or fulfilment state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.SalesAssistant.Ui` |
| API | `Acme.Erp.SalesAssistant.Api` |
| Primary users | Sales Assistant, Sales Supervisor |
| Database | None |
| Domain APIs consumed | Sales, Inventory Management, Purchasing, Order Fulfilment |

The Sales Assistant UI calls only the Sales Assistant API. The Sales Assistant API owns no durable business state, uses no EF Core migrations, and does not connect to SQL Server. It orchestrates domain API calls and returns workflow-focused responses to the UI.

## 3. User-Facing Scope

### In Scope

- Customer/account lookup, order contact, billing address, shipping address, customer reference, and sales channel capture.
- Product, SKU, barcode, and availability lookup using Inventory Management data surfaced through the application API.
- Sales order create, amend, submit, release, cancel/request-cancel, and controlled approval initiation through Sales.
- Non-routinely stocked product request submission through Sales and status display from Sales/Purchasing visibility.
- Fulfilment release, fulfilment progress, partial fulfilment, backorder, completion, and exception visibility.
- Search, filtering, operational dashboards, exception queues, CSV export, accessibility, and deterministic validation presentation.

### Out of Scope

- Durable sales, inventory, purchasing, or fulfilment state ownership.
- Direct database access, EF Core migrations, product master updates, stock mutation, PO authoring, picking, packing, shipping purchase, and label printing.
- Pricing, tax, payment capture, invoicing, credit control, returns/RMA, and finance workflows for the MVP.

## 4. Business Context

Sales users need one internal workflow for turning customer requests into valid sales orders and released fulfilment work. The application must combine Sales, Inventory, Purchasing, and Order Fulfilment information while making ownership boundaries invisible to users and preserving domain authority.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Sales Assistant | Internal order capture user. | Create/amend orders, review availability, submit buyer requests, release eligible orders, monitor status. | Fast form entry, search, field-level validation, keyboard support, clear exception guidance. |
| Sales Supervisor | Sales control and escalation user. | Approve controlled changes, cancellations, overrides, and review exception queues. | Approval queues, decision context, denial reasons, CSV export. |
| Support User | Limited internal support role where approved. | View order context for support without controlled actions. | Read-only, scoped access with privacy controls. |

## 6. User Journeys and Workflows

- **Create internal order**: user searches customer, enters contact/address/reference/channel, adds product lines, reviews availability, submits to Sales, and receives confirmation or validation errors.
- **Handle unavailable stock**: user sees Inventory availability state, can save/submit pending inventory state, or route non-stocked items through the Sales buyer request path.
- **Submit buyer request**: user enters requested product details and reason; Sales creates the request and Purchasing status is later shown in the order workspace.
- **Release to fulfilment**: user requests release only when Sales reports eligibility; the accepted release or business-rule rejection is shown.
- **Monitor order**: user searches orders and views current status, fulfilment progress, partial fulfilment/backorder state, and customer-impacting exceptions.
- **Supervisor approval**: supervisor opens queue, reviews reason and change context, approves or rejects controlled action through Sales.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| SA-APP-001 | Order capture | The application shall allow authorized Sales Assistant users to create and update sales orders by orchestrating Sales and Inventory Management APIs. | Must | Given required fields are complete, when the user submits, then the API sends a Sales command and displays the Sales result; given Sales rejects validation, then field-level errors are shown without local persistence. |
| SA-APP-002 | Availability | The application shall display Inventory Management availability and product validation results during order entry without storing inventory balances locally. | Must | Given a product is selected, when availability is requested, then the UI shows the returned quantity and stock status. |
| SA-APP-003 | Buyer request | The application shall let sales users submit non-routinely stocked product requests through Sales without directly writing Purchasing data. | Must | Given a line requires buyer action, when the request is submitted, then Sales returns a request reference and the UI shows Pending Buyer Request or validation errors. |
| SA-APP-004 | Release | The application shall expose release actions only when Sales reports release criteria are satisfied. | Must | Given Sales reports an order is not releasable, when the order is viewed, then release is disabled with a domain-provided reason. |
| SA-APP-005 | Fulfilment visibility | The application shall show fulfilment status, shipment reference, partial fulfilment, backorder, and exceptions from Sales and Order Fulfilment read contracts. | Must | Given fulfilment updates exist, when the order is opened, then status and exception details are displayed without the app mutating fulfilment state. |
| SA-APP-006 | Search and dashboards | The application shall support search and filtering by customer, channel, product/SKU, status, date, buyer request state, fulfilment state, and exception type. | Should | Given filters are applied, when results load, then the API queries domain contracts and returns paginated results with no local database. |
| SA-APP-007 | Approval workflow | The application shall provide Sales Supervisor approval/rejection actions for controlled sales changes when Sales reports approval is required. | Must | Given an approval is pending, when a supervisor approves or rejects it, then Sales records the decision; self-approval or unauthorized approval is denied and shown to the user. |

## 8. UI, Accessibility, and Usability Requirements

- Forms shall preserve entered values when domain validation fails and shall map domain validation messages to the relevant field or action banner.
- Order entry, search, queues, and approval screens shall be usable with keyboard and assistive technology and target WCAG 2.2 AA unless ACME adopts a stricter standard.
- Long product, customer, and address values shall wrap without overlapping action controls.
- Releasability, pending buyer request, and business exception states shall be visible in the relevant order summary and detail views.
- The UI shall avoid presenting unavailable actions as successful shortcuts; disabled actions must explain the domain-provided reason.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Customer/account reference | Sales | Order capture and customer scoping. | Yes | Show active status and domain validation errors. |
| Billing/shipping/contact details | Sales | Order submission. | Yes | Preserve user input on validation failure. |
| Product/SKU/barcode | Inventory Management | Line selection and validation. | Yes for stocked lines | Show inactive/unknown/non-stocked state. |
| Availability | Inventory Management | Release and order-entry guidance. | Conditional | Show the returned quantity and stock state. |
| Buyer request status | Sales/Purchasing visibility | Non-stocked workflow. | Conditional | Show reason for rejection/clarification. |
| Fulfilment status | Sales/Order Fulfilment | Customer and internal status visibility. | Conditional | Show partial/backorder/exception status. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Validation / Result |
|---|---|---|---|---|
| SA-INT-001 | Create/update order | Sales | Customer, channel, lines, addresses, and references. | Show validation and authorization errors. |
| SA-INT-002 | Product lookup | Inventory Management via app API | Search text, SKU/barcode, and active filters. | Show recognized and active product results. |
| SA-INT-003 | Availability check | Inventory Management via app API | Product/SKU/quantity and customer context where needed. | Show available quantity or Pending Inventory guidance. |
| SA-INT-004 | Submit buyer request | Sales | Requested product details, quantity, reason, and order context. | Show the accepted request reference or Sales validation errors. |
| SA-INT-005 | Release order | Sales | Sales order ID, release request, and reason where applicable. | Show the accepted release or business-rule rejection. |
| SA-INT-006 | Approval decision | Sales | Approval action and reason/comment. | Show denial including self-approval conflict. |

## 11. Reporting, Search, and Dashboard Requirements

| View / Report | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| Order Search | Sales Assistant, Sales Supervisor | Find orders quickly. | Customer, channel, date, status, SKU, buyer request, fulfilment state. | CSV. |
| Sales Exceptions | Sales Assistant, Sales Supervisor | Work blocked orders. | Exception type, age, channel, owner, customer. | CSV optional. |
| Pending Buyer Requests | Sales Assistant | Track non-stocked requests. | Request status, age, customer, product. | CSV optional. |
| Release Queue | Sales Assistant | Identify releasable orders. | Status, availability, buyer request state, date. | None for MVP. |
| Approval Queue | Sales Supervisor | Approve/reject controlled actions. | Action type, requester, value, age, status. | CSV optional for supervisor review. |

## 12. Security and Permissions

The application shall enforce route-level and screen-level access for Sales Assistant and Sales Supervisor roles. Sales remains authoritative for business authorization, approval authority, customer data access, self-approval rules, validation, and persistence. Unauthorized domain responses shall be shown as denied actions, not hidden success.

## 13. Non-Functional Requirements

- Order entry interactions shall provide clear feedback for domain validation and returned availability state.
- Search results shall be paginated and avoid blocking the UI on large result sets.
- The application shall remain stateless apart from user session/request context and shall not introduce application persistence.
- Error messages shall distinguish validation denial, authorization denial, and business conflict responses.

## 14. Dependencies

- Sales for orders, lifecycle, release, buyer request origination, and approvals.
- Inventory Management for product, SKU, barcode, and availability data.
- Purchasing for buyer request status through Sales/Purchasing contracts.
- Order Fulfilment for fulfilment visibility through Sales/fulfilment read contracts.
- Authentik and Gravitee for identity and route access.

## 15. Assumptions and MVP Defaults

- Sales Assistant is for internal authenticated users only.
- The application performs orchestration and presentation only; all durable state belongs to domain services.
- CSV export is sufficient for MVP operational exports.
- Pricing, tax, payment, invoicing, credit, and returns workflows are excluded.
- The application displays the Sales domain MVP approval threshold of 5,000 in the configured company currency and uses Sales Supervisor as the approval role.
- The Support User role is not enabled for Sales Assistant in MVP; customer fields are visible only to Sales Assistant and Sales Supervisor users with Sales authorization.
- Sales users see domain status names and concise domain-provided reasons; customer-facing wording is handled only by Customer Ordering.

## 16. Acceptance Summary

The Sales Assistant requirements are complete for MVP when they define order capture, availability review, buyer request submission, release, fulfilment visibility, supervisor approval, search/reporting, security, and explicit MVP defaults without assigning durable domain state to the application.
