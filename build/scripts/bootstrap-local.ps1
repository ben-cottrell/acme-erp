[CmdletBinding()]
param(
    [ValidateSet('platform', 'apps', 'all')]
    [string]$DeploymentScope = 'all',

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
$SecretsPath = Join-Path $LocalStatePath 'secrets.json'

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

function Read-SecretState {
    if (-not (Test-Path $SecretsPath)) {
        return @{}
    }

    $json = Get-Content -Raw -Path $SecretsPath
    if ([string]::IsNullOrWhiteSpace($json)) {
        return @{}
    }

    $state = @{}
    $object = $json | ConvertFrom-Json
    foreach ($property in $object.PSObject.Properties) {
        $state[$property.Name] = [string]$property.Value
    }

    return $state
}

function Write-SecretState {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    if (-not (Test-Path $LocalStatePath)) {
        New-Item -ItemType Directory -Path $LocalStatePath | Out-Null
    }

    $State | ConvertTo-Json | Set-Content -Path $SecretsPath -Encoding UTF8
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

function Set-KubernetesSecret {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [hashtable]$Values
    )

    $arguments = @('create', 'secret', 'generic', $Name, '--namespace', $Namespace, '--dry-run=client', '-o', 'yaml')
    foreach ($key in ($Values.Keys | Sort-Object)) {
        $arguments += "--from-literal=$key=$($Values[$key])"
    }

    $manifest = & kubectl @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl $($arguments -join ' ') failed with exit code $LASTEXITCODE"
    }

    $manifest | kubectl apply -f - | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl apply for secret '$Name' failed with exit code $LASTEXITCODE"
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
    $state = Read-SecretState

    Set-SecretValue -State $state -Name 'sql-sa-password' -Length 32
    Set-SecretValue -State $state -Name 'sales-db-password' -Length 32
    Set-SecretValue -State $state -Name 'purchasing-db-password' -Length 32
    Set-SecretValue -State $state -Name 'inventory-db-password' -Length 32
    Set-SecretValue -State $state -Name 'fulfilment-db-password' -Length 32
    Set-SecretValue -State $state -Name 'authentik-secret-key' -Length 64
    Set-SecretValue -State $state -Name 'authentik-postgresql-password' -Length 32
    Set-SecretValue -State $state -Name 'authentik-bootstrap-password' -Length 32
    Set-SecretValue -State $state -Name 'gravitee-admin-password' -Length 32
    Set-SecretValue -State $state -Name 'gravitee-oidc-client-secret' -Length 48

    Write-SecretState -State $state

    $sqlHost = 'sqlserver.erp-local.svc.cluster.local,1433'
    Set-KubernetesSecret -Name 'erp-sqlserver' -Values @{
        'sa-password' = $state['sql-sa-password']
        'sales-password' = $state['sales-db-password']
        'purchasing-password' = $state['purchasing-db-password']
        'inventory-password' = $state['inventory-db-password']
        'fulfilment-password' = $state['fulfilment-db-password']
    }

    Set-KubernetesSecret -Name 'erp-sqlserver-connection-strings' -Values @{
        sales = "Server=$sqlHost;Database=sales_db;User Id=sales_app;Password=$($state['sales-db-password']);Encrypt=True;TrustServerCertificate=True"
        purchasing = "Server=$sqlHost;Database=purchasing_db;User Id=purchasing_app;Password=$($state['purchasing-db-password']);Encrypt=True;TrustServerCertificate=True"
        inventory = "Server=$sqlHost;Database=inventory_db;User Id=inventory_app;Password=$($state['inventory-db-password']);Encrypt=True;TrustServerCertificate=True"
        fulfilment = "Server=$sqlHost;Database=fulfilment_db;User Id=fulfilment_app;Password=$($state['fulfilment-db-password']);Encrypt=True;TrustServerCertificate=True"
    }

    Set-KubernetesSecret -Name 'authentik-local' -Values @{
        'secret-key' = $state['authentik-secret-key']
        'postgresql-password' = $state['authentik-postgresql-password']
        'bootstrap-password' = $state['authentik-bootstrap-password']
        'bootstrap-email' = 'admin@localhost.localdomain'
    }

    Set-KubernetesSecret -Name 'gravitee-local' -Values @{
        'admin-password' = $state['gravitee-admin-password']
        'oidc-client-secret' = $state['gravitee-oidc-client-secret']
    }

    Write-Host "Local secret state written to $SecretsPath"
}

