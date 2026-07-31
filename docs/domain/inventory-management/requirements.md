# Domain Requirements: Inventory Management

## 1. Purpose

The Inventory Management bounded context owns the durable stock system of record for MVP product/SKU/barcode/stocking configuration, recorded stock, availability, reservations, goods receipts, stock checks, stock movements, and discrepancy state.

Inventory Management exposes WebAPI contracts and owns the Inventory database. It is authoritative for inventory validation, stock balance changes, reservation and consumption decisions, discrepancy handling, receipt booking, and inventory authorization. Warehouse, supervisor, sales, and fulfilment screens are owned by application services.

## 2. Domain Scope

### In Scope

- Product, SKU, barcode, stocking, location, and serialized-product configuration needed for the MVP.
- Recorded stock balances, available-to-promise quantities, reservations, non-available stock states, and the immutable stock movement ledger.
- Stock checks, actual count capture, variance calculation, discrepancy review state, and authorized adjustment posting.
- Goods receipt state, purchase order matching, receipt exceptions, and stock booking.
- Availability, reservation, consumption, and reversal contracts for Sales and Order Fulfilment.

### Out of Scope

- Razor Pages UI, scanner workflow presentation, or warehouse task screens.
- Purchase order authoring, supplier ordering, purchasing approval, and supplier master ownership beyond copied references.
- Sales order authoring, customer order intake, pricing, payment, invoicing, and customer communication.
- Picking, packing, shipping purchase, label printing, courier state, and fulfilment task ownership.
- Accounting postings, landed cost calculations, tax handling, returns/RMA, and warehouse automation hardware integration.

## 3. Business Context

ACME needs one trustworthy inventory record that supports sales availability, buyer receiving, warehouse stock control, and fulfilment execution. Inventory must prevent negative stock, link every balance change to its source, and separate operational entry from approval decisions where discrepancies or receipt exceptions occur.

The MVP outcome is a controlled inventory workflow where stock can be received, checked, reserved, consumed, adjusted with authorization, and queried by other domains without application services owning inventory state.

## 4. Stakeholders and Roles

| Role | Description | Responsibilities | Domain Permissions |
|---|---|---|---|
| Warehouse Operator | Warehouse user recording counts and receipts. | Capture physical counts, goods received, product/barcode/location input, and receipt issues. | Create stock check counts and receipt records; view operational inventory data. |
| Inventory Supervisor | Control user for inventory exceptions. | Review discrepancies, approve/reject adjustments, resolve receipt exceptions, monitor inventory accuracy. | Approve adjustments and exception resolution where policy allows. |
| Buyer/Purchasing Manager | Purchasing users who need receipt visibility. | Review receipt status and exception feedback for purchase orders. | Query receipt visibility through Purchasing-facing contracts. |
| Sales Assistant/Customer Ordering | Consumers of product and availability data. | Validate stocked products and availability during sales workflows. | Query product/availability contracts according to role. |
| Fulfilment Operator/Supervisor | Consumers of reservation and consumption contracts. | Pick, complete, and reverse fulfilment stock activity through Order Fulfilment. | Request reservation/consumption through authorized fulfilment contracts. |

## 5. Domain Capabilities and Workflows

- **Product and stocking configuration** starts when authorized inventory data is created or updated. It ends with an active or inactive product/SKU/barcode/location configuration available to consuming domains.
- **Goods receipt** starts when a warehouse operator records received goods against a Purchasing purchase order reference. It ends with stock booked, a receipt exception pending review, or a rejected receipt record.
- **Stock check and discrepancy** starts when actual quantity is captured for a product/SKU/location. It ends with no variance, discrepancy pending supervisor review, adjustment posted, or rejection/investigation.
- **Availability and reservation** starts when Sales or Order Fulfilment requests availability or reservation. It ends with availability returned, reservation recorded, or request rejected.
- **Fulfilment consumption and reversal** starts when Order Fulfilment completes or reverses fulfilment. It ends with immutable stock movement records and updated balances, or rejection without a stock change.

