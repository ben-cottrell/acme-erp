[CmdletBinding()]
param(
    [string]$Namespace = 'erp-local'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptRoot '../..')

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments = @()
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FilePath $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Invoke-ClusterHttpCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Namespace,

        [Parameter(Mandatory = $true)]
        [string]$PodName,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [int[]]$ExpectedStatusCodes = @(200)
    )

    Write-Host "Checking $Url"
    $arguments = @(
        'exec',
        '--namespace', $Namespace,
        $PodName,
        '--',
        'curl', '-s', '--max-time', '15', '-o', '/dev/null', '-w', 'HTTP_STATUS:%{http_code}', $Url
    )

    $output = & kubectl @arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl $($arguments -join ' ') failed with exit code $LASTEXITCODE`n$($output | Out-String)"
    }

    $statusMatch = [regex]::Match(($output | Out-String), 'HTTP_STATUS:(\d{3})')
    if (-not $statusMatch.Success) {
        throw "No HTTP status found while checking $Url. Output:`n$($output | Out-String)"
    }

    $actualStatusCode = [int]$statusMatch.Groups[1].Value
    if ($ExpectedStatusCodes -notcontains $actualStatusCode) {
        throw "$Url returned HTTP $actualStatusCode; expected one of: $($ExpectedStatusCodes -join ', ')"
    }
}

function Remove-ValidationPod {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Namespace,

        [Parameter(Mandatory = $true)]
        [string]$PodName
    )

    & kubectl delete pod $PodName --namespace $Namespace --ignore-not-found --wait=false | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to request deletion for validation pod $PodName. Attempting force delete."
    }

    & kubectl wait --for=delete pod/$PodName --namespace $Namespace --timeout=30s | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    Write-Warning "Validation pod $PodName did not terminate within 30 seconds. Forcing deletion."
    & kubectl delete pod $PodName --namespace $Namespace --ignore-not-found --force --grace-period=0 --wait=false | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to force delete validation pod $PodName. Manual cleanup may be required."
    }
}