function Install-Authentik {
    $state = Read-SecretState
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

    Invoke-NativeCommand kubectl apply -f (Join-Path $BuildRoot 'k8s/authentik/blueprint-configmap.yaml')
    Invoke-NativeCommand helm repo add authentik https://charts.goauthentik.io
    Invoke-NativeCommand helm repo update
        $arguments = @(
                'upgrade', '--install', 'authentik', 'authentik/authentik',
                '--namespace', $Namespace,
                '-f', (Join-Path $BuildRoot 'k8s/authentik/values.local.yaml'),
                '-f', $generatedValuesPath
        )
        Invoke-NativeCommand helm @arguments
}

function Apply-GraviteeRoutes {
    Invoke-NativeCommand kubectl apply -f (Join-Path $BuildRoot 'k8s/gravitee/route-config.yaml')
}

function Install-Gravitee {
    Apply-GraviteeRoutes
    Invoke-NativeCommand helm repo add graviteeio https://helm.gravitee.io
    Invoke-NativeCommand helm repo update
    $arguments = @(
        'upgrade', '--install', 'gravitee', 'graviteeio/apim',
        '--namespace', $Namespace,
        '-f', (Join-Path $BuildRoot 'k8s/gravitee/values.local.yaml')
    )
    Invoke-NativeCommand helm @arguments
}

function Wait-ForPlatform {
    Invoke-NativeCommand kubectl rollout status statefulset/sqlserver --namespace $Namespace --timeout=600s
    Invoke-NativeCommand kubectl wait --for=condition=complete job/sqlserver-bootstrap --namespace $Namespace --timeout=600s
}

function Invoke-SkaffoldProfile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('platform', 'apps')]
        [string]$SkaffoldProfile
    )

    $arguments = @('run', '-f', (Join-Path $BuildRoot 'skaffold.yaml'), '-p', $SkaffoldProfile)
    Invoke-NativeCommand -FilePath skaffold -Arguments $arguments
}

Test-RequiredCommand dotnet 'Install the .NET 10 SDK.'
Test-RequiredCommand docker 'Install Docker Desktop.'
Test-RequiredCommand kubectl 'Install kubectl or enable the Docker Desktop Kubernetes CLI integration.'
if (-not $SkipDeploy) {
    Test-RequiredCommand skaffold 'Install Skaffold from https://skaffold.dev/docs/install/.'
}
if (($DeploymentScope -eq 'platform' -or $DeploymentScope -eq 'all') -and -not $SkipDeploy) {
    Test-RequiredCommand helm 'Install Helm from https://helm.sh/docs/intro/install/.'
}

Push-Location $RepoRoot
try {
    Test-DockerDesktopContext
    Initialize-Namespace

    if (-not $SkipSecrets) {
        Initialize-LocalSecrets
    }

    if (-not $SkipDeploy) {
        if ($DeploymentScope -eq 'all') {
            Invoke-SkaffoldProfile -SkaffoldProfile 'platform'
            Install-Authentik
            Install-Gravitee
            Wait-ForPlatform
            Invoke-SkaffoldProfile -SkaffoldProfile 'apps'
            Apply-GraviteeRoutes
        }
        elseif ($DeploymentScope -eq 'platform') {
            Invoke-SkaffoldProfile -SkaffoldProfile 'platform'
            Install-Authentik
            Install-Gravitee
            Wait-ForPlatform
        }
        else {
            Invoke-SkaffoldProfile -SkaffoldProfile 'apps'
            Apply-GraviteeRoutes
        }
    }
}
finally {
    Pop-Location
}
