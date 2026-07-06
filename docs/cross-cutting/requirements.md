# Requirements Specification: Cross-Cutting Security, Authorization, and Role-Based Access Control

## 1. Purpose

The purpose of this specification is to define ERP-wide requirements for authentication, authorization, role-based access control, segregation of duties, approval authority, audit trail standards, privacy controls, service account security, master data security, and security reporting. These requirements apply across Inventory Management, Purchasing, Sales Order Management, and Order Fulfilment.

This document complements the module-specific requirements specifications. It defines shared controls and governance requirements that each ERP module shall inherit and apply within its own workflows.

## 2. Scope

### In Scope

- Authentication for internal users, external customers where applicable, administrators, and integration identities.
- Session management, account lockout, access recovery, and identity assurance requirements.
- Authorization and role-based access control across ERP modules.
- Global role definitions and cross-module permission categories.
- Segregation of duties across purchasing, inventory, sales, fulfillment, administration, and audit activities.
- Approval authority framework for controlled business actions.
- Minimum audit trail and compliance logging standards.
- Customer data privacy and sensitive data protection requirements.
- Service account and integration security for inter-module, website, courier, and finance integrations.
- Master data security for products, SKUs, barcodes, users, roles, permissions, suppliers, customers, and configuration records.
- Security monitoring, access review, privileged access reporting, and audit reporting.

### Out of Scope

- Module-owned functional workflows such as purchase order creation, goods receipt booking, sales order creation, inventory counting, picking, packing, courier shipping purchase, and label printing.
- Detailed network security architecture, encryption algorithm selection, infrastructure design, and database schema design.
- Public internet access controls, customer self-registration, guest checkout, and external-facing account recovery workflows for the initial release.
- Detailed accounting, tax, payment, invoicing, returns/RMA, and supplier onboarding rules unless separately specified.

## 3. Business Context

The ERP system spans multiple business modules that share users, data, approvals, integrations, and audit responsibilities. Module specifications already define local security needs, including role-based access, read-only access for dependent modules, segregation of duties, audit trails, and administrative access constraints. A shared cross-cutting specification is required so authentication, authorization, audit, privacy, and access governance are consistent across modules and not redefined differently by each workflow.

ACME is a medium-sized B2B seller of computer systems with a single office, single warehouse, approximately 1,000 products, 10 to 20 suppliers, and approximately 100 business customers. The ERP is an internal system on a protected network. Authentik shall provide OAuth/OIDC identity integration and password-only authentication for the initial release.

## 4. Stakeholders and Global Roles

| Role | Description | Key Responsibilities | Access Level |
|---|---|---|---|
| Customer | External user placing or viewing website-originated orders where customer access exists. | Submit order details, view own order status where supported, maintain own account credentials where applicable. | Restricted access to own customer-facing records only. |
| Sales Assistant | Internal user responsible for customer detail capture and sales order creation. | Create and update sales orders, view inventory availability, submit non-stocked product requests. | Sales create/update access; read-only access to required inventory availability. |
| Sales Supervisor | Sales control owner. | Review sales exceptions, controlled amendments, cancellations, and approval actions where policy requires. | Sales supervisory and approval access according to configured authority. |
| Buyer | Purchasing user responsible for purchase orders and buyer requests. | Create and update purchase orders, review non-stocked product requests, coordinate with Inventory. | Purchasing create/update access; read-only access to relevant receipt/request status. |
| Purchasing Manager | Purchasing control owner. | Review purchasing activity, approve POs or amendments where required, monitor exceptions. | Purchasing supervisory and approval access according to configured authority. |
| Warehouse Operator | Operational user for inventory and fulfillment tasks. | Count stock, record received goods, pick, pack, purchase shipping where authorized, print labels, complete assigned warehouse tasks. | Operational warehouse access within assigned locations and processes. |
| Inventory Supervisor | Inventory control owner. | Review stock discrepancies, approve adjustments where authorized, monitor stock accuracy. | Inventory supervisory and approval access according to configured authority. |
| Fulfilment Operator | Warehouse user responsible for fulfillment execution. | View released orders, pick components, pack orders, purchase shipping where authorized, print labels, complete fulfillment tasks. | Fulfillment task access within assigned scope. |
| Fulfilment Supervisor | Fulfillment control owner. | Monitor queues, resolve fulfillment exceptions, approve overrides or reversals where required. | Fulfillment supervisory and approval access according to configured authority. |
| Finance / Accounts Payable User | Finance user consuming PO and receipt data. | Review PO cost data, goods receipt status, and supplier invoice matching data where applicable. | Read-only access to purchasing and receipt data unless finance workflow ownership is later defined. |
| Finance / Accounts Receivable User | Finance user consuming sales order data. | Review sales order, completion, invoicing, or AR data where applicable. | Read-only access to sales and fulfillment data unless finance workflow ownership is later defined. |
| Security Administrator | User responsible for identity, role, and access governance. | Manage users, roles, permissions, access reviews, SoD configuration, and emergency access controls. | Security administration access without implicit business approval authority. |
| System Administrator | Technical administrator for configuration and operations. | Maintain technical configuration, integration settings, and system availability. | Administrative technical access without implicit business approval authority. |
| Auditor | Internal or external assurance user. | Review audit trails, access logs, approvals, exceptions, and control reports. | Read-only access to audit, security, and operational evidence. |
| Support User | Controlled support role used for troubleshooting. | Investigate support issues under approved access controls. | Time-bound, ticket-linked access according to support policy. |
| Integration Service Account | Non-human identity used by systems and integrations. | Exchange data between modules, website, courier services, finance systems, and master data sources. | Scoped integration access limited to required interfaces. |

