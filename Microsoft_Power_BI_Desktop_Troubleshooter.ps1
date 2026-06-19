#requires -Version 5.1
<#
.SYNOPSIS
  Microsoft Power BI Desktop Troubleshooter
.NOTES
  Created by Dewald Pretorius
#>
[CmdletBinding()]
param([string]$OutputPath)

$ErrorActionPreference='SilentlyContinue'
$Author='Dewald Pretorius'
if(-not $OutputPath){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'PowerBI_Desktop_Troubleshooter_Reports'}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$txt=Join-Path $OutputPath "PowerBI_Diagnostics_$stamp.txt"
$csv=Join-Path $OutputPath "PowerBI_Findings_$stamp.csv"

function Add-Finding{param($Area,$Check,$Status,$Detail,$Recommendation)
 [pscustomobject]@{Area=$Area;Check=$Check;Status=$Status;Detail=$Detail;Recommendation=$Recommendation}
}
$findings=@()
$process=Get-Process PBIDesktop -ErrorAction SilentlyContinue
$findings+=Add-Finding 'Application' 'Running process' ($(if($process){'Detected'}else{'Not running'})) ($(if($process){"Instances=$($process.Count); WorkingSetMB=$([math]::Round((($process|Measure-Object WorkingSet -Sum).Sum/1MB),1))"}else{'PBIDesktop.exe is not currently running'})) 'Close duplicate instances before testing refresh or publishing.'

$paths=@(
 "$env:ProgramFiles\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
 "${env:ProgramFiles(x86)}\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
)
$exe=$paths|Where-Object{$_ -and(Test-Path $_)}|Select-Object -First 1
if(-not $exe){$appx=Get-AppxPackage '*Microsoft.MicrosoftPowerBIDesktop*';if($appx){$exe=$appx.InstallLocation}}
$findings+=Add-Finding 'Application' 'Installation' ($(if($exe){'Pass'}else{'Review'})) ($(if($exe){$exe}else{'Power BI Desktop installation path not found'})) 'Repair or reinstall Power BI Desktop if installation files are missing.'

$cacheRoots=@(
 "$env:LOCALAPPDATA\Microsoft\Power BI Desktop",
 "$env:LOCALAPPDATA\Packages\Microsoft.MicrosoftPowerBIDesktop_8wekyb3d8bbwe\LocalCache"
)
foreach($root in $cacheRoots){
 if(Test-Path $root){
  $size=(Get-ChildItem $root -Recurse -File|Measure-Object Length -Sum).Sum
  $findings+=Add-Finding 'Cache' $root 'Detected' ("SizeMB={0}" -f [math]::Round($size/1MB,1)) 'Large caches can be backed up and cleared after Power BI Desktop is closed.'
 }
}

$odbc=Get-OdbcDriver|Select-Object Name,Platform,Version
$findings+=Add-Finding 'Data Sources' 'ODBC drivers' ($(if($odbc){'Detected'}else{'Review'})) ("DriverCount=$($odbc.Count)") 'Confirm the required 32-bit or 64-bit data-source driver matches Power BI Desktop.'

$gatewayServices=Get-Service PBIEgwService -ErrorAction SilentlyContinue
$findings+=Add-Finding 'Gateway' 'On-premises gateway service' ($(if($gatewayServices.Status -eq 'Running'){'Pass'}elseif($gatewayServices){'Review'}else{'Not installed'})) ($(if($gatewayServices){"Status=$($gatewayServices.Status)"}else{'Gateway service not found on this device'})) 'Gateway checks are relevant only when this computer hosts the on-premises data gateway.'

$targets='app.powerbi.com','api.powerbi.com','login.microsoftonline.com'
foreach($target in $targets){
 $dns=$false;$https=$false
 try{$dns=[bool](Resolve-DnsName $target -ErrorAction Stop|Select-Object -First 1)}catch{}
 try{$https=Test-NetConnection $target -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue}catch{}
 $findings+=Add-Finding 'Connectivity' $target ($(if($dns -and $https){'Pass'}else{'Fail'})) "DNS=$dns; HTTPS443=$https" 'Review DNS, proxy, firewall, TLS inspection, and Conditional Access when connectivity fails.'
}

$crashes=Get-WinEvent -FilterHashtable @{LogName='Application';StartTime=(Get-Date).AddDays(-7)}|Where-Object{$_.Message -match 'PBIDesktop|Microsoft.Mashup|msmdsrv'}|Select-Object -First 30 TimeCreated,Id,ProviderName,LevelDisplayName,Message
$findings+=Add-Finding 'Reliability' 'Recent Power BI events' ($(if($crashes){'Review'}else{'Pass'})) ("MatchingEvents=$($crashes.Count)") 'Correlate event timestamps with refresh, visual rendering, custom connectors, and publishing attempts.'

$findings|Export-Csv $csv -NoTypeInformation -Encoding UTF8
@(
 'MICROSOFT POWER BI DESKTOP TROUBLESHOOTER'
 "Created by $Author"
 "Generated: $(Get-Date)"
 ''
 'SUMMARY'
 ($findings|Format-Table -AutoSize|Out-String -Width 240)
 'RECENT EVENTS'
 ($crashes|Format-List|Out-String -Width 240)
 'INSTALLED ODBC DRIVERS'
 ($odbc|Format-Table -AutoSize|Out-String -Width 240)
)|Set-Content $txt -Encoding UTF8

Write-Host 'Power BI diagnostics complete.' -ForegroundColor Green
Write-Host "Text report: $txt"
Write-Host "CSV findings: $csv"
