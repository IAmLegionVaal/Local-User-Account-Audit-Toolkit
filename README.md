# Local User Account Audit Toolkit

PowerShell tools for reviewing local Windows accounts and applying guarded, target-specific corrections.

## Audit

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Local_User_Account_Audit_Toolkit.ps1
```

## Repair

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Local_User_Account_Repair_Toolkit.ps1 -UserName SupportUser -Enable -DryRun
```

Examples:

```powershell
.\Local_User_Account_Repair_Toolkit.ps1 -UserName SupportUser -Enable
.\Local_User_Account_Repair_Toolkit.ps1 -UserName OldUser -Disable
.\Local_User_Account_Repair_Toolkit.ps1 -UserName SupportUser -RequirePasswordExpiry
.\Local_User_Account_Repair_Toolkit.ps1 -UserName SupportUser -Description 'Approved support account'
```

The repair script captures the selected account before and after the change, supports `-DryRun`, confirmation, logs and clear exit codes. It refuses to disable the current user or the built-in Administrator and Guest accounts.

## Author

Dewald Pretorius — L2 IT Support Engineer
