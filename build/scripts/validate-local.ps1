[CmdletBinding()]
param(
    [string]$Namespace = 'erp-local',

    [switch]$IncludeExternalUi,

    [string]$GatewayHost = 'localhost',

    [ValidateSet('http', 'https')]
    [string]$Scheme = 'http',

    [int]$GatewayPort = 8082
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
        [string]$Url,

        [int[]]$ExpectedStatusCodes = @(200)
    )

    Write-Host "Checking $Url"
    $proxyPath = Convert-ToKubernetesServiceProxyPath -Namespace $Namespace -Url $Url
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & kubectl get --raw $proxyPath 2>&1
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $actualStatusCode = Get-KubectlRawHttpStatus -ExitCode $LASTEXITCODE -Output ($output | Out-String)
    if ($ExpectedStatusCodes -notcontains $actualStatusCode) {
        throw "$Url returned HTTP $actualStatusCode; expected one of: $($ExpectedStatusCodes -join ', ')"
    }
}

function Convert-ToKubernetesServiceProxyPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Namespace,

        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    $uri = [Uri]$Url
    if ($uri.Scheme -ne 'http') {
        throw "Cluster HTTP checks support only http service URLs. Got: $Url"
    }

    $port = if ($uri.IsDefaultPort) { 80 } else { $uri.Port }
    $pathAndQuery = $uri.PathAndQuery
    if ([string]::IsNullOrWhiteSpace($pathAndQuery)) {
        $pathAndQuery = '/'
    }

    return ('/api/v1/namespaces/{0}/services/http:{1}:{2}/proxy{3}' -f $Namespace, $uri.Host, $port, $pathAndQuery)
}

function Get-KubectlRawHttpStatus {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ExitCode,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Output
    )

    if ($ExitCode -eq 0) {
        return 200
    }

    $statusMatch = [regex]::Match($Output, '\b([1-5]\d{2})\b')
    if ($statusMatch.Success) {
        return [int]$statusMatch.Groups[1].Value
    }

    if ($Output -match 'Unauthorized|provide credentials|logged in') {
        return 401
    }

    if ($Output -match 'NotFound|Not Found|not found') {
        return 404
    }

    throw "kubectl get --raw failed with exit code $ExitCode and no HTTP status could be inferred. Output:`n$Output"
}

function Get-ExternalUiChecks {
    @(
        @{ Name = 'Sales Assistant UI'; Path = '/apps/sales-assistant/ui' },
        @{ Name = 'Customer Ordering UI'; Path = '/apps/customer-ordering/ui' },
        @{ Name = 'Buyer UI'; Path = '/apps/buyer/ui' },
        @{ Name = 'Warehouse Operator UI'; Path = '/apps/warehouse-operator/ui' },
        @{ Name = 'Fulfilment Operator UI'; Path = '/apps/fulfilment-operator/ui' },
        @{ Name = 'Inventory Supervisor UI'; Path = '/apps/inventory-supervisor/ui' },
        @{ Name = 'Fulfilment Supervisor UI'; Path = '/apps/fulfilment-supervisor/ui' }
    )
}

function New-ExternalUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Scheme,

        [Parameter(Mandatory = $true)]
        [string]$HostName,

        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalizedPath = $Path.TrimStart('/')
    return "${Scheme}://${HostName}:${Port}/$normalizedPath"
}

function Test-GatewayHostResolution {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName
    )

    try {
        $addresses = [System.Net.Dns]::GetHostAddresses($HostName)
    }
    catch {
        throw "Gateway host '$HostName' did not resolve. The default local gateway host is localhost; pass -GatewayHost with a resolvable host if using a non-default exposure. $($_.Exception.Message)"
    }

    if ($addresses.Count -eq 0) {
        throw "Gateway host '$HostName' did not resolve to any addresses. The default local gateway host is localhost; pass -GatewayHost with a resolvable host if using a non-default exposure."
    }

    Write-Host "Resolved $HostName to $($addresses -join ', ')"
}

function Invoke-ExternalHttpRequest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [int]$TimeoutSeconds = 15
    )

    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.Method = 'GET'
    $request.Timeout = $TimeoutSeconds * 1000
    $request.ReadWriteTimeout = $TimeoutSeconds * 1000
    $request.AllowAutoRedirect = $false
    $request.UserAgent = 'acme-erp-local-validator'

    try {
        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        try {
            return [pscustomobject]@{
                StatusCode = [int]$response.StatusCode
                Location = $response.Headers['Location']
                Error = $null
            }
        }
        finally {
            $response.Close()
        }
    }
    catch [System.Net.WebException] {
        $response = $_.Exception.Response
        if ($null -ne $response -and $response -is [System.Net.HttpWebResponse]) {
            try {
                return [pscustomobject]@{
                    StatusCode = [int]$response.StatusCode
                    Location = $response.Headers['Location']
                    Error = $null
                }
            }
            finally {
                $response.Close()
            }
        }

        return [pscustomobject]@{
            StatusCode = 0
            Location = $null
            Error = $_.Exception.Message
        }
    }
}

