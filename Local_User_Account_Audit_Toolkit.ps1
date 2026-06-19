#requires -Version 5.1
[CmdletBinding()]
param([string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Local_User_Audit_Reports'}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$users=Get-LocalUser -ErrorAction SilentlyContinue|Select-Object Name,Enabled,Description,LastLogon,PasswordLastSet,PasswordExpires,UserMayChangePassword,PasswordRequired,SID
$summary=[PSCustomObject]@{Computer=$env:COMPUTERNAME;AccountCount=@($users).Count;Enabled=@($users|Where-Object Enabled).Count;Disabled=@($users|Where-Object Enabled -eq $false).Count;Generated=Get-Date}
$users|Export-Csv (Join-Path $OutputPath "local_users_$stamp.csv") -NoTypeInformation -Encoding UTF8
@{Summary=$summary;Users=$users}|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OutputPath "local_user_audit_$stamp.json") -Encoding UTF8
$html="<h1>Local User Account Audit - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary)|ConvertTo-Html -Fragment)<h2>Accounts</h2>$($users|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Local User Account Audit'|Set-Content (Join-Path $OutputPath "local_user_audit_$stamp.html") -Encoding UTF8
$summary|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
