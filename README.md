# Local User Account Audit Toolkit

A read-only PowerShell toolkit for local Windows account inventory and review.

## Features

- Local account status and last-logon context
- Password and expiration flags
- Built-in and disabled account review
- CSV, JSON, and HTML reports

## Run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Local_User_Account_Audit_Toolkit.ps1
```

## Safety

Read-only reporting only. No accounts are changed.
