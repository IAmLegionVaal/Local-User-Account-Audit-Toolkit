[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [Parameter(Mandatory)][string]$UserName,
 [switch]$Enable,
 [switch]$Disable,
 [switch]$RequirePasswordExpiry,
 [string]$Description,
 [switch]$DryRun,
 [switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'LocalUserAccountRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory -Path $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State{Get-LocalUser -Name $UserName -ErrorAction Stop|Select-Object Name,Enabled,Description,PasswordExpires,PasswordRequired,PasswordLastSet,LastLogon,SID}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
$user=State;$user|ConvertTo-Json -Depth 4|Set-Content $before -Encoding UTF8
if(-not($Enable -or $Disable -or $RequirePasswordExpiry -or $PSBoundParameters.ContainsKey('Description'))){Write-Error 'Choose at least one repair action.';exit 2}
if($Enable -and $Disable){Write-Error 'Choose either -Enable or -Disable.';exit 2}
if(-not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
if($Disable){if($UserName -ieq $env:USERNAME){Write-Error 'Refusing to disable the current user.';exit 2};if($user.SID.Value -match '-(500|501)$'){Write-Error 'Refusing to disable built-in Administrator or Guest.';exit 2}}
if(-not $Yes -and -not $DryRun){if((Read-Host "Apply selected changes to local user '$UserName'? Type YES") -ne 'YES'){Log 'Cancelled.';exit 10}}
if($Enable){Act "Enabling local user $UserName" {Enable-LocalUser -Name $UserName}}
if($Disable){Act "Disabling local user $UserName" {Disable-LocalUser -Name $UserName}}
if($RequirePasswordExpiry){Act "Requiring password expiry for $UserName" {Set-LocalUser -Name $UserName -PasswordNeverExpires $false}}
if($PSBoundParameters.ContainsKey('Description')){Act "Updating description for $UserName" {Set-LocalUser -Name $UserName -Description $Description}}
Start-Sleep 1;State|ConvertTo-Json -Depth 4|Set-Content $after -Encoding UTF8
if($script:Failures){exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