Push-Location $RepoRoot
try {
    Invoke-NativeCommand dotnet sln Acme.Erp.slnx list
    Invoke-NativeCommand dotnet build Acme.Erp.slnx

    Invoke-NativeCommand kubectl get namespace $Namespace
    Invoke-NativeCommand kubectl get secret erp-sqlserver --namespace $Namespace
    Invoke-NativeCommand kubectl get secret erp-sqlserver-connection-strings --namespace $Namespace
    Invoke-NativeCommand kubectl rollout status statefulset/sqlserver --namespace $Namespace --timeout=120s
    Invoke-NativeCommand kubectl wait --for=condition=complete job/sqlserver-bootstrap --namespace $Namespace --timeout=120s
    Invoke-NativeCommand kubectl get configmap gravitee-acme-erp-routes --namespace $Namespace

    Invoke-NativeCommand helm list --namespace $Namespace

    Invoke-NativeCommand kubectl rollout status deployment/authentik-server --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/authentik-worker --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status statefulset/authentik-postgresql --namespace $Namespace --timeout=300s

    Invoke-NativeCommand kubectl rollout status deployment/gravitee-apim-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/gravitee-apim-gateway --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/gravitee-apim-portal --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/gravitee-apim-ui --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status statefulset/graviteeio-apim-elasticsearch-master --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status statefulset/graviteeio-apim-elasticsearch-data --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status statefulset/graviteeio-apim-elasticsearch-ingest --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status statefulset/graviteeio-apim-elasticsearch-coordinating --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status statefulset/graviteeio-apim-mongodb-replicaset --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/sales-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/purchasing-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/inventory-management-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/order-fulfilment-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/sales-assistant-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/sales-assistant-ui --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/customer-ordering-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/customer-ordering-ui --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/buyer-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/buyer-ui --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/warehouse-operator-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/warehouse-operator-ui --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/fulfilment-operator-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/fulfilment-operator-ui --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/inventory-supervisor-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/inventory-supervisor-ui --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/fulfilment-supervisor-api --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/fulfilment-supervisor-ui --namespace $Namespace --timeout=300s

    $clusterChecks = @(
        @{ Url = 'http://sales-api/healthz'; Status = 200 },
        @{ Url = 'http://sales-api/readyz'; Status = 200 },
        @{ Url = 'http://sales-api/domain/sales/api'; Status = 200 },
        @{ Url = 'http://sales-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://purchasing-api/healthz'; Status = 200 },
        @{ Url = 'http://purchasing-api/readyz'; Status = 200 },
        @{ Url = 'http://purchasing-api/domain/purchasing/api'; Status = 200 },
        @{ Url = 'http://purchasing-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://inventory-management-api/healthz'; Status = 200 },
        @{ Url = 'http://inventory-management-api/readyz'; Status = 200 },
        @{ Url = 'http://inventory-management-api/domain/inventory/api'; Status = 200 },
        @{ Url = 'http://inventory-management-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://order-fulfilment-api/healthz'; Status = 200 },
        @{ Url = 'http://order-fulfilment-api/readyz'; Status = 200 },
        @{ Url = 'http://order-fulfilment-api/domain/fulfilment/api'; Status = 200 },
        @{ Url = 'http://order-fulfilment-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://sales-assistant-api/healthz'; Status = 200 },
        @{ Url = 'http://sales-assistant-api/readyz'; Status = 200 },
        @{ Url = 'http://sales-assistant-api/apps/sales-assistant/api'; Status = 200 },
        @{ Url = 'http://sales-assistant-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://sales-assistant-ui/healthz'; Status = 200 },
        @{ Url = 'http://sales-assistant-ui/readyz'; Status = 200 },
        @{ Url = 'http://sales-assistant-ui/apps/sales-assistant/ui'; Status = 200 },
        @{ Url = 'http://customer-ordering-api/healthz'; Status = 200 },
        @{ Url = 'http://customer-ordering-api/readyz'; Status = 200 },
        @{ Url = 'http://customer-ordering-api/apps/customer-ordering/api'; Status = 200 },
        @{ Url = 'http://customer-ordering-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://customer-ordering-ui/healthz'; Status = 200 },
        @{ Url = 'http://customer-ordering-ui/readyz'; Status = 200 },
        @{ Url = 'http://customer-ordering-ui/apps/customer-ordering/ui'; Status = 200 },
        @{ Url = 'http://buyer-api/healthz'; Status = 200 },
        @{ Url = 'http://buyer-api/readyz'; Status = 200 },
        @{ Url = 'http://buyer-api/apps/buyer/api'; Status = 200 },
        @{ Url = 'http://buyer-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://buyer-ui/healthz'; Status = 200 },
        @{ Url = 'http://buyer-ui/readyz'; Status = 200 },
        @{ Url = 'http://buyer-ui/apps/buyer/ui'; Status = 200 },
        @{ Url = 'http://warehouse-operator-api/healthz'; Status = 200 },
        @{ Url = 'http://warehouse-operator-api/readyz'; Status = 200 },
        @{ Url = 'http://warehouse-operator-api/apps/warehouse-operator/api'; Status = 200 },
        @{ Url = 'http://warehouse-operator-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://warehouse-operator-ui/healthz'; Status = 200 },
        @{ Url = 'http://warehouse-operator-ui/readyz'; Status = 200 },
        @{ Url = 'http://warehouse-operator-ui/apps/warehouse-operator/ui'; Status = 200 },
        @{ Url = 'http://fulfilment-operator-api/healthz'; Status = 200 },
        @{ Url = 'http://fulfilment-operator-api/readyz'; Status = 200 },
        @{ Url = 'http://fulfilment-operator-api/apps/fulfilment-operator/api'; Status = 200 },
        @{ Url = 'http://fulfilment-operator-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://fulfilment-operator-ui/healthz'; Status = 200 },
        @{ Url = 'http://fulfilment-operator-ui/readyz'; Status = 200 },
        @{ Url = 'http://fulfilment-operator-ui/apps/fulfilment-operator/ui'; Status = 200 },
        @{ Url = 'http://inventory-supervisor-api/healthz'; Status = 200 },
        @{ Url = 'http://inventory-supervisor-api/readyz'; Status = 200 },
        @{ Url = 'http://inventory-supervisor-api/apps/inventory-supervisor/api'; Status = 200 },
        @{ Url = 'http://inventory-supervisor-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://inventory-supervisor-ui/healthz'; Status = 200 },
        @{ Url = 'http://inventory-supervisor-ui/readyz'; Status = 200 },
        @{ Url = 'http://inventory-supervisor-ui/apps/inventory-supervisor/ui'; Status = 200 },
        @{ Url = 'http://fulfilment-supervisor-api/healthz'; Status = 200 },
        @{ Url = 'http://fulfilment-supervisor-api/readyz'; Status = 200 },
        @{ Url = 'http://fulfilment-supervisor-api/apps/fulfilment-supervisor/api'; Status = 200 },
        @{ Url = 'http://fulfilment-supervisor-api/openapi/v1.json'; Status = 200 },
        @{ Url = 'http://fulfilment-supervisor-ui/healthz'; Status = 200 },
        @{ Url = 'http://fulfilment-supervisor-ui/readyz'; Status = 200 },
        @{ Url = 'http://fulfilment-supervisor-ui/apps/fulfilment-supervisor/ui'; Status = 200 },
        @{ Url = 'http://authentik-server/-/health/live/'; Status = 200 },
        @{ Url = 'http://gravitee-apim-api:83/management/organizations/DEFAULT/environments/DEFAULT/'; Status = 401 },
        @{ Url = 'http://gravitee-apim-gateway:8082/'; Status = 404 }
    )

    $curlPod = "erp-validate-$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())-$(Get-Random -Maximum 99999)"
    try {
        Invoke-NativeCommand kubectl run $curlPod --restart=Never --image=curlimages/curl:8.11.1 --namespace $Namespace --command -- sleep 600
        Invoke-NativeCommand kubectl wait --for=condition=Ready pod/$curlPod --namespace $Namespace --timeout=120s

        foreach ($check in $clusterChecks) {
            Invoke-ClusterHttpCheck -Namespace $Namespace -PodName $curlPod -Url $check.Url -ExpectedStatusCodes @($check.Status)
        }
    }
    finally {
        Remove-ValidationPod -Namespace $Namespace -PodName $curlPod
    }
}
finally {
    Pop-Location
}