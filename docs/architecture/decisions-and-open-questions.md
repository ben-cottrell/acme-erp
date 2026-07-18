# Architecture Decisions and MVP Scope

## Status

This document records ACME-specific decisions that resolve generated architecture and requirements questions for the initial ERP release.

## ACME Business Context

- ACME is a medium-sized B2B seller of computer systems.
- ACME has one office and one warehouse.
- ACME manages approximately 1,000 active products, 10 to 20 suppliers, and 100 business customers.
- The ERP is internal and runs on a protected network.
- The initial implementation should avoid multi-tenant, multi-warehouse, public internet, and broad finance-process complexity unless later requested.

## Architecture Decisions

| Decision | Rationale | Consequence |
|---|---|---|
| Authentik provides OAuth/OIDC identity, with password-only login for the initial release. | The ERP is internal and protected by the company network. | MFA remains optional/future and can be enabled later through Authentik policy. |
| All user and external client ingress goes through Gravitee. | Matches the fixed architecture baseline and centralizes API exposure. | Internal Kubernetes service calls are allowed only after ingress for trusted ERP services with service identity, authorization, and operational-history controls. |
| Security and Audit, Security Administration, and Audit Reporting are de-scoped for MVP. | The MVP focuses on business workflows while Authentik and Gravitee provide identity and ingress. | Do not generate a Security and Audit bounded context, Security Administration application, Audit Reporting application, or active compliance workflows. Access permissions are documented in the owning application/domain requirements. |
| The ERP is single-tenant for ACME only. | ACME is one company using one internal ERP. | Tenant partitioning and tenant-level authorization are out of scope for the first release. |
| Each domain bounded context owns its own database and uses external IDs for cross-domain references. | Preserves service boundaries in the fixed architecture. | Integration contracts must define external ID lifecycle and reconciliation behavior. |
| No separate master-data service is required for the MVP. | A dedicated master-data service would add architecture and workflow complexity before the core ERP flows are proven. | Inventory owns product/SKU/barcode/serialization configuration, Sales owns customer reference data, Purchasing owns supplier reference data, and other domains use external IDs or read models. |

## Cross-Cutting Decisions

| Decision | Rationale | Consequence |
|---|---|---|
| Sessions use a 60 minute idle timeout and an 8 hour absolute timeout. | Fits office and warehouse internal use without excessive reauthentication. | Authentik/session integration must enforce both values. |
| Customer accounts are mandatory for website orders. | ACME has approximately 100 B2B customers, making account management practical. | Guest checkout and anonymous order tracking are out of scope. |
| Approval thresholds are configurable with ACME defaults. | Defaults unblock requirements while allowing later policy changes. | Domain APIs must avoid hard-coding thresholds. |
| Local self-approval checks prevent users from approving controlled actions they created or requested. | Simple and appropriate for a medium-sized company. | Users may hold multiple roles when each owning domain allows the resulting permissions. |
| Service identities are owned by Authentik and platform configuration for MVP. | Keeps identity lifecycle in the platform layer. | Integration configuration must support credential replacement without broadening permissions. |

## Approval Defaults

| Area | Initial rule |
|---|---|
| Purchasing | Purchase orders over 10,000 require Purchasing Manager approval. Buyers cannot approve their own purchase orders. |
| Inventory | Adjustments over 2,000 value or 10 percent variance require Inventory Supervisor approval. The recorder cannot approve the related adjustment. |
| Sales | Sales overrides and post-confirmation cancellations over 5,000 require Sales Supervisor approval. Released-order amendments require coordination with Order Fulfilment. |
| Order Fulfilment | Pick exceptions, short picks, substitutions, partial fulfilment release, shipping overrides, cancellation after picking starts, and completion reversals require Fulfilment Supervisor approval. |

## Domain Decisions

