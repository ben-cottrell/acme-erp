# Application Requirements: Warehouse Operator

## 1. Purpose

The Warehouse Operator application shall support warehouse users who record informational physical stock checks and accepted goods received against purchase orders using scanner-friendly workflows.

The MVP outcome is a focused data-entry application that submits authoritative commands to Inventory Management and uses Purchasing for purchase order context without owning durable inventory or purchasing state.

## 2. Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.WarehouseOperator.Ui` |
| API | `Acme.Erp.WarehouseOperator.Api` |
| Primary users | Warehouse Operator |
| Database | None |
| Domain APIs consumed | Inventory Management, Purchasing |

The Warehouse Operator UI shall call only the Warehouse Operator API. The Warehouse Operator API shall own no database, EF Core migrations, durable business state, or domain invariants.

## 3. User-Facing Scope

### In Scope

- Product, SKU, barcode, and location lookup and scanner-assisted capture.
- Starting or opening stock checks, submitting actual counted quantities, and displaying the calculated variance.
- Purchase order search and selection for receipt using Purchasing data.
- Display of expected purchase order lines, supplier, ordered quantities, received quantities, and expected arrival date.
- Submission of accepted received quantities to Inventory Management and display of the resulting receipt reference.
- Stock-check and receipt worklists, pagination, input validation, and recoverable technical error handling.

### Out of Scope

- Durable inventory or purchasing state, direct database access, EF Core migrations, purchase order authoring, or supplier maintenance.
- Picking, packing, shipping, finance posting, and warehouse automation hardware integration.
- Offline business-data storage or background synchronization.

## 4. Business Context

Warehouse users need fast and reliable capture of informational physical checks and accepted inbound goods. Inventory Management remains authoritative for products, locations, stock checks, calculated variance, receipts, and stock movements. Purchasing remains authoritative for purchase orders and receipt eligibility.

## 5. Personas and User Roles

| Role | Description | Key Responsibilities | UX / Access Needs |
|---|---|---|---|
| Warehouse Operator | Authenticated warehouse user performing physical inventory work. | Scan or enter products and locations, submit informational checks, select purchase orders, and record accepted quantities. | Large stable controls, predictable scan flow, minimal navigation, and clear field validation. |

## 6. User Journeys and Workflows

### 6.1 Record an Informational Stock Check

The operator opens an existing stock check or starts one where Inventory Management permits it, scans the location and product, enters the actual quantity, and submits once. The journey ends with a completed check reference, count-time recorded quantity, actual quantity, and calculated variance returned by Inventory Management, or with retained input and correctable validation messages.

### 6.2 Record a Goods Receipt

The operator scans or searches for an eligible purchase order, reviews expected lines and quantities, scans received products, enters accepted quantities, and submits the receipt. The journey ends with an Inventory Management receipt reference and updated received quantities.

### 6.3 Correct Input Before Submission

The operator may edit or remove unsent stock-check and receipt entries. After submission, the UI shall reload the domain result and shall not alter durable state locally.

### 6.4 Recover from a Technical Failure

When a dependency or network call fails, the form shall retain unsent entries in the current browser session. For an uncertain mutation result, the application shall query by idempotency key before enabling another submission.

## 7. Functional Requirements

| ID | Workflow | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| WHO-APP-001 | Identifier capture | The system shall support product, SKU, barcode, and location entry by scanner or keyboard. | Must | Given a focused field and keyboard-wedge scan ending in Enter or Tab, when the value is received, then validation shall run and focus shall move to the configured next field without clearing valid data. |
| WHO-APP-002 | Identifier validation | The system shall validate products and locations through Inventory Management. | Must | Given an unknown or inactive identifier, when validation completes, then the affected field shall show the domain message and submission shall remain blocked. |
| WHO-APP-003 | Stock-check access | The system shall display Open stock checks available to the Warehouse Operator and shall allow a permitted check to be started for one product and location. | Must | Given supported filters, when the worklist loads, then Inventory Management checks shall be displayed with product, location, and current state; given valid product and location data, when a check is started once, then one Open check reference shall be returned. |
| WHO-APP-004 | Stock-check submission | The system shall submit an actual non-negative quantity to Inventory Management for the selected Open check, product, and location. | Must | Given valid current check data, when submitted once, then the UI shall display one completed check reference, count-time recorded quantity, actual quantity, and calculated variance returned by Inventory Management. |
| WHO-APP-005 | Purchase order lookup | The system shall search receipt-eligible purchase orders through Purchasing. | Must | Given a purchase order number, supplier, or expected date filter, when search completes, then eligible matching purchase orders shall be displayed. |
| WHO-APP-006 | Receipt line capture | The system shall allow scanner-assisted capture of products and accepted quantities against an eligible purchase order. | Must | Given a product belongs to the selected purchase order, when scanned, then its expected, received-to-date, and remaining quantities shall be displayed for entry. |
| WHO-APP-007 | Receipt submission | The system shall submit accepted received quantities to Inventory Management using the purchase order external ID. | Must | Given valid receipt lines, when submitted once, then the UI shall display one receipt reference and the accepted quantities returned by Inventory Management. |
| WHO-APP-008 | Worklists | The system shall provide paginated stock-check and expected-receipt worklists. | Must | Given supported filters, when a worklist loads, then results shall use stable sorting and include total or continuation information without local persistence. |

