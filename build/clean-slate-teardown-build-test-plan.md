# Clean-Slate Teardown, Build, and Test Plan

This plan is for an execution agent that must return the local Docker Desktop Kubernetes runtime to a clean state, delete locally built ERP images, and then rebuild and validate the full system from scratch.

The runtime dependencies are assumed to be installed and available on the command line: Docker, Helm, `kubectl`, Skaffold, and the .NET SDK.

## Scope

The local runtime owns these resources:

- Kubernetes namespace: `erp-local`
- Helm releases in `erp-local`: `authentik`, `gravitee`
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
  - `acme-erp/inventory-supervisor-api`
  - `acme-erp/inventory-supervisor-ui`
  - `acme-erp/fulfilment-supervisor-api`
  - `acme-erp/fulfilment-supervisor-ui`
  - `acme-erp/security-administration-api`
  - `acme-erp/security-administration-ui`
  - `acme-erp/audit-reporting-api`
  - `acme-erp/audit-reporting-ui`
- Generated local state: `build/.local/`

Do not delete unrelated namespaces, images, volumes, or Docker resources unless the user explicitly asks for a broader machine cleanup.

## Success Criteria

The task is complete only when all of the following are true:

- `erp-local` was removed during teardown and recreated during bootstrap.
- Helm releases `authentik` and `gravitee` are newly deployed and Ready.
- SQL Server is Ready and `sqlserver-bootstrap` completed.
- All 22 ASP.NET Core deployments are Ready.
- All 22 local `acme-erp/*` images were rebuilt after deletion.
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
helm list -n erp-local
docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | Select-String '^acme-erp/'
```

It is acceptable for some commands to report that `erp-local` or the releases do not exist; teardown must remain idempotent.

## Phase 2: Full Runtime Teardown

Stop or close any port-forward, watcher, or long-running Skaffold process before deleting resources. Then uninstall Helm releases first so Helm release metadata is cleaned up cleanly.

```powershell
helm uninstall gravitee -n erp-local
helm uninstall authentik -n erp-local
```

If either release does not exist, record that and continue.

Delete Skaffold-managed Kubernetes resources. This is useful when the namespace still exists and gives clearer errors than deleting the namespace first.

```powershell
skaffold delete -f build/skaffold.yaml -p apps
skaffold delete -f build/skaffold.yaml -p platform
```

If `skaffold delete` reports missing resources, record that and continue.

Delete the namespace and wait for it to terminate:

```powershell
kubectl delete namespace erp-local --wait=true --timeout=300s
```

If the namespace is stuck terminating, inspect finalizers instead of force-deleting immediately:

```powershell
kubectl get namespace erp-local -o yaml
kubectl get pvc,pv -A
```

Only use force/finalizer cleanup if the namespace is demonstrably stuck and the user has approved that escalation.

## Phase 3: Delete Local Images and Generated State

Delete only the ERP images managed by this repo.

```powershell
$erpImages = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -like 'acme-erp/*' }
if ($erpImages) {
    docker rmi -f $erpImages
}
```

Verify they are gone:

```powershell
docker images --format "{{.Repository}}:{{.Tag}}" | Select-String '^acme-erp/'
```

The verification should produce no rows.

Remove generated local state so the rebuild proves first-run bootstrap behavior. This deletes generated secrets and Helm generated values, not source files.

```powershell
Remove-Item -Recurse -Force build/.local -ErrorAction SilentlyContinue
```

Do not run broad Docker cleanup such as `docker system prune -a --volumes` unless explicitly approved. It can remove unrelated images, caches, and volumes from the developer machine.

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
.\build\scripts\bootstrap-local.ps1 -Profile platform
```

Wait and verify platform readiness before building apps:

```powershell
kubectl get namespace erp-local
kubectl rollout status statefulset/sqlserver -n erp-local --timeout=600s
kubectl wait --for=condition=complete job/sqlserver-bootstrap -n erp-local --timeout=600s
kubectl rollout status deployment/authentik-server -n erp-local --timeout=600s
kubectl rollout status deployment/authentik-worker -n erp-local --timeout=600s
kubectl rollout status statefulset/authentik-postgresql -n erp-local --timeout=600s
kubectl rollout status deployment/gravitee-apim-api -n erp-local --timeout=600s
kubectl rollout status deployment/gravitee-apim-gateway -n erp-local --timeout=600s
kubectl rollout status deployment/gravitee-apim-portal -n erp-local --timeout=600s
kubectl rollout status deployment/gravitee-apim-ui -n erp-local --timeout=600s
kubectl rollout status statefulset/graviteeio-apim-elasticsearch-master -n erp-local --timeout=600s
kubectl rollout status statefulset/graviteeio-apim-elasticsearch-data -n erp-local --timeout=600s
kubectl rollout status statefulset/graviteeio-apim-elasticsearch-ingest -n erp-local --timeout=600s
kubectl rollout status statefulset/graviteeio-apim-elasticsearch-coordinating -n erp-local --timeout=600s
kubectl rollout status statefulset/graviteeio-apim-mongodb-replicaset -n erp-local --timeout=600s
```

Then build and deploy the app layer from scratch:

```powershell
.\build\scripts\bootstrap-local.ps1 -Profile apps
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
helm list -n erp-local
kubectl get pods -n erp-local
kubectl get deployments,statefulsets -n erp-local
kubectl get jobs -n erp-local
```

Expected high-level results:

- `authentik` release: `deployed`
- `gravitee` release: `deployed`
- `sqlserver-bootstrap`: `Complete 1/1`
- all app deployments: `1/1`
- all Authentik deployments/StatefulSets: `1/1`
- all Gravitee deployments/StatefulSets: `1/1`

## Phase 6: Failure Triage Guide

If Helm release installation fails:

```powershell
helm list -n erp-local
helm status authentik -n erp-local
helm status gravitee -n erp-local
kubectl get events -n erp-local --sort-by=.lastTimestamp
```

If pods are not Ready:

```powershell
kubectl get pods -n erp-local -o wide
kubectl describe pod -n erp-local <pod-name>
kubectl logs -n erp-local <pod-name> --tail=200
```

Known local chart sensitivities:

- Gravitee Elasticsearch must use one replica per role and zero index replicas for the single-node cluster.
- Gravitee Elasticsearch must disable the unavailable Bitnami `os-shell` sysctl init image.
- Gravitee MongoDB must use the `mongodb.enabled` dependency key, not only the `mongo` repository configuration key.
- Gravitee MongoDB is tuned locally to one replica, no arbiter, and relaxed security contexts for the legacy Bitnami image.

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

- Teardown actions completed, including namespace deletion and image deletion.
- Whether `build/.local` was removed and regenerated.
- Build command results: `dotnet build`, `skaffold diagnose`, and app image rebuild.
- Helm release versions deployed.
- Final Kubernetes readiness snapshot.
- `validate-local.ps1` result.
- Any residual risks, especially if Gravitee route publication through the Management API remains unimplemented.