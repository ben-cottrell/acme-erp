# Security and Audit De-Scope Documentation Plan

This plan is for a documentation agent that must refactor repository documentation so a later implementation agent can update the code, solution, deployment manifests, and tests from the new MVP source of truth.

The new decision is broader than the previous Security Administration application de-scope. Remove the Security and Audit domain as an active bounded context, remove active audit/auditing requirements from MVP, and remove the `Auditor`, `System Administrator`, and `Security Administrator` roles from requirements and architecture. Replace the removed domain language with architecture documentation for cross-cutting authentication and identity handled by Authentik and Gravitee with OAuth2/OIDC. Authorization and access permissions are handled by the individual UI/application workflows and their paired APIs, with domain APIs still enforcing their own business invariants.

## Success Criteria

The task is complete only when all of the following are true:

- No documentation describes `Security and Audit` as an active domain bounded context, domain service, storage owner, project, database, API, policy service, or future MVP dependency.
- `docs/domain/security-and-audit/requirements.md` is removed or replaced by a retired-scope note that does not define active MVP requirements.
- No active MVP documentation requires audit reporting, audit exports, audit event envelopes, audit retention, access reviews, privileged access reviews, SoD conflict reporting, service account review, security configuration reporting, or audit-ready evidence workflows.
- The Audit Reporting application is removed from active application inventories, route tables, build instructions, and requirements, unless ACME explicitly keeps a non-audit reporting application under a different name and scope.
- No active requirements depend on `Acme.Erp.AuditReporting.Api`, `Acme.Erp.AuditReporting.Ui`, `src/Applications/AuditReporting/`, `audit-reporting-api`, `audit-reporting-ui`, `/apps/audit-reporting/api`, or `/apps/audit-reporting/ui`.
- No active requirements depend on `Acme.Erp.SecurityAdministration.Api`, `Acme.Erp.SecurityAdministration.Ui`, `src/Applications/SecurityAdministration/`, `security-administration-api`, `security-administration-ui`, `/apps/security-administration/api`, or `/apps/security-administration/ui`.
- Architecture documentation clearly states that authentication and identity are cross-cutting platform concerns handled by Authentik and Gravitee using OAuth2/OIDC.
- Architecture documentation clearly states that authorization/access permissions are owned by each individual UI/application workflow and paired application API, with domain APIs enforcing business authorization, validation, state transitions, and data-scope rules for their bounded context.
- The role catalog no longer includes `Auditor`, `System Administrator`, or `Security Administrator` as MVP personas, users, actors, approvers, reviewers, or permissions subjects.
- Remaining MVP personas are application/domain business personas only, such as Customer, Sales Assistant, Sales Supervisor, Buyer, Purchasing Manager, Warehouse Operator, Inventory Supervisor, Fulfilment Operator, Fulfilment Supervisor, Support User if still required, and Integration Service Account if still required.
- Build and implementation documentation no longer instructs agents to scaffold, build, route, validate, publish, or test Security Administration, Audit Reporting, Security and Audit domain services, audit libraries, audit databases, or audit-specific contracts.
- Repository-wide markdown validation searches find only retired-scope notes or this plan for removed concepts, and every remaining hit is explicitly reviewed.

## Non-Goals

- Do not remove Authentik or Gravitee. They become the controlling architecture for authentication, identity, OAuth2/OIDC token validation, and gateway identity propagation.
- Do not create a replacement Security and Audit domain, Audit service, Security service, Security Administration application, or Audit Reporting application.
- Do not move audit workflows into another application. Auditing is de-scoped for MVP.
- Do not introduce central RBAC, SoD, access review, or privileged access administration as a separate service. MVP access permissions belong with each UI/application workflow and paired API.
- Do not delete source code, Kubernetes YAML, CI workflow entries, Dockerfiles, or solution entries during the documentation pass unless the documentation agent is explicitly asked to perform code removal too. This plan should make the later code-removal work unambiguous.
- Do not remove ordinary operational logging, health checks, correlation IDs, or technical observability needed to run services. Those are not audit/compliance scope.