## 5. Business Process Overview

Cross-cutting security controls operate throughout the ERP lifecycle.

1. A user, customer, administrator, or integration identity authenticates through an approved identity mechanism.
2. The system establishes the identity, active session, assigned roles, module scope, and permission set.
3. The system evaluates authorization for each attempted action using role, permission, data scope, workflow status, and segregation-of-duties rules.
4. For controlled actions, the system applies approval authority rules, delegation rules, and exception handling.
5. The system records audit events for authentication, authorization, access changes, business approvals, sensitive data access, exports, administrative actions, and integration activity.
6. Security administrators, auditors, and business control owners review access, approvals, exceptions, and SoD conflicts through reports and dashboards.

## 6. Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|
| SEC-AUTH-001 | The system shall authenticate each internal user before allowing access to ERP modules. | Must | Given an internal user attempts to access an ERP module, when the user has not authenticated, then the system shall require successful authentication before granting access. |
| SEC-AUTH-002 | The system shall authenticate external customers before allowing access to customer-specific order information where customer accounts are supported. | Must | Given a customer attempts to view customer-specific order information, when customer account access is enabled, then the system shall require successful customer authentication before displaying the information. |
| SEC-AUTH-003 | The system shall support a configurable authentication mechanism for internal users. | Must | Given the organization selects an identity mechanism, when authentication is configured, then the system shall use the configured mechanism for internal user login. |
| SEC-AUTH-004 | The system shall support multi-factor authentication policy enforcement where required by organization policy. | Should | Given MFA is enabled for a role or user group, when a user authenticates, then the system shall require the configured additional factor before granting access. |
| SEC-AUTH-005 | The system shall terminate user sessions after a configured idle timeout. | Must | Given a user session is idle beyond the configured threshold, when the user attempts another action, then the system shall require re-authentication or session renewal according to policy. |
| SEC-AUTH-006 | The system shall lock or challenge accounts after configured failed authentication attempts. | Must | Given failed login attempts exceed the configured threshold, when another login is attempted, then the system shall block or challenge access according to account protection policy. |
| SEC-RBAC-001 | The system shall authorize user actions based on assigned roles, permissions, module access, and data scope. | Must | Given an authenticated user attempts an action, when the user lacks the required permission or data scope, then the system shall deny the action and record the authorization result where audit policy requires it. |
| SEC-RBAC-002 | The system shall support least-privilege role assignment for all internal users. | Must | Given a user is assigned ERP access, when roles are granted, then the system shall allow only the permissions required for the assigned business responsibilities. |
| SEC-RBAC-003 | The system shall support separate permissions for read, create, update, approve, cancel, export, configure, and administer actions. | Must | Given a role is configured, when permissions are assigned, then the system shall allow permission categories to be granted independently. |
| SEC-RBAC-004 | The system shall support data-scope restrictions by module, business role, and operational context. | Should | Given a user has access to a module, when data scope is configured by location, channel, buyer scope, or operational assignment, then the system shall restrict records according to that scope. |
| SEC-RBAC-005 | The system shall prevent system administrators from receiving business approval authority solely through technical administration access. | Must | Given a system administrator has technical access, when a business approval action is attempted, then the system shall require an explicit business approval role before allowing the action. |
| SEC-RBAC-006 | The system shall support time-bound and purpose-bound temporary access. | Should | Given temporary access is approved, when the access period expires, then the system shall automatically remove or disable the temporary permissions. |
| SEC-RBAC-007 | The system shall support deprovisioning of user access when employment, assignment, or account status changes. | Must | Given a user's access should be removed, when deprovisioning is processed, then the system shall prevent further ERP access by that user. |
| SEC-SOD-001 | The system shall support segregation-of-duties rules that prevent the same user from performing conflicting entry and approval actions where configured. | Must | Given a user performed a controlled entry action, when the same user attempts to approve that same transaction and SoD is configured, then the system shall deny the approval and record the conflict. |
| SEC-SOD-002 | The system shall prevent a buyer from approving the buyer's own purchase order where purchasing SoD policy is configured. | Should | Given a buyer created a PO, when that buyer attempts to approve the PO, then the system shall deny the approval if purchasing SoD policy prohibits self-approval. |
| SEC-SOD-003 | The system shall prevent a stock counter from approving the same stock discrepancy adjustment where inventory SoD policy is configured. | Should | Given a warehouse operator recorded a stock count discrepancy, when the same user attempts to approve the adjustment, then the system shall deny approval if inventory SoD policy prohibits self-approval. |
| SEC-SOD-004 | The system shall prevent a fulfillment operator from approving the operator's own exception override where fulfillment SoD policy is configured. | Should | Given a fulfillment operator records an exception, when the same operator attempts to approve the override, then the system shall deny approval if fulfillment SoD policy prohibits self-approval. |
| SEC-APP-001 | The system shall support configurable approval rules for controlled business actions. | Must | Given an action requires approval according to configured policy, when the action is submitted, then the system shall route it to an authorized approver before completion. |
| SEC-APP-002 | The system shall record approval decisions, approver identity, timestamp, comments, and outcome. | Must | Given an approver approves or rejects a controlled action, when the decision is submitted, then the system shall store the decision details in audit history. |
| SEC-APP-003 | The system shall support approval delegation where organization policy permits delegation. | Could | Given an approver delegates authority within policy, when an approval is routed during the delegation period, then the system shall allow the delegate to act and record the delegation context. |
| SEC-APP-004 | The system shall support escalation of pending approvals according to configured time or priority rules. | Could | Given an approval remains pending beyond a configured threshold, when escalation rules apply, then the system shall route or notify according to escalation policy. |
| SEC-AUD-001 | The system shall record a minimum audit event for security-relevant and controlled business actions. | Must | Given a security-relevant or controlled action occurs, when the action is processed, then the system shall record user or service identity, timestamp, source, action, outcome, reference record, and correlation identifier where available. |
| SEC-AUD-002 | The system shall record previous value, new value, and reason for controlled changes where values are changed. | Must | Given a controlled business or security value is changed, when the change is saved, then the system shall store the previous value, new value, reason where required, user identity, and timestamp. |
| SEC-AUD-003 | The system shall protect audit records from unauthorized modification or deletion. | Must | Given an audit record has been created, when a non-authorized user attempts to alter or delete it, then the system shall deny the action. |
| SEC-AUD-004 | The system shall support audit export for authorized auditors. | Must | Given an auditor has appropriate access, when the auditor requests an audit export, then the system shall provide audit records in an approved export format and record the export event. |
| SEC-PRV-001 | The system shall restrict access to customer personal data based on role, purpose, and data scope. | Must | Given a user requests customer personal data, when the user lacks required role or purpose-based access, then the system shall deny or mask the data according to privacy policy. |
| SEC-PRV-002 | The system shall record exports of customer personal data. | Must | Given an authorized user exports customer personal data, when the export is completed, then the system shall record exporter identity, timestamp, export scope, and purpose where required. |
| SEC-INT-001 | The system shall authenticate integration service accounts before allowing inter-system data exchange. | Must | Given an integration calls an ERP interface, when the integration identity is missing or invalid, then the system shall reject the request and log the failed attempt. |
| SEC-INT-002 | The system shall restrict each service account to the minimum interfaces and actions required for its integration purpose. | Must | Given a service account is configured, when permissions are assigned, then the account shall receive only the scoped permissions required for its integration. |
| SEC-INT-003 | The system shall support credential rotation for service accounts. | Must | Given service account credentials are due for rotation according to policy, when rotation is performed, then the system shall allow credentials to be replaced without granting broader permissions. |
| SEC-MDM-001 | The system shall restrict creation and amendment of master data and security configuration to authorized roles. | Must | Given a user attempts to create or amend product, SKU, barcode, user, role, permission, supplier, customer, or configuration records, when the user lacks authorization, then the system shall deny the action. |
| SEC-REP-001 | The system shall provide access review reports for authorized security administrators and auditors. | Must | Given an authorized reviewer requests an access review report, when the report is generated, then the system shall show active users, roles, permissions, privileged access, temporary access, and last review status. |
| SEC-REP-002 | The system shall provide segregation-of-duties violation or conflict reports. | Should | Given SoD rules are configured, when a reviewer requests a SoD report, then the system shall identify users or transactions that violate or conflict with configured SoD rules. |

