# Microsoft Power BI Desktop Troubleshooter

Created by **Dewald Pretorius**.

A read-only PowerShell diagnostic toolkit for Power BI Desktop refresh failures, crashes, slow performance, data-source drivers, gateway state, service connectivity, and recent reliability events.

## Checks

- Power BI Desktop installation and running processes
- Process memory usage and duplicate instances
- Local cache locations and approximate size
- Installed ODBC drivers and platform architecture
- On-premises gateway service state
- DNS and HTTPS connectivity to Power BI services
- Recent Power BI, Mashup Engine, and Analysis Services events

## Run

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Microsoft_Power_BI_Desktop_Troubleshooter.ps1"
```

Reports are saved to `Desktop\PowerBI_Desktop_Troubleshooter_Reports` as both TXT and CSV.

## Scenarios supported

- Desktop crashes or freezes
- Slow report opening and rendering
- Data refresh failures
- Missing or mismatched drivers
- Gateway connectivity questions
- Publishing or sign-in connectivity failures
- Large local caches
- Mashup Engine and model service errors

## Safety

The script collects diagnostic information only. It does not clear caches, change drivers, alter data sources, or modify Power BI configuration.