## De-Scoping Decision

Document this decision before making detailed edits:

> The MVP no longer includes a Security and Audit bounded context, Security Administration application, Audit Reporting application, or active auditing/compliance workflows. Authentication and identity are cross-cutting platform concerns handled by Authentik and Gravitee through OAuth2/OIDC. Each role-focused UI/application owns its own access-permission experience and its paired API enforces workflow authorization before calling domain APIs. Domain APIs remain authoritative for their own business rules, state transitions, data ownership, and domain-specific authorization checks. The `Auditor`, `System Administrator`, and `Security Administrator` roles are removed from MVP scope.

Use this wording, or an equivalent concise statement, in the architecture documents that currently describe boundaries, identity, applications, role catalogs, and MVP scope.

## Target Architecture After Documentation Refactor

### Authentication and Identity

- Authentik is the OAuth2/OIDC identity provider for internal users, customer users where applicable, and service identities where required.
- Gravitee is the single ingress point for user and external client traffic.
- Gravitee integrates with Authentik, validates sessions/tokens, applies coarse route policy, and forwards trusted identity claims, bearer tokens where needed, request metadata, and correlation IDs to downstream services.
- ERP UIs, application APIs, and domain APIs consume forwarded identity context; they do not own account lifecycle, password policy, MFA, lockout policy, or identity recovery requirements.
- Documentation should use `OAuth2/OIDC` consistently and avoid implying that ERP services implement an identity provider.

### Authorization and Access Permissions

- Each UI/application owns its own access-permission requirements for screens, commands, workflow actions, and role-specific navigation.
- Each paired application API enforces application workflow authorization before orchestrating domain APIs.
- Each domain API enforces domain-specific business authorization, data-scope checks, validation, state transition guards, and business invariants before changing domain state.
- Permission catalogs should be documented inside the owning application or domain requirements, not in a central Security and Audit domain.
- Segregation-of-duties should be removed where it is only a security/compliance framework. If a same-user approval guard is still a real business rule, document it locally in the owning domain using business language such as `requester cannot approve their own exception` and do not refer to central SoD policy.

### Auditing De-Scope

- Remove active requirements for audit event envelopes, audit evidence, audit-ready exports, access review evidence, privileged access reporting, audit retention, security event review, and audit report/query contracts.
- Keep only normal operational logging, error handling, correlation IDs, and health/diagnostic observability where needed for application operation.
- Remove `Audit Reporting` as an MVP application unless a separate product decision explicitly renames and re-scopes it away from auditing.

## Files to Update

### Domain Requirements

Update `docs/domain/security-and-audit/requirements.md` first.

Preferred approach: delete the file and remove the folder in the documentation pass if the repository accepts deleting retired requirement areas. If deletion is not desirable, replace the file with a short retired-scope note that includes:

- The Security and Audit domain is removed from MVP scope.
- No domain API, database, storage, shared project, policy service, audit service, or requirements should be generated from this file.
- Authentication and identity are now documented as cross-cutting architecture handled by Authentik and Gravitee.
- Authorization and access permissions are now documented in each owning UI/application and paired API, with domain APIs enforcing local business authorization.
- Auditing and audit reporting are de-scoped for MVP.
- The `Auditor`, `System Administrator`, and `Security Administrator` roles are removed from MVP scope.
- Code removal is intentionally deferred to the implementation agent unless this documentation agent is explicitly assigned code cleanup.

Then review all remaining domain requirement files:

| File | Required change |
|---|---|
| `docs/domain/sales/requirements.md` | Remove `Auditor`, Security and Audit dependencies, audit export/reporting requirements, audit retention, and central audit envelope references. Keep local business history only if it is operationally required by Sales. |
| `docs/domain/purchasing/requirements.md` | Remove `Auditor`, Security and Audit dependencies, audit/compliance exports, access review, SoD-policy references, and central audit envelope references. Rewrite approval self-checks only as local purchasing business rules if still needed. |
| `docs/domain/inventory-management/requirements.md` | Remove `Auditor`, Security and Audit dependencies, audit report/export scope, audit retention, and central audit envelope references. Keep stock movement history only if needed for operations. |
| `docs/domain/order-fulfilment/requirements.md` | Remove `Auditor`, Security and Audit dependencies, fulfilment audit reporting, audit retention, and central audit envelope references. Keep shipment/label evidence only if it is operational fulfilment data, not audit evidence. |

### Application Requirements

Remove or retire `docs/application/audit-reporting/requirements.md`. The retired note should state that Audit Reporting is not part of MVP and must not generate API/UI projects, routes, manifests, tests, or application workflows.

Review each remaining application requirements file and update it to localize access permissions and remove audit/security-role dependencies:

| File | Required change |
|---|---|
| `docs/application/sales-assistant/requirements.md` | Remove Audit Reporting, `Auditor`, Security and Audit dependencies, audit exports, and central permission policy references. Document Sales Assistant/Sales Supervisor screen and command permissions locally. |
| `docs/application/customer-ordering/requirements.md` | Remove audit export/reporting and central Security and Audit references. Keep customer authentication through Authentik/Gravitee and customer-specific access checks in the app/API. |
| `docs/application/buyer/requirements.md` | Remove Audit Reporting, `Auditor`, Security and Audit dependencies, audit exports, and SoD-policy references. Keep buyer/purchasing-manager access rules locally. |
| `docs/application/warehouse-operator/requirements.md` | Remove audit context/export language and Security and Audit dependency. Keep Warehouse Operator route/screen permissions and operational exception handling locally. |
| `docs/application/fulfilment-operator/requirements.md` | Remove audit context/export language, `Auditor`, Audit Reporting, and Security and Audit dependency. Keep Fulfilment Operator workflow permissions locally. |
| `docs/application/inventory-supervisor/requirements.md` | Remove audit/reporting exports, `Auditor`, Audit Reporting, and Security and Audit dependency. Keep Inventory Supervisor review/approval permissions only where they are operational workflow scope. |
| `docs/application/fulfilment-supervisor/requirements.md` | Remove audit/reporting exports, `Auditor`, Audit Reporting, and Security and Audit dependency. Keep Fulfilment Supervisor operational approval permissions locally. |

There is currently no active `docs/application/security-administration/requirements.md` in the workspace, but the documentation agent should still search for the folder and retire it if it reappears.

### Architecture Documentation

Update these files to replace Security and Audit/audit architecture with the new cross-cutting identity and localized authorization architecture:

| File | Required change |
|---|---|
| `docs/architecture/overview.md` | Remove Security and Audit from domain inventories. Remove Audit Reporting from application inventories. Add the de-scoping decision and summarize Authentik/Gravitee identity plus per-application access permissions. |
| `docs/architecture/domain-and-application-boundaries.md` | Remove the Security and Audit domain row. Remove Audit Reporting from `Application Services`. Update boundary rules to state authentication/identity is cross-cutting and authorization is local to applications/domains. |
| `docs/architecture/module-boundaries.md` | Remove Security and Audit from domain/application compatibility matrices. Remove Audit Reporting. Remove central audit/security module expectations. |
| `docs/architecture/api-gateway-and-identity.md` | Keep and strengthen Authentik/Gravitee OAuth2/OIDC responsibilities. Remove Audit Reporting routes, audit-specific API responsibilities, central role catalogs containing removed roles, SoD policy language, and Security and Audit dependencies. |
| `docs/architecture/monorepo-structure.md` | Remove Security and Audit domain project/folder conventions if present. Remove Audit Reporting project, image, manifest, and route rows. Ensure naming rules describe the remaining four domains and seven application API/UI pairs. |
| `docs/architecture/data-architecture.md` | Remove Security and Audit storage ownership, audit event storage, audit/reporting storage, access review state, service account policy storage, and central security policy ownership. |
| `docs/architecture/cross-cutting-projects.md` | Retire the file or keep only a retired-scope note. Keep authentication, authorization, correlation, logging, validation, and health-check behavior documented as platform or owning-service conventions rather than shared-project requirements. |
| `docs/architecture/testing-and-quality.md` | Remove audit/compliance evidence testing, Audit Reporting tests, Security and Audit tests, and removed roles from quality gates. Keep authentication/authorization tests for each app/API. |
| `docs/architecture/decisions-and-open-questions.md` | Add the new de-scope decision. Close or remove questions that assume Security and Audit, Audit Reporting, `Auditor`, `System Administrator`, or `Security Administrator` remain in MVP. |
| `docs/architecture/service-internal-architecture.md` | Remove central audit/security service expectations if present. Keep local service authorization and operational logging guidance. |

The remaining active application API/UI pairs should be seven: Sales Assistant, Customer Ordering, Buyer, Warehouse Operator, Fulfilment Operator, Inventory Supervisor, and Fulfilment Supervisor.

### Build Documentation

Update active build and implementation documentation so future agents do not regenerate removed code:

| File | Required change |
|---|---|
| `build/README.md` | Remove Audit Reporting and Security Administration from service inventory. Remove audit/security-domain language if present. |
| `build/domain-application-implementation-plan.md` | Remove Audit Reporting from success criteria, application inventory, solution project list, Kubernetes manifest list, image/Dockerfile list, route validation, and implementation notes. Replace Security and Audit notes with Authentik/Gravitee plus localized app/domain authorization guidance. |
| `build/clean-slate-teardown-build-test-plan.md` | Remove Audit Reporting and Security Administration image, manifest, project, route, and validation references. Remove audit/security-domain build expectations. |

If a build document is historical rather than active, add a short supersession note at the top pointing to this plan. Prefer editing active instructions that another agent is likely to execute.

### Agent and Prompt Documentation

Review customization and agent files so future generated requirements do not recreate retired scope:

- `.github/agents/erp-requirements-analyst.agent.md`
- `.github/agents/erp-architecture-specification.agent.md`
- `.github/copilot-instructions.md`
- `AGENTS.md`
- Any `*.instructions.md`, `*.prompt.md`, or `*.agent.md` files that list domains, applications, roles, audit requirements, or security administration scope.

Required changes:

- Remove Security and Audit as a domain requirements area.
- Remove Audit Reporting and Security Administration as application areas.
- Remove `Auditor`, `System Administrator`, and `Security Administrator` from persona lists.
- Add guidance that authentication/identity are Authentik/Gravitee cross-cutting architecture concerns, while access permissions belong in each application/domain requirements file.
- Add guidance that auditing is de-scoped for MVP.

## Execution Phases

### Phase 1: Preflight

Run from the repository root:

```powershell
Set-Location C:/dev/acme-erp
git status --short
```

Do not revert unrelated user changes. If a target document already has unrelated edits, preserve them and make the smallest compatible change.

### Phase 2: Retire Removed Requirement Sources

Retire or delete these first so architecture and build documents no longer derive active scope from them:

1. `docs/domain/security-and-audit/requirements.md`
2. `docs/application/audit-reporting/requirements.md`
3. Any reintroduced `docs/application/security-administration/requirements.md`

After this phase, no active requirements file should define Security and Audit domain scope, Audit Reporting workflows, Security Administration workflows, the removed roles, audit exports, access review, privileged access reporting, or central security policy administration.

### Phase 3: Update Controlling Architecture Docs

Edit the architecture docs in this order:

1. `docs/architecture/domain-and-application-boundaries.md`
2. `docs/architecture/overview.md`
3. `docs/architecture/api-gateway-and-identity.md`
4. `docs/architecture/module-boundaries.md`
5. `docs/architecture/monorepo-structure.md`
6. `docs/architecture/data-architecture.md`
7. `docs/architecture/cross-cutting-projects.md` retired note
8. `docs/architecture/testing-and-quality.md`
9. `docs/architecture/service-internal-architecture.md`
10. `docs/architecture/decisions-and-open-questions.md`

Keep inventories consistent across all tables. The remaining bounded contexts should be Sales, Purchasing, Inventory Management, and Order Fulfilment. The remaining application API/UI pairs should be Sales Assistant, Customer Ordering, Buyer, Warehouse Operator, Fulfilment Operator, Inventory Supervisor, and Fulfilment Supervisor.

### Phase 4: Localize Authorization and Permission Requirements

Update every remaining domain and application requirements file so permissions are owned locally:

- Application requirements should define route, screen, command, workflow, and data visibility permissions for their own users.
- Application APIs should enforce workflow permissions before orchestration.
- Domain requirements should define business authorization rules for state changes and data access inside that bounded context.
- Remove references to central RBAC, central SoD policy, central audit envelope, Security and Audit services, Audit Reporting, Security Administration, and removed roles.
- Replace generic `auditable` language with concrete business history only when that history is necessary for the workflow, for example order status history or stock movement history.

### Phase 5: Update Build, Agent, and Prompt Docs

Remove retired domains, applications, roles, routes, images, manifests, and project expectations from active build instructions and agent customization files. This prevents a later code agent from preserving or recreating removed code because of stale documentation.

### Phase 6: Documentation Validation

Run these searches from the repository root:

```powershell
$markdownFiles = Get-ChildItem -Path . -Filter *.md -Recurse
$markdownFiles | Select-String -Pattern 'Security and Audit|security-and-audit|SecurityAdministration|Security Administration|security-administration|Audit Reporting|AuditReporting|audit-reporting' -CaseSensitive:$false
$markdownFiles | Select-String -Pattern 'Auditor|System Administrator|Security Administrator' -CaseSensitive:$false
$markdownFiles | Select-String -Pattern 'audit|auditing|audit-ready|audit event|audit envelope|audit export|audit retention|access review|privileged access|segregation-of-duties|SoD' -CaseSensitive:$false
$markdownFiles | Select-String -Pattern 'Acme\.Erp\.AuditReporting|Acme\.Erp\.SecurityAdministration|src/Applications/AuditReporting|src/Applications/SecurityAdministration|/apps/audit-reporting|/apps/security-administration' -CaseSensitive:$false
```

Expected results:

- The first and fourth searches should return no active documentation references after edits, except retired-scope notes or this plan.
- The second search should return no active persona, role, permission, route, report, or acceptance-criteria references.
- The third search may return operational logging or ordinary business history references, but each remaining result must be reviewed to confirm it is not MVP auditing/compliance scope.
- Any remaining `SoD` or `segregation-of-duties` hit should be rewritten as a local business approval rule or removed.

Also run inventory consistency searches:

```powershell
$markdownFiles | Select-String -Pattern 'Domain bounded context|Domain Bounded Contexts|Application Services|Application API/UI pairs|Route Conventions|Project Conventions|service inventory' -CaseSensitive:$false
```

Manually verify every remaining domain and application table omits Security and Audit, Audit Reporting, and Security Administration.

## Handoff to Code Removal Agent

After documentation de-scoping is complete, hand off these code-removal targets to the implementation agent. The implementation agent should use the updated documentation as the source of truth and remove code that exists only for retired scope.

### Solution and Source Projects

