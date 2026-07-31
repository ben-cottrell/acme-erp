[CmdletBinding()]
param(
    [ValidateSet('namespace', 'sqlserver', 'identity', 'gateway', 'routes', 'platform', 'apps', 'all')]
    [string]$DeploymentScope = 'all',

    [ValidateSet('PortForward', 'LoadBalancer', 'None')]
    [string]$GatewayExposure = 'PortForward',

    [string]$GatewayHost = 'localhost',

    [int]$GatewayPort = 8082,

    [switch]$SkipDeploy,
    [switch]$SkipSecrets,
    [switch]$RotateSecrets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildRoot = Resolve-Path (Join-Path $ScriptRoot '..')
$RepoRoot = Resolve-Path (Join-Path $BuildRoot '..')
$Namespace = 'erp-local'
$LocalStatePath = Join-Path $BuildRoot '.local'
$LocalSecretValuesPath = Join-Path $BuildRoot 'k8s/local-secrets/local-secret-values.json'
$GatewayPortForwardOutputPath = Join-Path $LocalStatePath 'gravitee-port-forward.out.log'
$GatewayPortForwardErrorPath = Join-Path $LocalStatePath 'gravitee-port-forward.err.log'

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FilePath $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Test-RequiredCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$InstallHint
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing prerequisite '$Name'. $InstallHint"
    }
}

function Read-LocalSecretConfiguration {
    if (-not (Test-Path $LocalSecretValuesPath)) {
        throw "Local secret configuration '$LocalSecretValuesPath' does not exist."
    }

    $json = Get-Content -Raw -Path $LocalSecretValuesPath
    if ([string]::IsNullOrWhiteSpace($json)) {
        throw "Local secret configuration '$LocalSecretValuesPath' is empty."
    }

    return $json | ConvertFrom-Json
}

function ConvertTo-QuotedYamlValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'$($Value.Replace("'", "''"))'"
}

function New-SecretValue {
    param([int]$Length = 36)

    $characters = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!#$%*+-=?'
    $bytes = New-Object byte[] $Length
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $generator.GetBytes($bytes)
    }
    finally {
        $generator.Dispose()
    }

    $builder = New-Object System.Text.StringBuilder
    foreach ($byte in $bytes) {
        [void]$builder.Append($characters[$byte % $characters.Length])
    }

    return $builder.ToString()
}

function Set-SecretValue {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [int]$Length = 36
    )

    if ($RotateSecrets -or -not $State.ContainsKey($Name)) {
        $State[$Name] = New-SecretValue -Length $Length
    }
}

function Expand-LocalSecretTemplate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Template,

        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    return [regex]::Replace($Template, '\{([^{}]+)\}', {
        param($match)

        $name = $match.Groups[1].Value
        if (-not $State.ContainsKey($name)) {
            throw "Local secret template references missing state value '$name'."
        }

        return $State[$name]
    })
}

function Get-LocalSecretStateBindings {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Configuration
    )

    $bindings = @()
    foreach ($stateValue in @($Configuration.stateValues)) {
        $sourcesProperty = $stateValue.PSObject.Properties['sources']
        if ($null -eq $sourcesProperty) {
            continue
        }

        foreach ($source in @($sourcesProperty.Value)) {
            $bindings += [pscustomobject]@{
                StateName = [string]$stateValue.name
                SecretName = [string]$source.secret
                Key = [string]$source.key
            }
        }
    }

    foreach ($secret in @($Configuration.kubernetesSecrets)) {
        foreach ($property in $secret.stringData.PSObject.Properties) {
            $template = [string]$property.Value
            if ($template -match '^\{([^{}]+)\}$') {
                $bindings += [pscustomobject]@{
                    StateName = $Matches[1]
                    SecretName = [string]$secret.name
                    Key = [string]$property.Name
                }
            }
        }
    }

    return $bindings
}

function Read-KubernetesSecretStringValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SecretName,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $json = & kubectl get secret $SecretName --namespace $Namespace --ignore-not-found -o json
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($json)) {
        return $null
    }

    $secret = $json | ConvertFrom-Json
    $property = $secret.data.PSObject.Properties[$Key]
    if ($null -eq $property -or [string]::IsNullOrWhiteSpace($property.Value)) {
        return $null
    }

    $bytes = [Convert]::FromBase64String([string]$property.Value)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Read-KubernetesSecretState {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Configuration
    )

    $state = @{}
    foreach ($binding in Get-LocalSecretStateBindings -Configuration $Configuration) {
        if ($state.ContainsKey($binding.StateName)) {
            continue
        }

        $value = Read-KubernetesSecretStringValue -SecretName $binding.SecretName -Key $binding.Key
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $state[$binding.StateName] = $value
        }
    }

    return $state
}