function Test-ReachableExternalUiStatus {
    param(
        [Parameter(Mandatory = $true)]
        [int]$StatusCode
    )

    return (($StatusCode -ge 200 -and $StatusCode -lt 400) -or $StatusCode -eq 401 -or $StatusCode -eq 403)
}

function Wait-ExternalGateway {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GatewayUrl,

        [int]$TimeoutSeconds = 30
    )

    $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    $lastError = $null
    do {
        $response = Invoke-ExternalHttpRequest -Url $GatewayUrl -TimeoutSeconds 5
        if ($response.StatusCode -gt 0) {
            Write-Host "Gateway endpoint $GatewayUrl responded with HTTP $($response.StatusCode)"
            return
        }

        $lastError = $response.Error
        Start-Sleep -Milliseconds 500
    } while ([DateTimeOffset]::UtcNow -lt $deadline)

    throw "Gateway endpoint $GatewayUrl was not reachable within $TimeoutSeconds seconds. The local Gravitee gateway service is configured as a Docker Desktop LoadBalancer on localhost:8082; confirm the gravitee-apim-gateway service has an external localhost endpoint and the platform deployment is ready. Last error: $lastError"
}

function Invoke-ExternalUiValidation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GatewayHost,

        [Parameter(Mandatory = $true)]
        [string]$Scheme,

        [Parameter(Mandatory = $true)]
        [int]$GatewayPort
    )

    Write-Host "Checking external UI routes through ${Scheme}://${GatewayHost}:${GatewayPort}"
    Test-GatewayHostResolution -HostName $GatewayHost

    $gatewayUrl = New-ExternalUrl -Scheme $Scheme -HostName $GatewayHost -Port $GatewayPort -Path '/'
    Wait-ExternalGateway -GatewayUrl $gatewayUrl

    $results = @()
    foreach ($check in Get-ExternalUiChecks) {
        $url = New-ExternalUrl -Scheme $Scheme -HostName $GatewayHost -Port $GatewayPort -Path $check.Path
        $response = Invoke-ExternalHttpRequest -Url $url
        $reachable = Test-ReachableExternalUiStatus -StatusCode $response.StatusCode
        $reason = if ($reachable) { 'reachable' } elseif ($response.StatusCode -gt 0) { "HTTP $($response.StatusCode)" } else { $response.Error }

        $results += [pscustomobject]@{
            Name = $check.Name
            Url = $url
            StatusCode = $response.StatusCode
            Reachable = $reachable
            Reason = $reason
        }
    }

    Write-Host "External UI route results:"
    foreach ($result in $results) {
        $status = if ($result.StatusCode -gt 0) { $result.StatusCode } else { 'ERR' }
        Write-Host ('  {0,-28} {1,4} {2}' -f $result.Name, $status, $result.Url)
        if (-not $result.Reachable) {
            Write-Host "    $($result.Reason)"
        }
    }

    $httpResults = @($results | Where-Object { $_.StatusCode -gt 0 })
    $notReachable = @($results | Where-Object { -not $_.Reachable })
    if ($httpResults.Count -eq $results.Count -and @($httpResults | Where-Object { $_.StatusCode -eq 404 }).Count -eq $results.Count) {
        throw "All external UI routes returned HTTP 404. Gravitee is reachable, but the application routes are likely not synchronized. Confirm the Gravitee db-less gateway is watching Kubernetes ConfigMaps labeled managed-by=gravitee.io and gio-type=apidefinitions.gravitee.io."
    }

    if ($notReachable.Count -gt 0) {
        throw "$($notReachable.Count) external UI route check(s) failed."
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
    Invoke-NativeCommand kubectl get configmap --namespace $Namespace --selector "managed-by=gravitee.io,gio-type=apidefinitions.gravitee.io"
    Invoke-NativeCommand kubectl get configmap gravitee-acme-erp-route-sales-api gravitee-acme-erp-route-fulfilment-supervisor-ui --namespace $Namespace

    Invoke-NativeCommand helm list --namespace $Namespace

    Invoke-NativeCommand kubectl rollout status deployment/authentik-server --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status deployment/authentik-worker --namespace $Namespace --timeout=300s
    Invoke-NativeCommand kubectl rollout status statefulset/authentik-postgresql --namespace $Namespace --timeout=300s

    Invoke-NativeCommand kubectl rollout status deployment/gravitee-apim-gateway --namespace $Namespace --timeout=300s
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
        @{ Url = 'http://gravitee-apim-gateway:8082/'; Status = 404 }
    )

    foreach ($check in $clusterChecks) {
        Invoke-ClusterHttpCheck -Namespace $Namespace -Url $check.Url -ExpectedStatusCodes @($check.Status)
    }

    if ($IncludeExternalUi) {
        Invoke-ExternalUiValidation -GatewayHost $GatewayHost -Scheme $Scheme -GatewayPort $GatewayPort
    }
}
finally {
    Pop-Location
}