## 7. Business Rules

| ID | Rule | Applies To | Notes |
|---|---|---|---|
| SEC-BR-001 | Access to ERP functions shall require authenticated identity unless the function is explicitly approved for anonymous access. | Authentication | Guest website ordering is out of scope for the initial release. |
| SEC-BR-002 | Authorization shall be evaluated before each controlled action. | Authorization | Applies to internal users, customers, administrators, support users, and service accounts. |
| SEC-BR-003 | Roles shall be assigned according to least privilege. | RBAC | Role design must be confirmed with business owners. |
| SEC-BR-004 | Administrative technical access shall not imply business approval authority. | Administration | Repeated across module specifications. |
| SEC-BR-005 | Business approval authority shall be explicit, auditable, and configurable. | Approvals | Initial ACME thresholds are defined in Cross-Cutting Security Decisions. |
| SEC-BR-006 | Segregation-of-duties rules shall be configurable by module, action, and role conflict. | SoD | Initial ACME conflicts prohibit self-approval of controlled actions. |
| SEC-BR-007 | Audit records shall include enough information to identify who or what performed an action, what changed, when it changed, source context, and outcome. | Audit | Minimum fields are defined in Data Requirements. |
| SEC-BR-008 | Service accounts shall not be used for interactive human login. | Integrations | Supports traceability and credential control. |
| SEC-BR-009 | Customer personal data shall be accessed only by authorized roles with a legitimate business purpose. | Privacy | Initial scope covers B2B contact, billing, shipping, and order data; specific statutory mapping remains subject to legal review. |
| SEC-BR-010 | Security configuration changes shall be auditable and reviewable. | Security administration | Includes users, roles, permissions, SoD rules, and access policies. |

