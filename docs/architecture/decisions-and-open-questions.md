# Architecture Decisions and MVP Scope

## Status

This document records the current ACME-specific architecture and business workflow decisions for the initial ERP release.

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
| All user and external client ingress goes through Gravitee. | Matches the fixed architecture baseline and centralizes API exposure. | Internal Kubernetes service calls are allowed only after ingress for trusted ERP services with service identity and authorization controls. |
| The ERP is single-tenant for ACME only. | ACME is one company using one internal ERP. | Tenant partitioning and tenant-level authorization are out of scope for the first release. |
| Each domain bounded context owns its own database and uses external IDs for cross-domain references. | Preserves service boundaries in the fixed architecture. | Integration contracts must define external ID lifecycle and reconciliation behavior. |
| No separate master-data service is required for the MVP. | A dedicated master-data service would add architecture and workflow complexity before the core ERP flows are proven. | Inventory owns product/SKU/barcode/serialization configuration, Sales owns customer reference data, Purchasing owns supplier reference data, and other domains use external IDs or read models. |

## Cross-Cutting Decisions

| Decision | Rationale | Consequence |
|---|---|---|
| Sessions use a 60 minute idle timeout and an 8 hour absolute timeout. | Fits office and warehouse internal use without excessive reauthentication. | Authentik/session integration must enforce both values. |
| Customer accounts are mandatory for website orders. | ACME has approximately 100 B2B customers, making account management practical. | Guest checkout and anonymous order tracking are out of scope. |
| Service identities are owned by Authentik and platform configuration for MVP. | Keeps identity lifecycle in the platform layer. | Integration configuration must support credential replacement without broadening permissions. |

## Domain Decisions

| Domain | Decision |
|---|---|
| Sales | Initial channels are internal sales assistants and authenticated customer website orders. Mandatory data includes customer account, order contact, billing address, shipping address, product/SKU where applicable, quantity, and channel. |
| Sales | Inventory availability is informational during order entry. Inventory is reserved only when Sales releases an eligible order to Order Fulfilment, and the reservation must cover every released line in its required quantity. |
| Sales | Sales order terms may be changed only while the order is Draft and become immutable on submission. Non-routinely stocked products are routed to Purchasing through buyer requests. |
| Purchasing | Purchase orders require suppliers. Expected arrival date is captured at header level and may be overridden at line level. Purchase order terms may be changed only while the order is Draft and become immutable on placement. |
| Purchasing | Sales buyer requests enter the Open queue. A Buyer links an Open request to an Ordered purchase order line with sufficient quantity; Inventory receipt visibility moves the linked request to Satisfied when the requested quantity has been received. |
| Inventory | ACME has one warehouse. Inventory supports warehouse and bin identifiers where bin tracking is configured. Negative inventory balances are not permitted. |
| Inventory | Serial number tracking is required for serialized computer systems and serialized components. Lot and expiry tracking are out of scope initially unless configured later for specific products. |
| Inventory | Quarantine, Damaged, and Non-Available stock do not contribute to available-to-promise. Receipt input rejected by validation creates no receipt or stock change. |
| Inventory | A stock check records the count-time balance, actual quantity, and calculated variance as informational evidence. Completing a stock check does not change a balance or create a stock movement. |
| Order Fulfilment | Every released line must be picked in its exact required quantity. Packing, shipping purchase, and label generation proceed only after exact pick confirmation. |
| Order Fulfilment | Completion consumes every exact reservation quantity in one full-task completion and sends one Completed update to Sales. Dependency failures preserve the last committed valid state and retry the same idempotent operation. |
| Order Fulfilment | Courier integration is limited to one provider path for MVP. Royal Mail is the default first provider unless ACME supplies a different existing courier account before implementation starts. FedEx, DHL, and additional provider adapters are future scope. |
| Order Fulfilment | Shipping purchase requires ship-from, ship-to, package weight and dimensions, service level, customer contact, sales order reference, and package count where applicable. MVP label output uses PDF/browser printing; ZPL and printer-model-specific handling are future scope. |

## MVP Scope Decisions

| Scope area | MVP answer | Deferred scope |
|---|---|---|
| Master data ownership | Do not create a separate master-data service. Inventory owns product/SKU/barcode/serialization configuration; Sales owns customer reference data; Purchasing owns supplier reference data; users and identity claims are owned by Authentik, while access permissions are owned by each application/domain workflow. | Dedicated master-data service, onboarding workflows, lifecycle governance, and cross-domain synchronization tooling. |
| Privacy controls | MVP captures minimal B2B customer contact, billing, shipping, and order data and applies baseline access control in the owning workflows. Jurisdiction-specific automation is not included unless ACME confirms a legal requirement. | Automated GDPR/CCPA workflows, self-service privacy portals, deletion automation, and jurisdiction-specific consent management. |
| Application personas | Customer, Sales Assistant, Buyer, Warehouse Operator, and Fulfilment Operator are the user-facing MVP personas. Authentik owns identity claims; each application and domain maps those claims to required permissions and data scopes. | Additional role-specific applications and permission sets. |
| Finance integration | No automated Finance integration is included in MVP. Operational data is available through domain query contracts. | AP, AR, invoicing, tax, payment, invoice matching, accounting postings, and automated finance events. |
| Courier provider | Implement one provider path first. Royal Mail is the default unless ACME supplies a different existing courier account before implementation starts. | Multi-provider rating, provider failover, FedEx/DHL adapters, and rate negotiation workflows. |
| Label printer support | MVP uses PDF labels and browser/OS printing. | ZPL, direct thermal-printer integration, model-specific printer configuration, and print server management. |

## Verification Notes

- Domain requirements must remain consistent on inventory timing and quantity: reserve every required quantity at fulfilment release and consume those exact quantities at full fulfilment completion.
- Sales and Purchasing contracts must expose mutations to order terms only for Draft records.
- Inventory stock-check completion must remain informational and must not write balances or stock movements.
- Finance, returns/RMA, guest checkout, multi-warehouse, multi-tenant behavior, dedicated master-data services, multi-courier routing, and printer-specific label handling remain out of scope for the MVP unless explicitly promoted into scope.