## 8. UI and Usability Requirements

- Primary stock-check and receipt controls shall have stable dimensions and remain usable on shared workstation and handheld-width browser screens.
- Barcode, SKU, purchase order, and location fields shall accept keyboard-wedge scanner input ending in Enter or Tab.
- Scan processing shall not submit the entire form unless the final confirmation control has focus.
- Successfully validated scans shall provide a clear visual acknowledgement and move focus predictably.
- Forms shall preserve unsent entries after validation, authorization, conflict, timeout, or dependency failure responses.
- Validation messages shall appear beside affected fields and action-level messages in a stable summary region.
- Quantity fields shall use numeric input and shall not default blank values to zero.
- Submission shall require an explicit final action and shall block repeated clicks while in progress.

## 9. Data Display and Input Requirements

| Data | Source Domain/API | Used For | Required | Validation / Display Rules |
|---|---|---|---|---|
| Product external ID, SKU, and barcode | Inventory Management | Stock-check and receipt identification | Yes | Display recognized product and active state. |
| Location external ID and code | Inventory Management | Stock-check location | Yes for stock check | Required for each stock check. |
| Stock-check ID and version | Inventory Management | Check submission | Yes | Hidden from editing; refresh after a version conflict. |
| Actual quantity | User input to Inventory Management | Informational stock check | Yes | Non-negative numeric value using product precision. |
| Count-time recorded quantity and variance | Inventory Management | Check result | Yes after completion | Display exactly as returned with the completed check reference. |
| Purchase order external ID | Purchasing | Receipt context | Yes for receipt | Display purchase order number, supplier, and eligible state. |
| Expected and received quantities | Purchasing | Receipt guidance | Yes for receipt | Display by purchase order line and do not treat missing data as zero. |
| Accepted received quantity | User input to Inventory Management | Receipt recording | Yes | Positive value and no greater than the quantity accepted by domain validation. |
| Stock-check or receipt reference | Inventory Management | Submission confirmation | Yes after submit | Display prominently and retain for the current session. |

## 10. Orchestration and Integration Requirements

| ID | Application Action | Domain/API Called | Data Exchanged | Failure Handling | Idempotency / Correlation |
|---|---|---|---|---|---|
| WHO-INT-001 | Validate product or location | Inventory Management | Barcode, SKU, product ID, or location code | Retain scanned value, show validation or temporary failure, and permit retry. | Correlate calls with the active stock-check or receipt session. |
| WHO-INT-002 | Load or start stock check | Inventory Management | Check ID, product, location, operator context | Show authorization, stale-state, or technical errors without local state creation. | Propagate the request correlation ID; use an idempotency key when starting a check mutates state. |
| WHO-INT-003 | Submit stock check | Inventory Management | Check ID, version, product, location, actual quantity | Preserve input; query the result after timeout before enabling resubmission. | Send one idempotency key per submission and an end-to-end correlation ID. |
| WHO-INT-004 | Search purchase orders | Purchasing | Purchase order number, supplier, expected date, eligible state, paging | Show temporary unavailability separately from no results. | Propagate the request correlation ID. |
| WHO-INT-005 | Submit receipt | Inventory Management | Purchase order external ID, line external IDs, products, quantities, operator context | Map validation to lines; query uncertain outcomes before another submit. | Send one idempotency key per receipt and an end-to-end correlation ID. |