## 8. Data Requirements

| Entity / Field | Description | Required | Validation / Constraints | Source |
|---|---|---|---|---|
| User Identity | Human user account for internal users, administrators, support users, and auditors. | Yes | Must be unique and linked to account status. | Identity provider or user directory |
| Customer Identity | External customer account identity where customer accounts exist. | Conditional | Must be unique within customer account scope. | Website/customer identity source |
| Service Account Identity | Non-human account used by integrations. | Yes for integrations | Must be scoped, identifiable, and non-interactive. | Security administration |
| Role | Named set of business or technical permissions. | Yes | Must be approved and auditable. | Security administration |
| Permission | Atomic or grouped action permission. | Yes | Must map to module, action type, and data scope where applicable. | Security administration |
| Data Scope | Restriction by module, location, channel, customer, supplier, assignment, or other business scope. | Conditional | Must be enforceable where configured. | Security administration/business owners |
| Authentication Event | Login, logout, failed login, session timeout, MFA challenge, lockout. | Yes | Must include identity, timestamp, source, event type, and outcome. | System generated |
| Authorization Event | Permission check result for controlled or denied actions. | Conditional | Must include identity, action, resource, outcome, timestamp, and reason where available. | System generated |
| Approval Event | Approval, rejection, delegation, escalation, override. | Yes for controlled approvals | Must include approver, timestamp, outcome, comments, and reference record. | System generated/business user |
| Audit Event | Record of security-relevant or controlled business activity. | Yes | Must include minimum audit fields defined by SEC-AUD requirements. | System generated |
| SoD Rule | Configured conflicting roles or actions. | Conditional | Must identify conflict type and enforcement behavior. | Security administration/business owners |
| Access Review Record | Evidence of periodic review and outcome. | Yes where reviews are required | Must record reviewer, date, scope, findings, and remediation outcome. | Security administrator/auditor |
| Privacy Classification | Classification for personal or sensitive data. | Conditional | Must identify restrictions and handling requirements. | Data governance/privacy owner |
| Credential Rotation Record | Evidence of service credential rotation. | Yes for service accounts | Must include account, rotation date, operator, and status. | Security administration |