| Domain | Decision |
|---|---|
| Sales | Initial channels are internal sales assistants and authenticated customer website orders. Mandatory data includes customer account, order contact, billing address, shipping address, product/SKU where applicable, quantity, and channel. |
| Sales | Inventory is checked during order entry and reserved only when Sales releases the order to Order Fulfilment. |
| Sales | Insufficient stocked inventory may be partially fulfilled and backordered. Non-routinely stocked products are routed to Purchasing through buyer requests. |
| Purchasing | Purchase orders require suppliers. Expected arrival date is captured at header level and may be overridden at line level. Blanket, recurring, and partial-release POs are out of scope initially. |
| Purchasing | Sales buyer requests enter a buyer review queue. Buyers may create a linked PO, reject with reason, or return the request for clarification. |
| Inventory | ACME has one warehouse. Inventory supports warehouse and bin identifiers where bin tracking is configured. Negative inventory balances are not permitted. |
| Inventory | Serial number tracking is required for serialized computer systems and serialized components. Lot and expiry tracking are out of scope initially unless configured later for specific products. |
| Inventory | Damaged goods, quarantine stock, and rejected receipts are non-available stock states pending review or supplier return/disposal action. |
| Order Fulfilment | Inventory is consumed at fulfilment completion after pick, pack, shipping purchase, and label generation are complete or an approved manual exception exists. |
| Order Fulfilment | Partial fulfilment is allowed and reports remaining quantity to Sales as backordered. |
| Order Fulfilment | Courier integration is limited to one provider path for MVP. Royal Mail is the default first provider unless ACME supplies a different existing courier account before implementation starts. FedEx, DHL, and additional provider adapters are future scope. |
| Order Fulfilment | Shipping purchase requires ship-from, ship-to, package weight and dimensions, service level, customer contact, sales order reference, and package count where applicable. MVP label output uses PDF/browser printing; ZPL and printer-model-specific handling are future scope. |

## MVP Scope Decisions

| Scope area | MVP answer | Deferred scope |
|---|---|---|
| Master data ownership | Do not create a separate master-data service. Inventory owns product/SKU/barcode/serialization configuration; Sales owns customer reference data; Purchasing owns supplier reference data; users and identity claims are owned by Authentik, while access permissions are owned by each application/domain workflow. | Dedicated master-data service, onboarding workflows, lifecycle governance, and cross-domain synchronization tooling. |
| Privacy controls | MVP captures minimal B2B customer contact, billing, shipping, and order data and applies baseline access control in the owning workflows. Jurisdiction-specific automation is not included unless ACME confirms a legal requirement. | Automated GDPR/CCPA workflows, self-service privacy portals, deletion automation, and jurisdiction-specific consent management. |
| Role design ownership | Use role-based approval ownership in the MVP: Sales Supervisor, Purchasing Manager, Inventory Supervisor, and Fulfilment Supervisor. Named-person assignment is operational configuration, not a requirements feature. | Named delegation matrices, approval calendars, and department-specific governance workflows. |
| Finance integration | No automated Finance integration or event export in MVP. Finance visibility is provided through operational reports and CSV exports. | AP, AR, invoicing, tax, payment, invoice matching, accounting postings, and automated finance events. |
| Courier provider | Implement one provider path first. Royal Mail is the default unless ACME supplies a different existing courier account before implementation starts. | Multi-provider rating, provider failover, FedEx/DHL adapters, and rate negotiation workflows. |
| Label printer support | MVP uses PDF labels and browser/OS printing. | ZPL, direct thermal-printer integration, model-specific printer configuration, and print server management. |

## Verification Notes

- Requirements should continue to reference configurable thresholds rather than hard-coded values in business logic.
- Domain requirements should remain consistent on inventory timing: reserve at fulfilment release and consume at fulfilment completion.
- Finance, returns/RMA, guest checkout, multi-warehouse, multi-tenant behavior, dedicated master-data services, multi-courier routing, and printer-specific label handling remain out of scope for the MVP unless explicitly promoted into scope.