function New-LocalKubernetesSecretManifest {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    $items = @()
    foreach ($secret in @($Configuration.kubernetesSecrets)) {
        $typeProperty = $secret.PSObject.Properties['type']
        $secretType = if ($null -ne $typeProperty -and -not [string]::IsNullOrWhiteSpace($typeProperty.Value)) { [string]$typeProperty.Value } else { 'Opaque' }
        $stringData = [ordered]@{}
        foreach ($property in $secret.stringData.PSObject.Properties) {
            $stringData[$property.Name] = Expand-LocalSecretTemplate -Template ([string]$property.Value) -State $State
        }

        $items += [ordered]@{
            apiVersion = 'v1'
            kind = 'Secret'
            metadata = [ordered]@{
                name = [string]$secret.name
                namespace = $Namespace
                labels = [ordered]@{
                    'app.kubernetes.io/part-of' = 'acme-erp'
                    'app.kubernetes.io/managed-by' = 'acme-erp-local-bootstrap'
                }
            }
            type = $secretType
            stringData = $stringData
        }
    }

    [ordered]@{
        apiVersion = 'v1'
        kind = 'List'
        items = $items
    } | ConvertTo-Json -Depth 20
}

function Invoke-KubectlApplyManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Manifest
    )

    $Manifest | kubectl apply -f -
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl apply -f - failed with exit code $LASTEXITCODE"
    }
}

function Test-DockerDesktopContext {
    $context = & kubectl config current-context
    if ($LASTEXITCODE -ne 0) {
        throw 'kubectl has no current context. Enable Docker Desktop Kubernetes, then retry.'
    }

    if ($context -ne 'docker-desktop') {
        throw "kubectl current context is '$context'. Switch to 'docker-desktop' for this local single-node stack."
    }
}

function Initialize-Namespace {
    Invoke-NativeCommand kubectl apply -f (Join-Path $BuildRoot 'k8s/namespaces/erp-local.yaml')
    Invoke-NativeCommand kubectl wait '--for=jsonpath={.status.phase}=Active' "namespace/$Namespace" '--timeout=60s'
    Invoke-NativeCommand kubectl get namespace $Namespace
}

function Initialize-LocalSecrets {
    $configuration = Read-LocalSecretConfiguration
    $state = Read-KubernetesSecretState -Configuration $configuration

    foreach ($stateValue in @($configuration.stateValues)) {
        $length = if ($null -ne $stateValue.length) { [int]$stateValue.length } else { 36 }
        Set-SecretValue -State $state -Name $stateValue.name -Length $length
    }

    $manifest = New-LocalKubernetesSecretManifest -Configuration $configuration -State $state
    Invoke-KubectlApplyManifest -Manifest $manifest

    Write-Host "Local Kubernetes secrets reconciled from $LocalSecretValuesPath"
}

function Write-AuthentikGeneratedValues {
    $configuration = Read-LocalSecretConfiguration
    $state = Read-KubernetesSecretState -Configuration $configuration
    $requiredSecretNames = @(
        'authentik-secret-key',
        'authentik-postgresql-password',
        'authentik-bootstrap-password'
    )

    foreach ($secretName in $requiredSecretNames) {
        if (-not $state.ContainsKey($secretName) -or [string]::IsNullOrWhiteSpace($state[$secretName])) {
            throw "Missing local secret state '$secretName'. Run bootstrap without -SkipSecrets to create the cluster-backed local secrets."
        }
    }

    if (-not (Test-Path $LocalStatePath)) {
        New-Item -ItemType Directory -Path $LocalStatePath | Out-Null
    }

    $generatedValuesPath = Join-Path $LocalStatePath 'authentik.generated-values.yaml'
    @"
authentik:
    secret_key: $(ConvertTo-QuotedYamlValue -Value $state['authentik-secret-key'])
    postgresql:
        password: $(ConvertTo-QuotedYamlValue -Value $state['authentik-postgresql-password'])
    bootstrap_password: $(ConvertTo-QuotedYamlValue -Value $state['authentik-bootstrap-password'])
    bootstrap_email: 'admin@localhost.localdomain'
postgresql:
    auth:
        password: $(ConvertTo-QuotedYamlValue -Value $state['authentik-postgresql-password'])
"@ | Set-Content -Path $generatedValuesPath -Encoding UTF8

    Write-Host "Authentik generated Helm values written to $generatedValuesPath"
}