## 9. Workflow and Approval Requirements

### Access Provisioning Workflow

1. Authorized requester submits or initiates an access request.
2. System captures user identity, requested roles, data scope, business justification, and requester identity.
3. System evaluates role conflicts and segregation-of-duties rules.
4. Authorized approver approves or rejects the request where approval is required.
5. System provisions approved access and records the access grant in audit history.
6. Access is included in future access review reports.

### Access Removal Workflow

1. User account status, employment status, assignment, or role need changes.
2. Authorized administrator or integration initiates access removal.
3. System disables or removes affected roles and permissions.
4. System records access removal details in audit history.
5. System prevents future use of removed access.

### Controlled Approval Workflow

1. User submits a controlled action requiring approval.
2. System identifies approval requirement based on role, action, module, status, value, or configured threshold.
3. System checks segregation-of-duties constraints.
4. System routes the approval to an authorized approver.
5. Approver approves, rejects, delegates, or escalates according to configured policy.
6. System records approval history and applies the outcome to the transaction.

### Emergency Access Workflow

Emergency access requirements are not fully defined. The system should support a controlled break-glass process only if approved by stakeholders, with time-bound access, business justification, notification, and mandatory audit review.

## 10. Integration Requirements

| System | Direction | Data Exchanged | Frequency | Failure Handling |
|---|---|---|---|---|
| Identity Provider / User Directory | Inbound to ERP | User identity, account status, authentication result, group or role attributes where supported. | On login and scheduled or event-driven synchronization. | The system shall deny access if identity status cannot be verified according to policy and shall log the failure. |
| Customer-Facing Website | Bidirectional | Customer authentication context, order identity context, customer account status, session or token metadata where applicable. | On customer login, order submission, and order lookup. | The system shall reject unauthenticated or unauthorized customer-specific access and log failed access attempts. |
| ERP Modules | Bidirectional | User identity, roles, permissions, approval context, audit events, correlation IDs. | On each controlled action and status change. | The system shall deny or hold controlled actions if authorization cannot be verified. |
| Courier Service | Bidirectional | Service account authentication, shipment request authorization, shipping purchase response, label reference, tracking reference. | During fulfillment shipping purchase and label generation. | The system shall reject requests with invalid courier credentials and place fulfillment activity into exception where required. |
| Finance Systems | Bidirectional | Authorized identity context, PO data, receipt data, sales order data, finance status where applicable. | On configured finance events. | The system shall queue, reject, or flag finance integration events according to integration policy and preserve audit context. |
| Audit / Reporting Store | Outbound from ERP | Authentication events, authorization events, approval events, data export events, business control events. | Near real time or batch according to architecture. | The system shall alert or flag security operations if audit event transmission fails. |

## 11. Reporting and Analytics Requirements