## 6. Functional Requirements

| ID | Capability | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|---|
| INV-DOM-001 | Product configuration | The system shall maintain active/inactive product, SKU, barcode, stocking, location, and serialization configuration required for inventory validation. | Must | Given an active SKU exists, when Sales, Purchasing, or Fulfilment queries it, then Inventory returns current validation data and identifiers; inactive products cannot be used for new controlled transactions unless policy allows exception handling. |
| INV-DOM-002 | Goods receipt | The system shall validate goods receipt entries against Purchasing purchase order data before increasing available inventory. | Must | Given received quantities match an eligible PO line, when the receipt is booked, then Inventory records the receipt and corresponding stock movement; given mismatch, damage, over-receipt, or unknown item, then Inventory creates a receipt exception without increasing available stock. |
| INV-DOM-003 | Stock checks | The system shall maintain stock check records, actual counts, variance calculations, discrepancy state, and adjustment outcomes. | Must | Given actual count equals recorded stock, when the count is posted, then the check closes without adjustment; given variance exists, then Inventory creates discrepancy state pending authorized outcome. |
| INV-DOM-004 | Adjustment approval | The system shall require authorized supervisor approval for controlled inventory adjustments according to configurable value, percentage, and self-approval rules. | Must | Given an adjustment exceeds policy or was created by the same user, when approval is attempted by an unauthorized or conflicted actor, then Inventory rejects the approval and records the denial. |
| INV-DOM-005 | Stock movements | The system shall record every inventory balance change in an immutable stock movement ledger linked to a source document or authorized manual adjustment. | Must | Given stock changes through receipt, adjustment, reservation release, consumption, or reversal, when the transaction completes, then the movement identifies its source, actor/service, quantity, and prior/new state. |
| INV-DOM-006 | Non-negative stock | The system shall prevent recorded stock from becoming negative. | Must | Given a command would reduce recorded quantity below zero, when Inventory validates it, then the command is rejected without applying the balance change. |
| INV-DOM-007 | Availability | The system shall expose availability and stocked-product status for Sales and Order Fulfilment without allowing consumers to mutate balances directly. | Must | Given an authorized availability query, when Inventory responds, then it includes product/SKU identifiers, available quantity or availability state, and any non-available restrictions. |
| INV-DOM-008 | Reservation | The system shall reserve stock at fulfilment release for a valid Sales order and fulfilment task. | Must | Given Sales releases an eligible order and stock is available, when Inventory receives a valid reservation request, then available-to-promise is reduced and a reservation reference is returned. |
| INV-DOM-009 | Consumption | The system shall consume reserved stock at fulfilment completion and support authorized reversal where fulfilment is corrected. | Must | Given Order Fulfilment completes a task with valid reservation references, when Inventory consumes stock, then recorded stock and reservation state update with a corresponding stock movement; invalid references are rejected without changing stock. |
| INV-DOM-010 | Inventory queries | The system shall expose search and query contracts for products, current stock balances, reservations, discrepancies, and receipt exceptions. | Should | Given an authorized query with filters, when Inventory processes it, then results are paginated and scoped by permission. |

## 7. Business Rules and Validation Rules