function Wait-ForPlatform {
    Invoke-NativeCommand kubectl rollout status statefulset/sqlserver --namespace $Namespace --timeout=600s
    Invoke-NativeCommand kubectl wait --for=condition=complete job/sqlserver-bootstrap --namespace $Namespace --timeout=600s
}

function Wait-ForIdentity {
    Invoke-NativeCommand kubectl rollout status deployment/authentik-server --namespace $Namespace --timeout=600s
    Invoke-NativeCommand kubectl rollout status deployment/authentik-worker --namespace $Namespace --timeout=600s
    Invoke-NativeCommand kubectl rollout status statefulset/authentik-postgresql --namespace $Namespace --timeout=600s
}

function Wait-ForGateway {
    Invoke-NativeCommand kubectl rollout status deployment/gravitee-apim-gateway --namespace $Namespace --timeout=600s
}

function Wait-ForGatewayLoadBalancer {
    $deadline = [DateTimeOffset]::UtcNow.AddSeconds(120)
    do {
        $endpoint = & kubectl get service gravitee-apim-gateway --namespace $Namespace '-o=jsonpath={.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}' 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($endpoint)) {
            Write-Host "Gravitee gateway LoadBalancer endpoint: $endpoint"
            return
        }

        Start-Sleep -Seconds 2
    } while ([DateTimeOffset]::UtcNow -lt $deadline)

    throw "Gravitee gateway LoadBalancer did not receive an endpoint within 120 seconds. Re-run bootstrap with -GatewayExposure PortForward for the most reliable local exposure path."
}

function Test-GatewayHttpEndpoint {
    $url = "http://${GatewayHost}:$GatewayPort/"
    $request = [System.Net.HttpWebRequest]::Create($url)
    $request.Method = 'GET'
    $request.Timeout = 2000
    $request.ReadWriteTimeout = 2000
    $request.AllowAutoRedirect = $false
    $request.UserAgent = 'acme-erp-local-bootstrap'

    try {
        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        $response.Close()
        return $true
    }
    catch [System.Net.WebException] {
        if ($null -ne $_.Exception.Response -and $_.Exception.Response -is [System.Net.HttpWebResponse]) {
            $_.Exception.Response.Close()
            return $true
        }

        return $false
    }
}

function Stop-GatewayPortForwardProcesses {
    $processes = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -in @('kubectl.exe', 'kubectl') -and
        $_.CommandLine -match '(?i)(^|\s)port-forward(\s|$)' -and
        ($_.CommandLine -match 'gravitee-apim-gateway' -or $_.CommandLine -match "${GatewayPort}:8082")
    })

    foreach ($process in $processes) {
        Write-Host "Stopping stale Gravitee gateway port-forward process $($process.ProcessId)."
        Stop-Process -Id $process.ProcessId -Force
        try {
            Wait-Process -Id $process.ProcessId -Timeout 10 -ErrorAction Stop
        }
        catch [System.TimeoutException] {
            throw "Port-forward process $($process.ProcessId) did not stop within 10 seconds."
        }
        catch [System.ArgumentException] {
            # The process exited before Wait-Process observed it.
        }
    }
}

function Start-GatewayPortForward {
    Stop-GatewayPortForwardProcesses

    if (-not (Test-Path $LocalStatePath)) {
        New-Item -ItemType Directory -Path $LocalStatePath | Out-Null
    }

    $arguments = @('port-forward', '--namespace', $Namespace, 'svc/gravitee-apim-gateway', "${GatewayPort}:8082")
    $process = Start-Process -FilePath kubectl -ArgumentList $arguments -RedirectStandardOutput $GatewayPortForwardOutputPath -RedirectStandardError $GatewayPortForwardErrorPath -WindowStyle Hidden -PassThru
    Write-Host "Started Gravitee gateway port-forward process $($process.Id): http://${GatewayHost}:$GatewayPort"

    $deadline = [DateTimeOffset]::UtcNow.AddSeconds(30)
    do {
        if ($process.HasExited) {
            $errorText = if (Test-Path $GatewayPortForwardErrorPath) { Get-Content -Raw -Path $GatewayPortForwardErrorPath } else { '' }
            throw "Gravitee gateway port-forward exited before becoming reachable. See $GatewayPortForwardErrorPath. $errorText"
        }

        if (Test-GatewayHttpEndpoint) {
            return
        }

        Start-Sleep -Milliseconds 500
    } while ([DateTimeOffset]::UtcNow -lt $deadline)

    throw "Gravitee gateway port-forward did not become reachable at ${GatewayHost}:$GatewayPort within 30 seconds. See $GatewayPortForwardOutputPath and $GatewayPortForwardErrorPath."
}