| Report / Dashboard | Audience | Purpose | Filters | Export Needs |
|---|---|---|---|---|
| User Access Review Report | Security Administrator, Auditor, Business Owners | Review active user access by role, module, and data scope. | User, role, module, department, status, last login, reviewer. | CSV and audit-ready PDF export. |
| Privileged Access Report | Security Administrator, Auditor | Identify administrative, approval, support, and high-risk access. | Role, user, permission, module, temporary access, date assigned. | CSV and PDF export. |
| Failed Authentication Report | Security Administrator | Monitor failed logins, lockouts, and suspicious authentication patterns. | User, source, date range, outcome, channel. | CSV export. |
| Segregation-of-Duties Conflict Report | Security Administrator, Auditor, Business Control Owners | Identify conflicting roles or self-approval attempts. | User, conflict type, module, transaction, date, status. | CSV and PDF export. |
| Approval Exception Report | Business Owners, Auditor | Review overrides, delegated approvals, escalations, and rejected approvals. | Module, approver, action, status, date range, exception type. | CSV and PDF export. |
| Service Account Activity Report | Security Administrator, System Administrator, Auditor | Review integration account usage and failed service authentication. | Service account, integration, endpoint, outcome, date range. | CSV export. |
| Customer Data Export Report | Privacy Owner, Auditor | Review exports of customer personal data. | User, role, export type, date range, purpose, channel. | CSV and PDF export. |
| Security Configuration Change Report | Security Administrator, Auditor | Review changes to users, roles, permissions, SoD rules, and security settings. | Changed by, date range, entity type, previous value, new value. | Audit-ready PDF and CSV export. |

## 12. Security, Roles, and Permissions

### Permission Categories

| Permission Category | Description |
|---|---|
| Read | View records or reports within authorized scope. |
| Create | Create new business records or configuration records. |
| Update | Modify existing records before or after controlled statuses. |
| Approve | Approve controlled business actions, access requests, or exceptions. |
| Cancel / Reverse | Cancel, reverse, or void controlled transactions where allowed. |
| Export | Export operational, audit, personal, or sensitive data. |
| Configure | Maintain module configuration, workflow rules, role rules, or integration settings. |
| Administer | Manage technical operations, users, roles, permissions, and system settings. |

### Global RBAC Matrix

| Role | Inventory Management | Purchasing | Sales | Order Fulfilment | Cross-Cutting / Security |
|---|---|---|---|---|---|
| Customer | None unless customer-facing inventory visibility is later approved. | None. | Create website order and view own order information where customer accounts exist. | View own shipment/order status where exposed by customer-facing channel. | Manage own customer authentication where supported. |
| Sales Assistant | Read availability. | Submit/read non-stocked product request status where integrated. | Create/update sales orders within scope. | Read fulfillment status for related sales orders. | No security administration access. |
| Sales Supervisor | Read inventory availability and exceptions affecting sales. | Read request status where relevant. | Review, approve, cancel, or override sales actions where configured. | Read fulfillment status and exceptions affecting sales. | No security administration access unless separately assigned. |
| Buyer | Read receipt status relevant to POs and buyer requests. | Create/update POs and process buyer requests. | Read non-stocked product request context. | None unless purchasing data is needed for fulfillment exceptions. | No security administration access. |
| Purchasing Manager | Read receipt exceptions and PO match issues. | Approve and review purchasing actions where configured. | Read non-stocked request activity where relevant. | None unless required by exception process. | No security administration access unless separately assigned. |
| Warehouse Operator | Create stock counts and goods receipts within scope. | Read PO details required for receipt. | Read order details only where operationally required. | Execute assigned pick, pack, ship, label, and completion tasks. | No security administration access. |
| Inventory Supervisor | Review and approve inventory discrepancies where configured. | Read POs and receipt exceptions. | Read sales demand/availability exceptions where relevant. | Read fulfillment consumption exceptions. | No security administration access unless separately assigned. |
| Fulfilment Operator | Read availability and trigger consumption events through fulfillment. | None. | Read released order details required for fulfillment. | Execute fulfillment tasks within assigned scope. | No security administration access. |
| Fulfilment Supervisor | Review inventory consumption and fulfillment stock exceptions. | None unless required for exception resolution. | Read released order and customer delivery context where needed. | Review and approve fulfillment exceptions where configured. | No security administration access unless separately assigned. |
| Finance / AP User | Read goods receipts and receipt exceptions. | Read PO and cost data. | None unless finance process requires sales data. | Read shipping cost data if applicable. | No security administration access. |
| Finance / AR User | None unless finance process requires inventory data. | None unless finance process requires PO data. | Read sales order data for invoicing or AR where applicable. | Read completion and shipment references where applicable. | No security administration access. |
| Security Administrator | Read access-relevant metadata only. | Read access-relevant metadata only. | Read access-relevant metadata only. | Read access-relevant metadata only. | Administer users, roles, permissions, SoD rules, access reviews, and emergency access. |
| System Administrator | Technical configuration and support access as approved. | Technical configuration and support access as approved. | Technical configuration and support access as approved. | Technical configuration and support access as approved. | Administer technical settings without implicit business approval authority. |
| Auditor | Read audit and evidence records. | Read audit and evidence records. | Read audit and evidence records. | Read audit and evidence records. | Read security, access, audit, SoD, and configuration reports. |
| Support User | Time-bound support access as approved. | Time-bound support access as approved. | Time-bound support access as approved. | Time-bound support access as approved. | No standing administrative access unless separately approved. |
| Integration Service Account | Scoped interface access only. | Scoped interface access only. | Scoped interface access only. | Scoped interface access only. | Non-interactive service identity with restricted permissions. |

