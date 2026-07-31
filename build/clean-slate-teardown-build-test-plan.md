# Clean-Slate Teardown, Build, and Test Plan

This plan is for an execution agent that must return the local Docker Desktop Kubernetes runtime to a clean state, delete locally built ERP images, and then rebuild and validate the full system from scratch.

The runtime dependencies are assumed to be installed and available on the command line: Docker, Helm, `kubectl`, Skaffold, and the .NET SDK.

## Scope

The local runtime owns these resources:

- Kubernetes namespace: `erp-local`
- Skaffold config: `build/skaffold.yaml`
- Local app images:
  - `acme-erp/sales-api`
  - `acme-erp/purchasing-api`
  - `acme-erp/inventory-management-api`
  - `acme-erp/order-fulfilment-api`
  - `acme-erp/sales-assistant-api`
  - `acme-erp/sales-assistant-ui`
  - `acme-erp/customer-ordering-api`
  - `acme-erp/customer-ordering-ui`
  - `acme-erp/buyer-api`
  - `acme-erp/buyer-ui`
  - `acme-erp/warehouse-operator-api`
  - `acme-erp/warehouse-operator-ui`
  - `acme-erp/fulfilment-operator-api`
  - `acme-erp/fulfilment-operator-ui`
- Generated local state: `build/.local/`

The automated teardown is intentionally broader than the ERP resource list: it uninstalls every Helm release in every namespace in the active `docker-desktop` context and runs `docker system prune -a --volumes --force`. The Docker prune removes all unused Docker containers, images, volumes, networks, and build cache on the machine. Do not run it when the Docker Desktop context contains workloads or unused Docker resources that must be preserved.

## Success Criteria

The task is complete only when all of the following are true:

- `erp-local` was removed during teardown and recreated during bootstrap.
- Skaffold-rendered Authentik and Gravitee gateway workloads are deployed and Ready.
- SQL Server is Ready and `sqlserver-bootstrap` completed.
- All 14 Gravitee route ConfigMaps exist with database-less sync labels.
- All 14 ASP.NET Core deployments are Ready.
- All 14 local `acme-erp/*` images were rebuilt after deletion.
- `dotnet build Acme.Erp.slnx` succeeds.
- `skaffold diagnose -f build/skaffold.yaml` succeeds.
- `build/scripts/validate-local.ps1` succeeds.

## Phase 1: Preflight and Evidence Capture

Run from the repository root.

```powershell
Set-Location C:\dev\acme-erp

docker version
docker info
kubectl version --client=true
kubectl config current-context
helm version --short
skaffold version
dotnet --version
```

The expected Kubernetes context is `docker-desktop`. If the current context is different, stop and switch context explicitly:

```powershell
kubectl config use-context docker-desktop
```

Capture the current state before deleting anything:

```powershell
kubectl get namespaces
kubectl get all,pvc,secrets,configmaps -n erp-local
helm list --all-namespaces
docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | Select-String '^acme-erp/'
docker system df
```

It is acceptable for some commands to report that `erp-local` does not exist; teardown must remain idempotent.

## Phase 2: Full Runtime Teardown

