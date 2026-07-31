# Application Requirements: Buyer

## 1. Purpose

The Buyer application shall support internal buyers who author and place purchase orders, link Sales-originated buyer requests, close fully received orders, and review receipt progress.

The MVP outcome is a purchasing workbench that coordinates Purchasing, Sales, and Inventory Management without owning durable business state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.Buyer.Ui` |
| API | `Acme.Erp.Buyer.Api` |
| Primary users | Buyer |
| Database | None |
| Domain APIs consumed | Purchasing, Sales, Inventory Management |

The Buyer UI shall call only the Buyer API. The Buyer API shall own no database, EF Core migrations, durable business state, or domain invariants. It shall orchestrate domain calls and return workflow-focused responses.

## 3. User-Facing Scope

### In Scope

- Supplier lookup, purchase order creation, editing while Draft, direct placement into Ordered, closure after full receipt, and status review.
- Product, SKU, and barcode validation using Inventory Management data.
- Capture of quantity, unit cost, purchase date, expected arrival date, buyer notes, and supplier reference.
- Processing of Sales-originated buyer requests by linking an Open request to an eligible Ordered purchase order line.
- Receipt progress and received-quantity visibility supplied through Purchasing contracts.
- Paginated purchase order search, expected-arrival views, buyer-request worklists, validation, and recoverable technical error handling.

### Out of Scope

- Durable purchasing, supplier, sales, or inventory state.
- Direct database access, EF Core migrations, goods receipt booking, stock mutation, supplier onboarding, contract management, invoice matching, tax, landed cost, accounts payable, or payment processing.
- Warehouse receipt entry, sales order capture, fulfilment execution, and finance workflows.

## 4. Business Context

Buyers need a single workbench for supplier ordering and non-routinely stocked item requests. Purchasing remains authoritative for supplier references, purchase orders, buyer-request processing state, and receipt visibility. Inventory Management remains authoritative for product identifiers and receipt recording, while Sales remains authoritative for originating request context.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Buyer | Authenticated internal purchasing user. | Create and edit Draft purchase orders, place orders, link buyer requests, close fully received orders, and monitor receipts. | Efficient line entry, supplier and product lookup, clear validation, and filterable worklists. |

## 6. User Journeys and Workflows

### 6.1 Create, Edit, and Place a Purchase Order

The journey starts when the Buyer selects an active supplier and creates a Draft. While it remains Draft, the user may edit supplier, lines, quantities, costs, dates, notes, and references. The user places a valid Draft directly into Ordered. The journey ends with a purchase order number and Ordered status, or with correctable validation messages and retained input.

### 6.2 Close a Received Purchase Order

The user opens a Received purchase order and submits closure to Purchasing. The journey ends with Closed status. A stale version or any other current state shall leave durable state unchanged and require refresh.

### 6.3 Process a Buyer Request

The user opens an Open Sales-originated request, reviews the permitted Sales context, and links it to one eligible Ordered purchase order line that covers the requested quantity. The journey ends with Linked status and the purchase order reference returned by Purchasing.

### 6.4 Monitor Expected Arrivals and Receipts

The user filters purchase orders by expected arrival date and opens a purchase order to review ordered, received, and remaining quantities. The application shall present the latest receipt information available from Purchasing.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| BYR-APP-001 | Supplier lookup | The system shall allow a Buyer to search active suppliers through Purchasing. | Must | Given supplier criteria, when search completes, then only suppliers returned within the user's Purchasing data scope shall be displayed. |
| BYR-APP-002 | Product validation | The system shall validate product, SKU, and barcode identifiers through Inventory Management. | Must | Given an identifier, when validation completes, then the UI shall show the recognized product and active state without copying product master data. |
| BYR-APP-003 | Purchase order creation | The system shall allow a Buyer to create a purchase order draft through Purchasing. | Must | Given valid supplier, line, quantity, cost, and date data, when submitted once, then Purchasing shall create one draft and return its external ID and version. |
| BYR-APP-004 | Draft editing | The system shall allow the Buyer to edit supplier, line, quantity, cost, date, note, and reference data only while Purchasing reports the purchase order as Draft. | Must | Given a Draft and current version, when valid changes are submitted, then the UI shall display the updated Draft and version; given a non-Draft order or stale version, then Purchasing shall reject the edit without changing ordered terms. |
| BYR-APP-005 | Purchase order placement | The system shall allow the Buyer to place a valid Draft directly into Ordered through Purchasing. | Must | Given a valid Draft and current version, when the Buyer places it once, then the UI shall display the purchase order number and Ordered status returned by Purchasing. |
| BYR-APP-006 | Buyer-request linkage | The system shall allow the Buyer to link an Open buyer request to one eligible Ordered purchase order line through Purchasing. | Must | Given an Open request and an Ordered line with sufficient quantity, when linkage is submitted once, then the UI shall display Linked status and the purchase order reference. |
| BYR-APP-007 | Receipt visibility | The system shall display ordered, received, and remaining quantities returned by Purchasing. | Must | Given receipt data exists, when a purchase order is opened, then each line shall show the latest received and remaining quantities and last receipt date. |
| BYR-APP-008 | Purchase order closure | The system shall allow the Buyer to close a purchase order only when Purchasing reports it as Received. | Must | Given a Received purchase order, when closure is submitted once, then the UI shall display Closed status; given any other current state, then the order shall remain unchanged and the domain reason shall be displayed. |
| BYR-APP-009 | Search and worklists | The system shall provide paginated purchase order and buyer-request worklists. | Must | Given supported filters, when a view loads, then results shall use stable sorting and include total or continuation information without local persistence. |

## 8. UI and Usability Requirements

- Draft purchase order line entry shall support add, edit, and remove operations before placement.
- Entered values shall remain available after validation, authorization, conflict, timeout, or dependency failure responses.
- Validation messages shall appear beside affected fields and action-level messages in a stable summary region.
- Supplier, item, and note values shall wrap without obscuring controls.
- Closure shall require explicit confirmation.
- Search filters shall be retained when moving between list and detail during the same session.
- Dates and currency values shall be displayed consistently with the deployment locale and configured company currency.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Supplier external ID | Purchasing | Purchase order creation | Yes | Display active state and supplier name; submit the external ID. |
| Product, SKU, and barcode | Inventory Management and Purchasing | Line identification | Yes where assigned | Display recognized and active state. |
| Quantity | Purchasing | Ordered amount | Yes | Positive value using the unit precision supported by Purchasing. |
| Unit cost and currency | Purchasing | Purchase order value | Yes | Non-negative amount; use the configured company currency for MVP. |
| Purchase and expected arrival dates | Purchasing | Ordering and inbound planning | Yes | Apply Purchasing date rules and display locale-formatted dates. |
| Supplier reference and buyer notes | Purchasing | Supplier communication context | No | Trim whitespace and enforce domain length limits. |
| Buyer-request context | Purchasing and Sales | Request processing | Conditional | Show request reference, Sales order reference, description, quantity, reason, and created date. |
| Receipt progress | Purchasing | Purchase order monitoring | Conditional | Show ordered, received, remaining, and last receipt date per line. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| BYR-INT-001 | Search suppliers | Purchasing | Search criteria, paging, user scope | Show an unavailable message, permit retry, and do not use stale results. | Propagate the request correlation ID. |
| BYR-INT-002 | Validate product | Inventory Management | SKU, barcode, or product external ID | Retain line input and permit retry when validation is unavailable. | Correlate product validation with the active edit request. |
| BYR-INT-003 | Create or edit Draft purchase order | Purchasing | Supplier, version, lines, costs, dates, notes, and references | Map validation to fields; retain entered data and show authorization or version conflicts without local state change. | Send one idempotency key per user submission and reuse it only for retry. |
| BYR-INT-004 | Place or close purchase order | Purchasing | Purchase order ID, current version, and requested lifecycle action | Refresh after conflict and never infer success from timeout. | Send one idempotency key per action and an end-to-end correlation ID. |
| BYR-INT-005 | Link buyer request | Purchasing | Request ID, current version, purchase order line ID, and covered quantity | Preserve selection, refresh after conflict, and never infer success from timeout. | Send an idempotency key and end-to-end correlation ID. |
| BYR-INT-006 | View receipt progress | Purchasing | Purchase order ID and paging where needed | Mark receipt data temporarily unavailable without replacing it with zero values. | Propagate the request correlation ID. |

The application API shall use bounded timeouts. Automatic retries shall be limited to safe reads; mutation retries shall reuse the original idempotency key. Cross-service references shall use external IDs rather than database keys.

## 11. Operational View and Search Requirements

| View | Audience | Purpose | Filters |
|---|---|---|---|
| Purchase Order Workbench | Buyer | Author Drafts and review placed purchase orders | Purchase order number, supplier, SKU, status, buyer, date range |
| Expected Arrivals | Buyer | Plan inbound purchases | Expected date range, supplier, SKU, receipt state |
| Buyer Request Worklist | Buyer | Process Sales-originated requests | Request reference, state, age, Sales order, description |
| Receipt Progress View | Buyer | Review inbound completion | Purchase order, supplier, SKU, received state, last receipt date |

Results shall default to the most relevant date descending, provide pagination, and use deterministic secondary sorting. The MVP shall not provide scheduled reports, data exports, or application-owned reporting storage.

## 12. Security and Permissions

- Authentik shall authenticate users and Gravitee shall enforce ingress policy.
- The UI and paired API shall require the Buyer role for all routes and actions.
- The paired API shall forward user identity and correlation context to domain APIs.
- Purchasing shall remain authoritative for supplier scope, Draft editing, placement, closure, buyer-request linkage, validation, and persistence.
- Sales shall control the request context visible to the Buyer, and Inventory Management shall control product data visibility.
- Logs shall exclude tokens, supplier notes, free-text request reasons, and commercially sensitive payload values.

## 13. Non-Functional Requirements

- **Performance:** Worklists shall be paginated, and independent read sections may load separately when this does not affect command validity.
- **Reliability:** The application shall be stateless beyond normal authenticated session and request context and shall not persist local drafts.
- **Consistency:** The UI shall use domain versions for mutations and re-read uncertain outcomes after timeouts.
- **Observability:** Requests shall carry correlation IDs; logs and metrics shall record route, dependency, outcome class, and duration without sensitive payloads.
- **Availability:** A dependency outage shall produce a retryable technical error only for workflows requiring that dependency.
- **Maintainability:** Versioned domain clients shall be covered by contract tests.
- **Localization:** MVP dates, numbers, and currency shall use the ACME deployment locale; multiple locales are not required.
- **Supportability:** Unexpected technical errors shall display a support reference derived from the correlation ID.

## 14. Errors and Edge Cases

- Duplicate submission or retry shall not create duplicate purchase orders or repeat buyer-request actions.
- A stale purchase order or request version shall require refresh before another mutation.
- An inactive supplier or product shall block submission and preserve correctable input.
- A receipt update arriving while detail is open shall appear after refresh and shall not overwrite unsent purchase order edits.
- A timed-out mutation shall be queried by external ID or idempotency key before the action is offered again.
- A partially unavailable composed read shall identify the unavailable section without displaying missing values as business zeros.

## 15. Dependencies

- Purchasing for suppliers, purchase orders, buyer-request processing, receipt visibility, allowed actions, and validation.
- Inventory Management for product, SKU, and barcode validation and source receipt data.
- Sales for permitted buyer-request context through versioned integration contracts.
- Authentik and Gravitee for identity, claims, ingress, and route policy.
- External IDs, idempotency keys, and correlation IDs for cross-service interactions.

## 16. Assumptions

- The application is available only to authenticated internal Buyer users.
- Supplier reference data is owned by Purchasing for MVP.
- One configured company currency is used.
- Purchasing exposes current versions, Draft editability, placement eligibility, and Received closure eligibility in its contracts.
- Buyer-request screens show only the Sales order reference, requested description, quantity, requesting role, request date, and reason permitted by Sales.
- Search defaults to the most recent 90 days and a page size of 50.
- Accounts payable, invoice matching, tax, landed cost, supplier onboarding, and payment processing are outside MVP.

## 17. Open Questions

None. The remaining policy and contract details can use the stated MVP defaults and owning-domain rules.

## 18. Acceptance Summary

The Buyer MVP is complete when an authenticated Buyer can create and edit Draft purchase orders, place valid Drafts directly into Ordered, link Open buyer requests to eligible Ordered lines, close Received orders, search purchase orders, and review receipt progress through the paired API. Mutations must be idempotent, technical failures recoverable, permissions enforced, and durable business state owned only by domains.