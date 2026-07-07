# Retired Application Scope: Audit Reporting

Audit Reporting is removed from MVP scope. This file is retained only as a de-scoping note and must not be used to generate active application requirements.

No API project, UI project, route, Kubernetes manifest, Docker image, test project, report workflow, export workflow, or application service should be generated for Audit Reporting.

Authentication and identity are cross-cutting platform concerns handled by Authentik and Gravitee using OAuth2/OIDC. Access permissions belong in each remaining role-focused UI/application workflow and its paired application API.

Auditing, audit-ready exports, audit evidence review, access reviews, privileged access reporting, segregation-of-duties reporting, security-event review, and central audit report/query contracts are de-scoped for MVP. Ordinary operational logging, diagnostics, health checks, and correlation IDs remain in scope for operating services.

The `Auditor`, `System Administrator`, and `Security Administrator` roles are removed from MVP scope.

Code removal for `Acme.Erp.AuditReporting.Api`, `Acme.Erp.AuditReporting.Ui`, `src/Applications/AuditReporting/`, `audit-reporting-api`, `audit-reporting-ui`, and `/apps/audit-reporting/*` is intentionally deferred to the later code-removal implementation pass.