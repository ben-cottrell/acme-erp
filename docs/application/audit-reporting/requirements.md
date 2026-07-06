# Application Requirements: Audit Reporting

## Purpose

The Audit Reporting application supports auditors, security administrators, and business control owners who review audit trails, approvals, exceptions, access reports, security events, and controlled business activity across domains.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.AuditReporting.Ui` |
| API | `Acme.Erp.AuditReporting.Api` |
| Primary users | Auditor, Security Administrator, business control owners |
| Database | None |
| Domain APIs consumed | Security and Audit services, Sales, Purchasing, Inventory Management, Order Fulfilment |

The Audit Reporting UI calls only the Audit Reporting API. The Audit Reporting API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Display audit records, status history, approval decisions, exception records, and export events from domain APIs and audit services.
- Provide user access review, privileged access, failed authentication, SoD conflict, approval exception, service account activity, customer data export, and security configuration change reports.
- Provide operational audit reports for sales orders, purchase orders, inventory movements, goods receipt exceptions, fulfilment completion, courier transactions, and label events.
- Support CSV, spreadsheet, PDF, or audit-ready export formats where specified by the source report requirements.
- Record audit export actions through security/audit services.

## Functional Requirements

| ID | Requirement |
|---|---|
| ARP-APP-001 | The application shall provide read-only access to audit and control reports for authorized users. |
| ARP-APP-002 | The application shall request audit and report data from domain APIs or audit services without storing report data locally. |
| ARP-APP-003 | The application shall enforce report filters by user role, business scope, module/domain, date range, status, exception type, and privacy restrictions. |
| ARP-APP-004 | The application shall record export actions for operational, audit, personal, or sensitive data. |
| ARP-APP-005 | The application shall protect customer personal data in reports according to role, purpose, and data scope. |
| ARP-APP-006 | The application shall provide accessible report review and export workflows. |

## Security and Audit

The application must never grant report access by presentation logic alone. Security and Audit services and the source domain APIs remain authoritative for authorization, export logging, privacy restrictions, and audit retention.