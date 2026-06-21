[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$UserName,
    [switch]$Enable,
    [switch]$Disable,
    [switch]$RequirePasswordExpiry,
    [string]$Description,
    [switch]$DryRun,
    [switch]$Yes,
    [string]$OutputPath = (Join-Path $env:ProgramData 'LocalUserAccountRepair')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Failures = 0
$script:VerificationFailures = 0
$script:Actions = 0

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($env:OS -ne 'Windows_NT') { Write-Error 'This tool requires Windows.'; exit 3 }
if (-not ($Enable -or $Disable -or $RequirePasswordExpiry -or $PSBoundParameters.ContainsKey('Description'))) { Write-Error 'Choose at least one repair action.'; exit 2 }
if ($Enable -and $Disable) { Write-Error 'Choose either -Enable or -Disable.'; exit 2 }
if (-not (Get-Command Get-LocalUser -ErrorAction SilentlyContinue)) { Write-Error 'Microsoft.PowerShell.LocalAccounts is unavailable in this PowerShell host.'; exit 3 }
if (-not $DryRun -and -not (Test-Administrator)) { Write-Error 'Run from an elevated PowerShell session.'; exit 4 }

try { $initialUser = Get-LocalUser -Name $UserName -ErrorAction Stop } catch { Write-Error "Local user '$UserName' was not found."; exit 2 }
if ($Disable) {
    if ($UserName -ieq $env:USERNAME) { Write-Error 'Refusing to disable the current user.'; exit 2 }
    if ($initialUser.SID.Value -match '-(500|501)$') { Write-Error 'Refusing to disable built-in Administrator or Guest.'; exit 2 }
}

$runPath = Join-Path $OutputPath (Get-Date -Format 'yyyyMMdd_HHmmss')
New-Item -ItemType Directory -Path $runPath -Force | Out-Null
$logPath = Join-Path $runPath 'repair.log'
$beforePath = Join-Path $runPath 'before.json'
$afterPath = Join-Path $runPath 'after.json'

function Write-Log([string]$Message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" | Tee-Object -FilePath $logPath -Append
}
function Get-RepairState {
    Get-LocalUser -Name $UserName -ErrorAction Stop |
        Select-Object Name,Enabled,Description,PasswordNeverExpires,PasswordExpires,PasswordRequired,PasswordLastSet,LastLogon,SID
}
function Invoke-RepairAction([string]$DescriptionText,[scriptblock]$Script) {
    $script:Actions++
    Write-Log "ACTION: $DescriptionText"
    if ($DryRun) { Write-Log "DRY-RUN: $DescriptionText"; return }
    try {
        & $Script
        Write-Log "SUCCESS: $DescriptionText"
    } catch {
        $script:Failures++
        Write-Log "FAILED: $DescriptionText - $($_.Exception.Message)"
    }
}

Get-RepairState | ConvertTo-Json -Depth 5 | Set-Content $beforePath -Encoding UTF8
Write-Log "Saved pre-change account state to $beforePath"

if (-not $DryRun -and -not $Yes) {
    if ((Read-Host "Apply selected changes to local user '$UserName'? Type YES") -cne 'YES') { Write-Log 'Repair cancelled.'; exit 10 }
}

if ($Enable) { Invoke-RepairAction "Enabling local user $UserName" { Enable-LocalUser -Name $UserName } }
if ($Disable) { Invoke-RepairAction "Disabling local user $UserName" { Disable-LocalUser -Name $UserName } }
if ($RequirePasswordExpiry) { Invoke-RepairAction "Requiring password expiry for $UserName" { Set-LocalUser -Name $UserName -PasswordNeverExpires $false } }
if ($PSBoundParameters.ContainsKey('Description')) { Invoke-RepairAction "Updating description for $UserName" { Set-LocalUser -Name $UserName -Description $Description } }

if (-not $DryRun) { Start-Sleep -Seconds 1 }
$finalUser = Get-RepairState
$finalUser | ConvertTo-Json -Depth 5 | Set-Content $afterPath -Encoding UTF8

if (-not $DryRun) {
    if ($Enable -and -not $finalUser.Enabled) { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: account is not enabled.' }
    if ($Disable -and $finalUser.Enabled) { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: account is not disabled.' }
    if ($RequirePasswordExpiry -and $finalUser.PasswordNeverExpires) { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: PasswordNeverExpires remains enabled.' }
    if ($PSBoundParameters.ContainsKey('Description') -and $finalUser.Description -cne $Description) { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: description does not match the requested value.' }
}

if ($script:Failures -gt 0) { exit 20 }
if ($script:VerificationFailures -gt 0) { exit 30 }
Write-Log "Workflow completed. Actions: $script:Actions; DryRun: $DryRun"
exit 0
