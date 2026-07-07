# Retired Domain Scope: Security and Audit

Security and Audit is removed from MVP scope. This file is retained only as a de-scoping note and must not be used to generate active domain requirements.

No domain API, database, storage owner, shared project, policy service, audit service, reporting service, or application workflow should be generated from this retired scope.

Authentication and identity are cross-cutting platform concerns handled by Authentik and Gravitee using OAuth2/OIDC. ERP services consume trusted identity context from the platform; they do not own account lifecycle, password policy, MFA, lockout, or identity recovery requirements.

Authorization and access permissions are documented in each owning UI/application workflow and paired application API. Domain APIs remain authoritative for their own business authorization, validation, state transitions, data-scope checks, and business invariants.

Auditing, audit reporting, access reviews, privileged access reporting, segregation-of-duties reporting, audit-ready evidence workflows, audit export, and audit retention requirements are de-scoped for MVP. Ordinary operational logging, health checks, diagnostics, and correlation IDs remain platform and service concerns.

The `Auditor`, `System Administrator`, and `Security Administrator` roles are removed from MVP scope.

Source code, solution entries, deployment manifests, Docker images, routes, CI entries, and tests for this retired scope are intentionally left for the later code-removal implementation pass.