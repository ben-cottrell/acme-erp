# Retired Scope: Cross-Cutting Projects

Shared cross-cutting projects are not part of MVP documentation. This file is retained only as a de-scoping note and must not be used to generate active architecture or implementation requirements.

No `src/Shared/`, `tests/Shared/`, `Acme.Erp.ApiConventions`, `Acme.Erp.Security`, `Acme.Erp.Observability`, `Acme.Erp.Integration`, `Acme.Erp.Testing`, or equivalent shared project should be generated from this file.

Authentik and Gravitee remain the documented owners for authentication, identity, OAuth2/OIDC integration, ingress, and route policy. Access permissions and authorization behavior remain documented in each owning application/domain requirement.

Service conventions for OpenAPI, health checks, logging, diagnostics, correlation IDs, idempotency, service identity, authorization, and operational history remain documented in owning service, architecture, and requirement files. Implementations should keep those responsibilities inside the owning service unless a later explicit architecture decision reintroduces shared projects.

Source code, solution entries, package references, deployment manifests, CI entries, and tests for any existing shared-project scope are intentionally left for the later code-removal implementation pass.