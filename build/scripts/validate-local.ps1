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

        $clusterChecks = @(
            @{ Url = 'http://sales-api/healthz'; Status = 200 },
            @{ Url = 'http://sales-api/readyz'; Status = 200 },
            @{ Url = 'http://sales-api/sales/api'; Status = 200 },
            @{ Url = 'http://sales-ui/healthz'; Status = 200 },
            @{ Url = 'http://sales-ui/readyz'; Status = 200 },
            @{ Url = 'http://sales-ui/sales/ui'; Status = 200 },
            @{ Url = 'http://purchasing-api/healthz'; Status = 200 },
            @{ Url = 'http://purchasing-api/readyz'; Status = 200 },
            @{ Url = 'http://purchasing-api/purchasing/api'; Status = 200 },
            @{ Url = 'http://purchasing-ui/healthz'; Status = 200 },
            @{ Url = 'http://purchasing-ui/readyz'; Status = 200 },
            @{ Url = 'http://purchasing-ui/purchasing/ui'; Status = 200 },
            @{ Url = 'http://inventory-management-api/healthz'; Status = 200 },
            @{ Url = 'http://inventory-management-api/readyz'; Status = 200 },
            @{ Url = 'http://inventory-management-api/inventory/api'; Status = 200 },
            @{ Url = 'http://inventory-management-ui/healthz'; Status = 200 },
            @{ Url = 'http://inventory-management-ui/readyz'; Status = 200 },
            @{ Url = 'http://inventory-management-ui/inventory/ui'; Status = 200 },
            @{ Url = 'http://order-fulfilment-api/healthz'; Status = 200 },
            @{ Url = 'http://order-fulfilment-api/readyz'; Status = 200 },
            @{ Url = 'http://order-fulfilment-api/fulfilment/api'; Status = 200 },
            @{ Url = 'http://order-fulfilment-ui/healthz'; Status = 200 },
            @{ Url = 'http://order-fulfilment-ui/readyz'; Status = 200 },
            @{ Url = 'http://order-fulfilment-ui/fulfilment/ui'; Status = 200 },
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
            & kubectl delete pod $curlPod --namespace $Namespace --ignore-not-found | Out-Null
        }
}
finally {
    Pop-Location
}