The paired API shall use bounded timeouts. Safe reads may be retried automatically. Mutation retries shall reuse the original idempotency key. Cross-service references shall use external IDs.

## 11. Operational View and Search Requirements

| View | Audience | Purpose | Filters |
|---|---|---|---|
| Open Stock Checks | Warehouse Operator | Find informational count work | Check ID, location, SKU, state, date |
| Expected Receipt Worklist | Warehouse Operator | Find purchase orders ready for receipt | Purchase order, supplier, expected date, SKU, receipt state |
| Recent Submissions | Warehouse Operator | Confirm the operator's recent check and receipt submissions | Submission type, reference, date, product, purchase order |

Worklists shall use deterministic sorting and pagination. Recent Submissions shall be assembled from domain queries and shall not be stored by the application. The MVP shall not provide scheduled reports or data exports.

## 12. Security and Permissions

- Authentik shall authenticate users and Gravitee shall enforce ingress policy.
- The UI and paired API shall require the Warehouse Operator role for every route and action.
- The paired API shall forward user identity and correlation context to domain APIs.
- Inventory Management shall remain authoritative for product and location scope, stock-check and receipt commands, validation, variance calculation, and persistence.
- Purchasing shall remain authoritative for purchase order visibility and receipt eligibility.
- Logs shall exclude tokens and complete scanned payloads; identifiers may be logged only where operationally required and permitted.

## 13. Non-Functional Requirements

- **Performance:** Worklists shall be paginated, and scan validation shall provide an in-progress state without moving focus unexpectedly.
- **Reliability:** The application shall remain stateless beyond normal authenticated session and request context and shall not provide offline persistence.
- **Consistency:** Mutations shall use domain versions where supplied and shall resolve uncertain outcomes before resubmission.
- **Observability:** Requests shall carry correlation IDs; metrics shall identify scan validation latency, submission outcomes, dependency, and duration without sensitive payloads.
- **Availability:** A Purchasing outage shall not prevent stock-check work that requires only Inventory Management; affected receipt actions shall show a retryable technical message.
- **Maintainability:** Versioned domain clients and scanner input behavior shall be covered by contract and UI tests.
- **Localization:** MVP dates and numbers shall use the ACME deployment locale; multiple locales are not required.
- **Supportability:** Unexpected technical errors shall display a support reference derived from the correlation ID.

## 14. Errors and Edge Cases

- Repeated scans of the same product shall update the active entry according to explicit user action and shall not silently create duplicate lines.
- Duplicate clicks or network retries shall create no more than one stock check or receipt for one idempotency key.
- A stale stock-check or purchase order state shall require refresh before submission.
- Unknown, inactive, or context-incompatible identifiers shall block submission and retain other valid entries.
- A scanner value containing prefix or suffix characters shall be normalized only according to configured scanner input rules.
- A timed-out mutation shall be queried by idempotency key before the form permits another submit.

## 15. Dependencies

- Inventory Management for products, barcodes, locations, stock-check recording and variance, receipts, stock effects, validation, and persistence.
- Purchasing for purchase order search, expected lines, quantities, supplier context, and receipt eligibility.
- Authentik and Gravitee for identity, claims, ingress, and route policy.
- Keyboard-wedge barcode scanners and versioned API contracts using external IDs.

## 16. Assumptions

- The application is available only to authenticated Warehouse Operator users.
- MVP uses one logical warehouse and simple location codes supplied by Inventory Management.
- Count-time recorded quantities are visible with completed stock-check results.
- Scanner support targets keyboard-wedge devices that emit text followed by Enter or Tab.
- Code 128 is the default label format, while manual SKU and barcode entry remains available.
- The browser session may retain unsent form values but the application API stores no drafts.
- Worklists use a default page size of 50 and newest operational date first.

## 17. Open Questions

None. The remaining device and contract details can use the stated MVP defaults and owning-domain rules.

## 18. Acceptance Summary

The Warehouse Operator MVP is complete when an authenticated operator can use keyboard or scanner input to validate products and locations, complete informational stock checks and view their calculated variance, find eligible purchase orders, record accepted goods receipts, and confirm recent submissions. Mutations must be idempotent, technical failures recoverable, and all durable state and business validation domain-owned.
