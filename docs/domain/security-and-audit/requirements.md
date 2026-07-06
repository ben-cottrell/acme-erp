# Domain Requirements: Security and Audit

## Purpose

The Security and Audit domain defines ERP-wide authentication integration, authorization policy, role-based access control, segregation of duties, approval authority, audit event shape, retention policy, service account security, privacy controls, and access review requirements.

Security and Audit may be implemented through shared projects, platform services, Authentik integration, and explicit ERP services as the architecture evolves. Any service introduced for this domain owns its own storage. User-facing administration and reporting screens belong to application services.

## Domain Scope

### In Scope

- Authentik OAuth/OIDC integration requirements and session policy.
- ERP role, permission, data-scope, and authorization policy requirements.
- Segregation-of-duties and approval authority policy model.
- Service account identity, scoping, non-interactive use, and credential rotation policy.
- Audit event envelope, retention categories, controlled action coverage, and export logging.
- Privacy protection for B2B customer contact, billing, shipping, and order data.
- Access review, privileged access, SoD conflict, approval exception, service account activity, customer data export, and security configuration reporting data.

### Out of Scope

- Domain-owned business workflows such as sales order creation, purchase order authoring, goods receipt booking, stock counting, picking, packing, shipping purchase, and label printing.
- Razor Pages UI for security administration, access reviews, or audit reports.
- Detailed network security architecture, encryption algorithm selection, infrastructure design, and database schema design.
- Public internet access controls, customer self-registration, guest checkout, and external-facing account recovery workflows for the MVP.
- Detailed accounting, tax, payment, invoicing, returns/RMA, and supplier onboarding rules unless separately specified.

## Domain Business Rules

| ID | Rule |
|---|---|
| SEC-DOM-001 | Access to ERP functions shall require authenticated identity unless the function is explicitly approved for anonymous access. |
| SEC-DOM-002 | Authorization shall be evaluated before each controlled action. |
| SEC-DOM-003 | Roles shall be assigned according to least privilege. |
| SEC-DOM-004 | Administrative technical access shall not imply business approval authority. |
| SEC-DOM-005 | Business approval authority shall be explicit, auditable, and configurable. |
| SEC-DOM-006 | Segregation-of-duties rules shall be configurable by domain, action, and role conflict. |
| SEC-DOM-007 | Users shall not approve controlled transactions, exceptions, cancellations, access changes, or temporary access requests that they created or requested. |
| SEC-DOM-008 | Audit records shall identify who or what performed an action, what changed, when it changed, source context, outcome, and correlation identifier where available. |
| SEC-DOM-009 | Service accounts shall not be used for interactive human login. |
| SEC-DOM-010 | Customer personal data shall be accessed only by authorized roles with a legitimate business purpose. |
| SEC-DOM-011 | Security configuration changes shall be auditable and reviewable. |

## Global Roles

Initial global roles are Customer, Sales Assistant, Sales Supervisor, Buyer, Purchasing Manager, Warehouse Operator, Inventory Supervisor, Fulfilment Operator, Fulfilment Supervisor, Finance/AP User, Finance/AR User, Security Administrator, System Administrator, Auditor, Support User, and Integration Service Account.

Role-facing application requirements are documented under `docs/application/`. Domain APIs remain responsible for final authorization decisions even when application services enforce route-level or screen-level authorization for user experience.

## Audit and Retention

| Category | Retention |
|---|---|
| Sales, purchasing, approval, and financially relevant business events | 7 years |
| Inventory and fulfilment operational events | 3 years |
| Authentication, authorization, and integration events | 1 year unless linked to an incident |
| Security incident evidence | 7 years |

## Integration Contracts

| Target or source | Direction | Contract responsibility |
|---|---|---|
| Authentik | Inbound to ERP services | User identity, account status, authentication result, group or role attributes, and OAuth/OIDC tokens. |
| Gravitee | Inbound to ERP services | Authenticated ingress, coarse-grained route policy, token forwarding, correlation IDs, and request metadata. |
| Domain APIs | Bidirectional | Authorization decisions, role/permission context, audit events, correlation IDs, and service identity validation. |
| Application APIs | Inbound to security/audit services | Security administration commands, access review queries, audit export queries, and reporting queries. |
| Courier, website, finance, and service integrations | Bidirectional | Service account authentication, scoped authorization, credential rotation metadata, audit evidence, and failure records. |

## Application Requirements Moved Out

Security administration screens, access provisioning UX, access removal UX, access review dashboards, privileged access reports, SoD conflict reports, approval exception reports, service account activity reports, customer data export reports, security configuration change reports, and related accessibility requirements are documented under `docs/application/`.