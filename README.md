# Local User Account Audit Toolkit

PowerShell tooling for auditing local Windows accounts and applying narrowly scoped account repairs.

## Scripts

- `Local_User_Account_Audit_Toolkit.ps1` — read-only inventory and CSV, JSON, and HTML reporting.
- `Local_User_Account_Repair_Toolkit.ps1` — guarded repair workflow for one named local user.

## Repair actions

The repair script can enable or disable an account, clear `PasswordNeverExpires`, and update the account description. It refuses to disable the currently signed-in user and refuses to disable the built-in Administrator or Guest accounts.

Windows and the `Microsoft.PowerShell.LocalAccounts` cmdlets are required. Actual changes require an elevated PowerShell session.

## Examples

Preview an enable operation:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Local_User_Account_Repair_Toolkit.ps1 `
  -UserName SupportUser -Enable -DryRun
```

Apply several repairs without the interactive prompt:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Local_User_Account_Repair_Toolkit.ps1 `
  -UserName SupportUser -Enable -RequirePasswordExpiry `
  -Description "Local support account" -Yes
```

Omit `-Yes` to require typing `YES` before changes are made.

## Evidence and verification

Each run creates a timestamped directory under `%ProgramData%\LocalUserAccountRepair` unless `-OutputPath` is supplied. It contains `before.json`, `after.json`, and `repair.log`. The pre-change JSON is the account-state backup for this targeted workflow. Applied changes are checked against the requested final state.

`-DryRun` records intended actions and does not apply or verify changes.

## Exit codes

| Code | Meaning |
|---:|---|
| 0 | Completed successfully, including a successful dry run |
| 2 | Invalid arguments, missing account, or safety refusal |
| 3 | Unsupported platform or missing LocalAccounts cmdlets |
| 4 | Elevation required |
| 10 | User cancelled at the confirmation prompt |
| 20 | One or more repair actions failed |
| 30 | Actions ran, but post-repair verification failed |

## Validation status

The scripts were source-reviewed during this update. They were not runtime-tested on a Windows endpoint.

## Author

Dewald Pretorius — L2 IT Support Engineer