## 13. Audit and Compliance Requirements

- The system shall record authentication events including successful login, failed login, logout, account lockout, session timeout, MFA challenge where applicable, and identity recovery where applicable.
- The system shall record authorization failures for controlled or sensitive actions.
- The system shall record access grants, access removals, role changes, permission changes, data-scope changes, and temporary access changes.
- The system shall record security configuration changes including authentication settings, SoD rules, approval rules, integration credentials metadata, and audit settings.
- The system shall record approval decisions and exception overrides with approver identity, timestamp, action, outcome, comments, and reference record.
- The system shall record data exports involving operational records, audit data, customer personal data, security configuration, or privileged access reports.
- The system shall support correlation of audit events across modules using transaction identifiers or correlation identifiers where available.
- The system shall retain audit data for 7 years for sales, purchasing, approval, and financially relevant business events; 3 years for inventory and fulfilment operational events; 1 year for authentication, authorization, and integration events unless linked to an incident; and 7 years for security incident evidence.
- The system shall support audit review without granting auditors permission to modify operational records or security configuration.

## 14. Non-Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---|---|
| SEC-NFR-001 | The system shall complete authorization checks within an agreed response threshold for interactive user actions. | Must | Given an authenticated user performs an authorized action, when the authorization service is operational, then the permission check shall complete within the agreed service level. |
| SEC-NFR-002 | The system shall fail closed for controlled actions when authorization status cannot be determined. | Must | Given a controlled action requires authorization, when authorization cannot be verified, then the system shall deny or hold the action rather than allowing it without verification. |
| SEC-NFR-003 | The system shall preserve audit logging integrity during normal operation and recovery scenarios. | Must | Given a controlled action is processed, when audit logging fails, then the system shall record or flag the failure according to audit failure policy. |
| SEC-NFR-004 | The system shall support backup and disaster recovery for identity, authorization, role, permission, SoD, approval, and audit data. | Must | Given a recovery event occurs, when security and audit data is restored, then role assignments, permissions, and audit records shall remain consistent. |
| SEC-NFR-005 | The system shall support accessible authentication, authorization, approval, and access review workflows. | Should | Given a user relies on keyboard navigation or assistive technology, when using security-related screens, then controls shall be operable and identifiable according to confirmed accessibility standard. |
| SEC-NFR-006 | The system shall maintain role and permission configuration in a maintainable structure that can be reviewed by authorized administrators. | Should | Given a security administrator reviews role configuration, when roles and permissions are displayed, then the system shall present them in a form that supports review and change control. |
| SEC-NFR-007 | The system shall support monitoring and alerting for critical security events where monitoring policy requires it. | Should | Given a critical security event occurs, when alerting rules are configured, then the system shall generate a notification or alert for authorized security reviewers. |

## 15. Exceptions and Edge Cases

- Identity provider is unavailable during login.
- User has duplicate or conflicting identities.
- User account is terminated but still has active ERP roles.
- User has stale temporary access after the business need has expired.
- User holds conflicting roles across modules.
- User attempts to approve a transaction they created.
- System administrator attempts a business approval action without explicit approval role.
- Support user requires emergency access outside normal approval hours.
- MFA factor is lost or unavailable.
- Customer forgets account credentials for authenticated website order visibility.
- Service account credentials expire, are rotated incorrectly, or are suspected of compromise.
- Audit logging is unavailable or delayed.
- Audit export contains customer personal data.
- Privacy deletion request conflicts with required audit retention.
- Integration request lacks a valid service identity or correlation identifier.
- Role assignment change conflicts with active transactions awaiting approval.

## 16. Dependencies

