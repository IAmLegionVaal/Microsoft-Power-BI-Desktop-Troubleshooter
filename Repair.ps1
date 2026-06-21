#requires -Version 5.1
<# Created by Dewald Pretorius. #>
[CmdletBinding(SupportsShouldProcess=$true)]
param([ValidateSet('Diagnose','ResetCache','FlushDns')][string]$Action='Diagnose',[string]$OutputPath=(Join-Path ([Environment]::GetFolderPath('Desktop')) 'Power_BI_Desktop_Repair'))
$ErrorActionPreference='Stop';$cachePaths=@("$env:LOCALAPPDATA\Microsoft\Power BI Desktop\Cache","$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces")
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null;$stamp=Get-Date -Format yyyyMMdd_HHmmss;$log=Join-Path $OutputPath "Repair_$stamp.log";function Log($m){$l='{0:u} {1}'-f(Get-Date),$m;Write-Host $l;Add-Content $log $l}
[ordered]@{Action=$Action;Processes=@(Get-Process PBIDesktop,'Microsoft.Mashup.Container.NetFX40' -ErrorAction SilentlyContinue|Select-Object Name,Id);Caches=@($cachePaths|ForEach-Object{[pscustomobject]@{Path=$_;Exists=Test-Path $_}});PowerBI443=(Test-NetConnection 'api.powerbi.com' -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue)}|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OutputPath "PreRepair_$stamp.json")
if($Action -eq 'Diagnose'){Log '[COMPLETE] Snapshot saved.';exit 0}
try{if($Action -eq 'ResetCache' -and $PSCmdlet.ShouldProcess('Power BI Desktop caches','Back up and reset')){if(Get-Process PBIDesktop,'Microsoft.Mashup.Container.NetFX40' -ErrorAction SilentlyContinue){throw 'Close Power BI Desktop and wait for Mashup processes to exit.'};foreach($path in $cachePaths){if(Test-Path $path){$backup="$path.backup-$stamp";Move-Item $path $backup -Force;New-Item -ItemType Directory $path -Force|Out-Null;Log "[BACKUP] $backup"}}}
elseif($Action -eq 'FlushDns' -and $PSCmdlet.ShouldProcess('Windows DNS client cache','Clear')){Clear-DnsClientCache}}catch{Log "[FAILED] $($_.Exception.Message)";exit 5};Log '[COMPLETE] Repair completed.';exit 0