function Initialize-GatewayExposure {
    if ($GatewayExposure -eq 'PortForward') {
        Start-GatewayPortForward
    }
    elseif ($GatewayExposure -eq 'LoadBalancer') {
        Wait-ForGatewayLoadBalancer
    }
}

function Get-GatewaySkaffoldProfile {
    if ($GatewayExposure -eq 'LoadBalancer') {
        return 'gateway-loadbalancer'
    }

    return 'gateway'
}

function Clear-StuckGatewayServiceDeletion {
    $deletionTimestamp = & kubectl get service gravitee-apim-gateway --namespace $Namespace '-o=jsonpath={.metadata.deletionTimestamp}' 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($deletionTimestamp)) {
        return
    }

    Write-Warning "Gravitee gateway service is stuck deleting. Removing its load-balancer cleanup finalizer before reapplying gateway configuration."
    if (-not (Test-Path $LocalStatePath)) {
        New-Item -ItemType Directory -Path $LocalStatePath | Out-Null
    }

    $patchPath = Join-Path $LocalStatePath 'gravitee-service-finalizer-patch.json'
    '{"metadata":{"finalizers":[]}}' | Set-Content -Path $patchPath -Encoding UTF8
    Invoke-NativeCommand kubectl patch service gravitee-apim-gateway --namespace $Namespace --type=merge --patch-file $patchPath
    Invoke-NativeCommand kubectl wait --for=delete service/gravitee-apim-gateway --namespace $Namespace --timeout=60s
}

function Invoke-SkaffoldProfile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('namespace', 'sqlserver', 'identity', 'gateway', 'gateway-loadbalancer', 'routes', 'platform', 'apps')]
        [string]$SkaffoldProfile
    )

    $arguments = @('run', '-f', (Join-Path $BuildRoot 'skaffold.yaml'), '-p', $SkaffoldProfile)
    Invoke-NativeCommand -FilePath skaffold -Arguments $arguments
}

function Invoke-PlatformDeployment {
    Invoke-SkaffoldProfile -SkaffoldProfile 'sqlserver'
    Wait-ForPlatform
    Invoke-SkaffoldProfile -SkaffoldProfile 'identity'
    Wait-ForIdentity
    Invoke-SkaffoldProfile -SkaffoldProfile 'routes'
    Clear-StuckGatewayServiceDeletion
    Invoke-SkaffoldProfile -SkaffoldProfile (Get-GatewaySkaffoldProfile)
    Wait-ForGateway
    Initialize-GatewayExposure
}

Test-RequiredCommand dotnet 'Install the .NET 10 SDK.'
Test-RequiredCommand docker 'Install Docker Desktop.'
Test-RequiredCommand kubectl 'Install kubectl or enable the Docker Desktop Kubernetes CLI integration.'
if (-not $SkipDeploy) {
    Test-RequiredCommand skaffold 'Install Skaffold from https://skaffold.dev/docs/install/.'
}
if (($DeploymentScope -in @('identity', 'gateway', 'platform', 'all')) -and -not $SkipDeploy) {
    Test-RequiredCommand helm 'Install Helm from https://helm.sh/docs/intro/install/. Skaffold uses Helm to render local platform charts.'
}

Push-Location $RepoRoot
try {
    Test-DockerDesktopContext
    Initialize-Namespace

    if (-not $SkipSecrets) {
        Initialize-LocalSecrets
    }

    if ($DeploymentScope -in @('identity', 'platform', 'all')) {
        Write-AuthentikGeneratedValues
    }

    if (-not $SkipDeploy) {
        switch ($DeploymentScope) {
            'namespace' {
                Invoke-SkaffoldProfile -SkaffoldProfile 'namespace'
            }
            'sqlserver' {
                Invoke-SkaffoldProfile -SkaffoldProfile 'sqlserver'
                Wait-ForPlatform
            }
            'identity' {
                Invoke-SkaffoldProfile -SkaffoldProfile 'identity'
                Wait-ForIdentity
            }
            'gateway' {
                Clear-StuckGatewayServiceDeletion
                Invoke-SkaffoldProfile -SkaffoldProfile (Get-GatewaySkaffoldProfile)
                Wait-ForGateway
                Initialize-GatewayExposure
            }
            'routes' {
                Invoke-SkaffoldProfile -SkaffoldProfile 'routes'
            }
            'platform' {
                Invoke-PlatformDeployment
            }
            'apps' {
                Invoke-SkaffoldProfile -SkaffoldProfile 'apps'
            }
            'all' {
                Invoke-PlatformDeployment
                Invoke-SkaffoldProfile -SkaffoldProfile 'apps'
            }
        }
    }
}
finally {
    Pop-Location
}