- Authentik must be configured as the ERP identity provider and integrated with Gravitee using OAuth/OIDC.
- Business owners must confirm named role owners and any exceptions to the initial approval authority and segregation-of-duties policies.
- Module specifications must identify local controlled actions and local audit events that inherit this cross-cutting standard.
- Product, customer, supplier, user, role, and permission master data ownership must be confirmed.
- Website identity behavior must support mandatory authenticated customer accounts for customer order visibility.
- Courier, finance, website, and inter-module integrations require approved service account and credential management processes.
- Audit storage, reporting, retention, and export tooling must support ERP-wide audit and compliance needs.

## 17. Assumptions

- ERP access for internal users requires authenticated identity.
- Global RBAC and security controls apply to Inventory Management, Purchasing, Sales Order Management, and Order Fulfilment.
- Module-specific requirements retain local workflow ownership while inheriting cross-cutting security controls from this document.
- Administrative users do not automatically receive business approval authority.
- Service accounts are non-human identities and shall not be used for interactive user access.
- Customer personal data exists in Sales and website order processes and requires protection.
- Authentik provides password-only authentication for the initial protected-network release; MFA is deferred unless external access or privileged-user policy changes.
- Sessions use a 60 minute idle timeout and an 8 hour absolute timeout.
- The ERP is single-tenant for ACME only.

## 18. Cross-Cutting Security Decisions

- Internal ERP users and authenticated customer users shall authenticate through Authentik using OAuth/OIDC integration with Gravitee.
- Password-only authentication is acceptable for the initial protected-network release. Authentik shall enforce password policy, account lockout, and recovery settings.
- Customer accounts are mandatory for website order submission and order visibility. Guest checkout is out of scope.
- Users may hold multiple operational roles when the combined roles do not violate configured SoD rules.
- Users shall not approve controlled transactions, exceptions, cancellations, access changes, or temporary access requests that they created or requested.
- Initial approval thresholds are configurable and default to: purchase orders over 10,000 require Purchasing Manager approval; inventory adjustments over 2,000 value or 10 percent variance require Inventory Supervisor approval; sales overrides and post-confirmation cancellations over 5,000 require Sales Supervisor approval; fulfilment substitutions, short picks, and completion overrides require Fulfilment Supervisor approval; security access changes require Security Administrator approval.
- Emergency access shall require Security Administrator approval before use where practical, shall be time-bound and ticket-linked, and shall be reviewed within one business day after use.
- Service account credential rotation is owned by the System Administrator with Security Administrator review and module owner coordination.
- API rate limits, IP restrictions, and network source controls shall be configured at Gravitee and the protected network boundary for integrations exposed outside the cluster. Internal Kubernetes service calls remain allowed only for trusted ERP services with service identity, authorization, correlation, and audit controls.
- Security and access-management workflows shall target WCAG 2.2 AA accessibility unless ACME adopts a stricter standard.

## 19. MVP Scope Decisions

- MVP privacy scope is baseline protection for B2B customer contact, billing, shipping, and order data: role-based access, audit trails, export logging, and retention rules. Automated GDPR, CCPA, consent, deletion, and privacy self-service workflows are out of scope unless ACME confirms a specific legal requirement.
- MVP role-design approval uses role-based ownership: Sales Supervisor for Sales roles, Purchasing Manager for Purchasing roles, Inventory Supervisor for Inventory roles, Fulfilment Supervisor for Fulfilment roles, and Security Administrator for security administration roles. Named-person ownership is operational configuration.
- MVP master-data ownership stays module-local: Inventory owns product, SKU, barcode, stocking, and serialization configuration; Sales owns customer account reference data; Purchasing owns supplier reference data; Authentik and Security Administration own users, roles, and permissions.

## 20. Acceptance Summary

The cross-cutting security requirements shall be considered complete when the ERP system has defined and testable MVP requirements for authentication, session management, authorization, RBAC, global roles, segregation of duties, approval authority, audit trail standards, privacy controls, service account security, master data security, security reporting, and non-functional security expectations. The specification shall remain separate from module-owned business workflows while providing shared controls that Inventory Management, Purchasing, Sales Order Management, and Order Fulfilment can inherit and apply locally. Additional privacy automation, named-person governance workflows, and dedicated master-data services are outside MVP scope.