[CmdletBinding()]
param(
    [string]$Namespace = 'erp-local',

    [int]$NamespaceTimeoutSeconds = 300,

    [int]$HelmTimeoutSeconds = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildRoot = Resolve-Path (Join-Path $ScriptRoot '..')
$RepoRoot = Resolve-Path (Join-Path $BuildRoot '..')
$LocalStatePath = Join-Path $BuildRoot '.local'
$SkaffoldConfigPath = Join-Path $BuildRoot 'skaffold.yaml'

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

function Test-DockerDesktopContext {
    $context = & kubectl config current-context
    if ($LASTEXITCODE -ne 0) {
        throw 'kubectl has no current context. Enable Docker Desktop Kubernetes, then retry.'
    }

    if ($context -ne 'docker-desktop') {
        throw "kubectl current context is '$context'. Switch to 'docker-desktop' before running this destructive cleanup."
    }
}

function Stop-ConflictingProcesses {
    $processes = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -in @('skaffold.exe', 'skaffold') -or (
            $_.Name -in @('kubectl.exe', 'kubectl') -and
            $_.CommandLine -match '(?i)(^|\s)port-forward(\s|$)'
        )
    })

    foreach ($process in $processes) {
        Write-Host "Stopping process $($process.ProcessId): $($process.CommandLine)"
        Stop-Process -Id $process.ProcessId -Force
        try {
            Wait-Process -Id $process.ProcessId -Timeout 15 -ErrorAction Stop
        }
        catch [System.TimeoutException] {
            throw "Process $($process.ProcessId) did not stop within 15 seconds."
        }
        catch [System.ArgumentException] {
            # The process exited before Wait-Process observed it.
        }
    }

    return $processes.Count
}

function Invoke-SkaffoldDelete {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('apps', 'platform')]
        [string]$Profile
    )

    $arguments = @('delete', '-f', $SkaffoldConfigPath, '-p', $Profile)
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & skaffold @arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $output | Out-Host
    if ($exitCode -eq 0) {
        return
    }

    $outputText = $output | Out-String
    if ($outputText -match '(?i)not found|no resources found|does not exist') {
        Write-Warning "Skaffold $Profile resources were already absent. Continuing."
        return
    }

    if ($Profile -eq 'platform' -and $outputText -match '(?i)failed to render release.*no cached repo found') {
        Write-Warning 'Skaffold could not render the platform Helm charts because the local Helm cache is absent. Continuing; all Helm releases and the erp-local namespace will be removed next.'
        return
    }

    throw "skaffold $($arguments -join ' ') failed with exit code $exitCode."
}

function Get-HelmReleases {
    $output = & helm list --all-namespaces --output json
    if ($LASTEXITCODE -ne 0) {
        throw "helm list --all-namespaces --output json failed with exit code $LASTEXITCODE"
    }

    $json = $output | Out-String
    if ([string]::IsNullOrWhiteSpace($json)) {
        return @()
    }

    return @($json | ConvertFrom-Json)
}

function Remove-AllHelmReleases {
    $removedReleases = @()
    do {
        $releases = Get-HelmReleases
        foreach ($release in $releases) {
            Write-Host "Uninstalling Helm release '$($release.name)' from namespace '$($release.namespace)'."
            Invoke-NativeCommand helm uninstall $release.name --namespace $release.namespace --wait "--timeout=$HelmTimeoutSeconds`s" | Out-Host
            $removedReleases += $release
        }
    }
    while ($releases.Count -gt 0)

    return $removedReleases
}

function Test-NamespaceExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & kubectl get namespace $Name --output name 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return $exitCode -eq 0
}

function Remove-Namespace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Test-NamespaceExists -Name $Name)) {
        Write-Host "Namespace '$Name' is already absent."
        return $false
    }

    try {
        Invoke-NativeCommand kubectl delete namespace $Name --wait=true "--timeout=$NamespaceTimeoutSeconds`s" | Out-Host
    }
    catch {
        Write-Host "Namespace '$Name' did not delete cleanly. Capturing diagnostics."
        & kubectl get namespace $Name -o yaml
        & kubectl get pvc,pv -A
        throw
    }

    return $true
}

function Remove-LocalErpImages {
    $images = @(docker images --format '{{.Repository}}:{{.Tag}}' | Where-Object { $_ -like 'acme-erp/*' })
    if ($LASTEXITCODE -ne 0) {
        throw "docker images failed with exit code $LASTEXITCODE"
    }

    if ($images.Count -eq 0) {
        Write-Host 'No local acme-erp/* images found.'
        return 0
    }

    Write-Host "Removing $($images.Count) local acme-erp/* image tags."
    Invoke-NativeCommand -FilePath docker -Arguments (@('rmi', '-f') + $images) | Out-Host
    return $images.Count
}

function Remove-LocalState {
    if (-not (Test-Path $LocalStatePath)) {
        Write-Host "Generated local state '$LocalStatePath' is already absent."
        return $false
    }

    Remove-Item -Recurse -Force $LocalStatePath
    return $true
}

function Invoke-DockerPrune {
    Write-Host 'Pruning all unused Docker containers, images, volumes, networks, and build cache.'
    Invoke-NativeCommand -FilePath docker -Arguments @('system', 'prune', '-a', '--volumes', '--force') | Out-Host
}

function Confirm-TeardownState {
    if (Test-NamespaceExists -Name $Namespace) {
        throw "Namespace '$Namespace' still exists after teardown."
    }

    $remainingImages = @(docker images --format '{{.Repository}}:{{.Tag}}' | Where-Object { $_ -like 'acme-erp/*' })
    if ($LASTEXITCODE -ne 0) {
        throw "docker images failed with exit code $LASTEXITCODE"
    }

    if ($remainingImages.Count -ne 0) {
        throw "Local acme-erp/* image tags remain after teardown: $($remainingImages -join ', ')"
    }

    if (Test-Path $LocalStatePath) {
        throw "Generated local state '$LocalStatePath' still exists after teardown."
    }
}

Test-RequiredCommand docker 'Install Docker Desktop.'
Test-RequiredCommand kubectl 'Install kubectl or enable the Docker Desktop Kubernetes CLI integration.'
Test-RequiredCommand skaffold 'Install Skaffold from https://skaffold.dev/docs/install/.'
Test-RequiredCommand helm 'Install Helm from https://helm.sh/docs/intro/install/.'

Push-Location $RepoRoot
try {
    Test-DockerDesktopContext

    $stoppedProcessCount = Stop-ConflictingProcesses
    Invoke-SkaffoldDelete -Profile apps
    Invoke-SkaffoldDelete -Profile platform
    $removedHelmReleases = @(Remove-AllHelmReleases)
    $namespaceRemoved = Remove-Namespace -Name $Namespace
    $removedImageCount = Remove-LocalErpImages
    $localStateRemoved = Remove-LocalState
    Invoke-DockerPrune
    Confirm-TeardownState

    Write-Host 'Clean-slate teardown completed.'
    Write-Host "Stopped conflicting processes: $stoppedProcessCount"
    Write-Host "Removed Helm releases: $($removedHelmReleases.Count)"
    Write-Host "Removed namespace '$Namespace': $namespaceRemoved"
    Write-Host "Removed local acme-erp/* image tags: $removedImageCount"
    Write-Host "Removed generated local state: $localStateRemoved"
}
finally {
    Pop-Location
}