Run the automated teardown. It stops local Skaffold and `kubectl port-forward` processes, deletes Skaffold-managed resources, uninstalls every Helm release in every namespace in the active `docker-desktop` context, and deletes `erp-local`. It is non-interactive.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build\scripts\teardown-local.ps1
```

The script treats already-absent ERP resources as a successful teardown. If namespace deletion fails, it captures namespace, PVC, and PV diagnostics and stops without force-removing finalizers.

## Phase 3: Delete Local Images and Generated State

The teardown script removes all local `acme-erp/*` images and `build/.local`, then runs `docker system prune -a --volumes --force`. This globally removes unused Docker resources, including non-ERP resources. It does not remove Docker resources that are still in use.

Verify the expected local clean state after the script completes:

```powershell
kubectl get namespace erp-local
docker images --format "{{.Repository}}:{{.Tag}}" | Select-String '^acme-erp/'
Test-Path build/.local
```

The namespace lookup should report NotFound, the image check should produce no rows, and `Test-Path` should return `False`.

## Phase 4: Clean-Slate Build

Validate the solution and Skaffold config before deploying.

```powershell
dotnet sln Acme.Erp.slnx list
dotnet build Acme.Erp.slnx
skaffold diagnose -f build/skaffold.yaml
```

Bootstrap the platform first. Use `-RotateSecrets` only if `build/.local` was not removed and a forced credential refresh is needed.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build\scripts\bootstrap-local.ps1 -DeploymentScope platform
```

Wait and verify platform readiness before building apps:

```powershell
kubectl get namespace erp-local
kubectl rollout status statefulset/sqlserver -n erp-local --timeout=600s
kubectl wait --for=condition=complete job/sqlserver-bootstrap -n erp-local --timeout=600s
kubectl rollout status deployment/authentik-server -n erp-local --timeout=600s
kubectl rollout status deployment/authentik-worker -n erp-local --timeout=600s
kubectl rollout status statefulset/authentik-postgresql -n erp-local --timeout=600s
kubectl rollout status deployment/gravitee-apim-gateway -n erp-local --timeout=600s
kubectl get configmap -n erp-local --selector "managed-by=gravitee.io,gio-type=apidefinitions.gravitee.io"
kubectl get service gravitee-apim-gateway -n erp-local
```

Then build and deploy the app layer from scratch:

```powershell
.\build\scripts\bootstrap-local.ps1 -DeploymentScope apps
```

Confirm the local images exist again:

```powershell
docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | Select-String '^acme-erp/'
```

## Phase 5: Full Validation

Run the repository validation script:

```powershell
.\build\scripts\validate-local.ps1
```

This script should build the solution, verify expected secrets and config, wait for SQL Server, Authentik, and Gravitee workloads, and perform in-cluster HTTP checks against the placeholder services and platform endpoints.

Also run a final direct readiness snapshot:

```powershell
kubectl get pods -n erp-local
kubectl get deployments,statefulsets -n erp-local
kubectl get jobs -n erp-local
```

Expected high-level results:

- `sqlserver-bootstrap`: `Complete 1/1`
- all app deployments: `1/1`
- all Authentik deployments/StatefulSets: `1/1`
- Gravitee gateway deployment: `1/1`
- Gravitee gateway service: `LoadBalancer` on port `8082`

## Phase 6: Failure Triage Guide

If platform deployment fails:

```powershell
skaffold render -f build/skaffold.yaml -p platform
kubectl get events -n erp-local --sort-by=.lastTimestamp
kubectl get configmap -n erp-local --selector "managed-by=gravitee.io,gio-type=apidefinitions.gravitee.io"
```

If teardown fails while uninstalling Helm releases, inspect the remaining cluster-wide releases before retrying:

```powershell
helm list --all-namespaces
```

If Docker cleanup fails, inspect Docker's remaining resource usage before retrying:

```powershell
docker system df
```

If pods are not Ready:

```powershell
kubectl get pods -n erp-local -o wide
kubectl describe pod -n erp-local <pod-name>
kubectl logs -n erp-local <pod-name> --tail=200
```

Known local chart sensitivities:

- Authentik Helm rendering requires the generated `build/.local/authentik.generated-values.yaml` file.
- Gravitee local mode is database-less gateway-only; Management API, portal, UI, MongoDB, and Elasticsearch should not be expected locally.
- Gravitee db-less route synchronization requires route ConfigMaps labeled `managed-by=gravitee.io` and `gio-type=apidefinitions.gravitee.io`.

If image deletion or rebuild fails:

```powershell
docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | Select-String '^acme-erp/'
skaffold build -f build/skaffold.yaml -p apps
```

If `validate-local.ps1` fails during HTTP checks, first verify the temporary curl pod was removed, then check services directly:

```powershell
kubectl get pods -n erp-local | Select-String 'erp-validate'
kubectl get svc -n erp-local
kubectl run erp-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n erp-local -- curl -s -o /dev/null -w "HTTP %{http_code}\n" http://sales-api/healthz
```

## Completion Report Template

When finished, report:

- Teardown actions completed, including stopped processes, every removed Helm release, namespace deletion, ERP image deletion, generated-state removal, and the global unused-Docker prune.
- Whether `build/.local` was removed and regenerated.
- Build command results: `dotnet build`, `skaffold diagnose`, and app image rebuild.
- Helm release versions deployed.
- Final Kubernetes readiness snapshot.
- `validate-local.ps1` result.
- Any residual risks, especially if Gravitee route publication through the Management API remains unimplemented.