| ID | Rule | Applies To | Enforcement Point | Notes |
|---|---|---|---|---|
| INV-BR-001 | Stock checks compare actual stock against recorded stock for the same product, SKU, barcode, and location. | Stock checks | Inventory validation | Location is required where location tracking is enabled. |
| INV-BR-002 | Goods receipts must validate products and quantities against purchase orders before stock is available. | Receipts | Inventory/Purchasing integration | Purchasing owns PO state; Inventory owns receipt and stock booking. |
| INV-BR-003 | Unmatched, damaged, quarantined, rejected, over-received, or under-received goods do not increase available inventory until resolved or authorized. | Receipt exceptions | Inventory receipt workflow | Non-available states remain visible. |
| INV-BR-004 | Discrepancies do not update recorded stock until reviewed or resolved according to authority. | Discrepancies | Inventory approval workflow | Auto-close only when no variance exists. |
| INV-BR-005 | Adjustments over configured value or variance thresholds require Inventory Supervisor approval. | Adjustments | Inventory authorization | Existing docs mention 2,000 value or 10 percent variance as placeholders. |
| INV-BR-006 | The user who recorded a count or receipt exception may not approve the related adjustment or exception resolution. | Approval control | Inventory approval workflow | Enforced even if the UI hides the action. |
| INV-BR-007 | Every balance change must reference a source document or authorized manual adjustment. | Stock movements | Inventory persistence | Source may be PO receipt, stock check, fulfilment task, reversal, or manual adjustment. |
| INV-BR-008 | Negative inventory balances are prohibited. | Stock changes | Inventory validation | Backorder belongs to Sales/Fulfilment status, not negative stock. |
| INV-BR-009 | Reservations reduce available-to-promise quantity at fulfilment release. | Reservations | Inventory reservation workflow | Reservation command must carry external sales/fulfilment IDs. |
| INV-BR-010 | Serial number tracking is required for serialized computer systems and serialized components; lot and expiry tracking are deferred unless configured later. | Serialized products | Inventory validation | MVP default from existing requirements. |

## 8. State Model

| Area | States | Allowed Transitions | Guards / Notes |
|---|---|---|---|
| Stock Check | Open, Counted, No Variance, Discrepancy Pending Review, Adjustment Approved, Adjustment Rejected, Closed | Open to Counted; Counted to No Variance or Discrepancy; Discrepancy to Approved/Rejected/Closed. | Adjustment posting requires approval when policy applies. |
| Goods Receipt | Open, Matched, Partially Matched, Exception Pending Review, Booked, Rejected, Closed | Open to Matched/Exception; Matched to Booked; Exception to Booked/Rejected/Closed. | Available stock increases only on Booked quantities. |
| Reservation | Requested, Reserved, Partially Reserved, Rejected, Consumed, Released, Reversed | Requested to Reserved/Rejected; Reserved to Consumed/Released/Reversed. | Reservation quantity cannot exceed available stock. |
| Stock State | Available, Reserved, Quarantine, Damaged, Rejected, Non-Available | Available to Reserved/Non-Available; Non-Available to Available or disposal/rejection state. | Non-available stock excluded from availability. |

## 9. Data Ownership and Data Requirements

| Entity / Field | Ownership | Required | Validation / Constraints | External References |
|---|---|---|---|---|
| Product/SKU/Barcode | Inventory Management | Yes | Unique identifiers, active flag, stocked flag, serialization flag. | Referenced by Sales, Purchasing, Fulfilment. |
| Stock Balance | Inventory Management | Yes | Non-negative recorded quantity by product/SKU/location/state. | No cross-database foreign keys. |
| Reservation | Inventory Management | Conditional | Quantity, expiry/release policy placeholder, and source order/fulfilment IDs. | Sales order and fulfilment task external IDs. |
| Stock Movement | Inventory Management | Yes | Immutable source, quantity, prior/new state, actor/service, and timestamp. | PO, sales order, fulfilment task, adjustment references. |
| Goods Receipt | Inventory Management | Conditional | PO reference, received quantity, condition, exception state. | Purchasing purchase order external ID. |
| Discrepancy/Adjustment | Inventory Management | Conditional | Counted quantity, variance, reason, approval status, approver, self-approval outcome. | Stock check and actor identities. |

## 10. Integration Requirements