- Remove `src/Applications/AuditReporting/`.
- Remove `src/Applications/SecurityAdministration/` if present.
- Remove any `src/Domain/SecurityAndAudit/`, `src/Domain/SecurityAndAudit.*`, or equivalent Security and Audit source folders if present.
- Remove `Acme.Erp.AuditReporting.Api` and `Acme.Erp.AuditReporting.Ui` from `Acme.Erp.slnx`.
- Remove `Acme.Erp.SecurityAdministration.Api` and `Acme.Erp.SecurityAdministration.Ui` from `Acme.Erp.slnx` if present.
- Remove any Security and Audit domain projects from `Acme.Erp.slnx` if present.
- Remove shared audit-only libraries such as `Acme.Erp.Audit` only if they are not required for operational logging or correlation after the documentation update.

### Deployment and Local Runtime

- Remove `build/k8s/services/audit-reporting-api.yaml` and `build/k8s/services/audit-reporting-ui.yaml`.
- Remove `build/k8s/services/security-administration-api.yaml` and `build/k8s/services/security-administration-ui.yaml` if present.
- Remove Audit Reporting, Security Administration, and Security and Audit artifacts from `build/skaffold.yaml`.
- Remove Audit Reporting and Security Administration route configuration from `build/k8s/gravitee/route-config.yaml`.
- Remove Audit Reporting, Security Administration, and Security and Audit validation checks from `build/scripts/validate-local.ps1`.
- Remove Audit Reporting, Security Administration, and Security and Audit Docker image build/publish entries from CI workflows.

### Code Refactor Guidance

- Replace central security/audit dependencies with Authentik/Gravitee identity context and local application/domain authorization checks.
- Remove `Auditor`, `SystemAdministrator`, and `SecurityAdministrator` enum values, constants, seed data, claims policies, tests, UI navigation items, and route policies.
- Remove audit-reporting controllers, pages, clients, DTOs, OpenAPI registrations, tests, health checks, manifests, and images.
- Remove access review, privileged access, audit export, audit retention, audit envelope, and central SoD-policy types unless they are explicitly re-scoped as local business workflow history.
- Keep normal ASP.NET Core logging, OpenTelemetry/correlation where present, health endpoints, and operational diagnostics.

### Code Validation Commands

Run the most focused checks available after code removal, then broaden:

```powershell
dotnet build Acme.Erp.slnx
skaffold diagnose -f build/skaffold.yaml
./build/scripts/validate-local.ps1
```

If tests exist for touched projects, run them before the full solution build. If CI workflows include image or manifest validation, update and run the local equivalent.

## Final Review Checklist

- [ ] Security and Audit requirements are deleted or replaced with a retired-scope note.
- [ ] Audit Reporting requirements are deleted or replaced with a retired-scope note.
- [ ] Security Administration remains absent or retired.
- [ ] Architecture domain inventories list only Sales, Purchasing, Inventory Management, and Order Fulfilment.
- [ ] Architecture application inventories list only Sales Assistant, Customer Ordering, Buyer, Warehouse Operator, Fulfilment Operator, Inventory Supervisor, and Fulfilment Supervisor.
- [ ] Authentik and Gravitee OAuth2/OIDC ownership is clear in architecture documentation.
- [ ] Authorization/access permissions are documented in the owning UI/application and domain requirements, not in a central Security and Audit domain.
- [ ] Auditing, audit reporting, audit exports, audit retention, access review, privileged access reporting, and central SoD policy are removed from MVP requirements.
- [ ] `Auditor`, `System Administrator`, and `Security Administrator` roles are removed from active requirements and architecture.
- [ ] Build docs no longer mention removed projects, routes, images, manifests, or solution entries as active scope.
- [ ] Agent/prompt customization files no longer recreate removed domain, applications, roles, or audit requirements.
- [ ] Markdown validation searches have been run and each remaining hit is either removed, rewritten, or explicitly justified as a retired-scope note/this plan.
- [ ] The code-removal handoff lists all source, solution, deployment, route, validation, and CI cleanup targets discovered during documentation review.