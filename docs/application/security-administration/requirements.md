# Application Requirements: Security Administration

## Purpose

The Security Administration application supports security administrators and system administrators who manage users, roles, permissions, service account policy, access reviews, segregation-of-duties configuration, temporary access, emergency access, and security configuration review.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.SecurityAdministration.Ui` |
| API | `Acme.Erp.SecurityAdministration.Api` |
| Primary users | Security Administrator, System Administrator |
| Database | None |
| Domain APIs consumed | Security and Audit services, Authentik integration, domain metadata APIs |

The Security Administration UI calls only the Security Administration API. The Security Administration API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Manage users, roles, permission assignments, data scopes, temporary access, and access removal workflows through security services and Authentik integration.
- Configure or review SoD rules, approval authority, emergency access, and service account credential rotation metadata.
- Display access review, privileged access, service account activity, and security configuration change views.
- Preserve the rule that System Administrator access does not imply business approval authority.

## Functional Requirements

| ID | Requirement |
|---|---|
| SAD-APP-001 | The application shall support access provisioning and access removal workflows through security services or Authentik integration. |
| SAD-APP-002 | The application shall display role, permission, data scope, privileged access, and temporary access configuration for review. |
| SAD-APP-003 | The application shall support SoD conflict review and configuration where approved by security policy. |
| SAD-APP-004 | The application shall support service account credential rotation workflow visibility without exposing secrets in application logs or screens. |
| SAD-APP-005 | The application shall prevent system administration screens from granting business approval authority unless explicit business roles are assigned through approved policy. |
| SAD-APP-006 | The application shall provide accessible authentication, authorization, approval, and access review workflows targeting WCAG 2.2 AA unless ACME adopts a stricter standard. |

## Security and Audit

Security and Audit services, Authentik, and domain APIs remain authoritative for identity, authorization, SoD, access state, audit events, and retention. The application is a workflow and presentation layer only.