| ID | Source | Target | Direction | Data Exchanged | Trigger / Frequency | Validation |
|---|---|---|---|---|---|---|
| INV-INT-001 | Purchasing | Inventory Management | Inbound query/copy | PO header, PO lines, supplier, item, SKU/barcode, quantity, unit cost, expected arrival, and PO status. | Receipt lookup and booking. | Reject unknown, closed, or mismatched purchase orders. |
| INV-INT-002 | Inventory Management | Purchasing | Outbound update | Receipt status, received quantities, business exception state, and receipt dates. | Receipt booking or exception change. | Purchasing validates the purchase order, receipt identity, and status change. |
| INV-INT-003 | Sales | Inventory Management | Inbound query | Product validation, stocked status, and availability. | Order entry and release checks. | Return whether the product is recognized and whether the requested stock is available. |
| INV-INT-004 | Order Fulfilment | Inventory Management | Inbound command/query | Reservation, consumption, reversal, and fulfilment task references. | Release, completion, reversal. | Reject invalid order, task, location, reference, or quantity data without partially changing stock. |
| INV-INT-005 | Application APIs | Inventory Management | Inbound command/query | Stock count, receipt, approval, and search requests. | User actions. | Domain validation/authorization errors returned without partial balance changes. |

## 11. Search and Query Requirements

| Query / View | Audience | Purpose | Filters |
|---|---|---|---|
| Stock Balance Search | Warehouse, Sales, Fulfilment, Supervisors | Review current stock and availability. | SKU, barcode, location, stock state, availability. |
| Discrepancy Queue | Inventory Supervisor | Review count variances and pending adjustments. | Age, variance, value, location, SKU, recorder, status. |
| Receipt Exception Queue | Warehouse, Inventory Supervisor, Buyer | Manage mismatches and damaged/quarantined receipts. | Supplier, PO, SKU, exception type, status, age. |

## 12. Security, Authorization, and Approval Controls

Inventory Management shall enforce authorization for product configuration, stock count recording, receipt booking, exception resolution, adjustment approval, reservation, consumption, reversal, and queries. Application UI checks are not authoritative.

Inventory Supervisor approval is required for controlled adjustments, receipt exception resolution where policy requires review, and reversal/correction actions that affect stock. The actor who records a count, receipt exception, or adjustment request shall not approve the related controlled action. Service-to-service inventory mutations shall be scoped to the source domain and authorized for the requested action.

## 13. Non-Functional Requirements

- Inventory commands that mutate stock shall be transactionally consistent within the Inventory database.
- Availability and stock queries shall be paginated where result sets can grow.
- Structured logs, metrics, health checks, and business review queues shall support operational diagnosis.
- Validation errors shall be deterministic and suitable for scanner-assisted and form-based application workflows.
- Inventory services shall not depend on application UI projects or application-owned persistence.

## 14. Dependencies

- Purchasing for purchase order receipt-matching data and receipt status feedback.
- Sales for availability checks and sales order references used by reservations.
- Order Fulfilment for reservation, consumption, reversal, and fulfilment task references.
- Gravitee and Authentik for authenticated ingress, identity, and service accounts.

## 15. Assumptions and MVP Defaults

- Inventory owns MVP product/SKU/barcode/stocking configuration until a dedicated product master is introduced.
- The MVP inventory adjustment approval thresholds are 2,000 in the configured company currency or 10 percent variance, whichever is reached first.
- Inventory Supervisor is the MVP approval role for inventory adjustments and receipt exception resolution.
- Lot and expiry tracking are deferred for MVP unless ACME configures them for specific products.
- Warehouse automation hardware integration is out of scope; scanner-assisted UI remains an application concern.
- Reservations are initiated at fulfilment release and consumption occurs at fulfilment completion.
- MVP uses a single logical warehouse with simple location codes and stock states of Available, Reserved, Quarantine, Damaged, Rejected, and Non-Available.
- Reservation expiry is not automated in MVP; unreleased or unfulfilled reservations remain until fulfilment completion, cancellation, or supervisor release.

## 16. Acceptance Summary

The Inventory Management requirements are complete for MVP when they define authoritative inventory state ownership, product/stock/receipt/discrepancy/reservation workflows, cross-domain contracts, approval and self-approval rules, query needs, and explicit MVP defaults without assigning UI workflows or durable inventory state to application services.
