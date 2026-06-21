# Microsoft Power BI Desktop Troubleshooter

Created by **Dewald Pretorius**.

The repository includes the original diagnostics and a new `Repair.ps1` helper.

Supported actions:

- `Diagnose`
- `ResetCache`
- `FlushDns`

```powershell
.\Repair.ps1 -Action Diagnose
.\Repair.ps1 -Action ResetCache -WhatIf
.\Repair.ps1 -Action ResetCache -Confirm
```

Close Power BI Desktop before cache repair. Existing cache and workspace folders are preserved as timestamped backups. Each run saves pre-change evidence and a log. Source-reviewed for PowerShell 5.1; not runtime-tested against every Power BI Desktop build.
