#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Update-CodeDescriptions.ps1                                                  ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


$UpdateCodeScript = "$PSScriptRoot\ps\Update-Odb2Codes.ps1"

. "$UpdateCodeScript"


$RootPath = (Resolve-Path "$PSScriptRoot\..").Path
$HtmlPath = (Resolve-Path "$RootPath\html").Path
$HtmlDataPath = (Resolve-Path "$HtmlPath\data").Path

$BodyCodesJsonFilePath = Join-Path "$HtmlDataPath" "bodycodes.json"
$PowertrainCodesJsonFilePath = Join-Path "$HtmlDataPath" "powertraincodes.json"
$ChassisCodesJsonFilePath = Join-Path "$HtmlDataPath" "chassiscodes.json"
$NetworkCodesJsonFilePath = Join-Path "$HtmlDataPath" "networkcodes.json"

Write-Host "`n=========================================" -f DarkYellow
Write-Host "Updating Body Codes" -f DarkRed
Write-Host "=========================================`n`n" -f DarkYellow
$BodyCodesList        = Get-GenericBodyCodes
$BodyCodesJsonData = $BodyCodesList | ConvertTo-Json

Write-Host "Writing Body Codes Json File `"$BodyCodesJsonFilePath`"" -f DarkCyan
Set-Content -Path "$BodyCodesJsonFilePath" -Value "$BodyCodesJsonData"

Write-Host "`n=========================================" -f DarkYellow
Write-Host "Updating Powertrain Codes" -f DarkRed
Write-Host "=========================================`n`n" -f DarkYellow
$PowertrainCodesList  = Get-GenericPowertrainCodes 
$PowertrainCodesJsonData = $PowertrainCodesList | ConvertTo-Json
Write-Host "Writing Powertrain Codes Json File `"$PowertrainCodesJsonFilePath`"" -f DarkCyan
Set-Content -Path "$PowertrainCodesJsonFilePath" -Value "$PowertrainCodesJsonData"

Write-Host "`n=========================================" -f DarkYellow
Write-Host "Updating Chassis Codes" -f DarkRed
Write-Host "=========================================`n`n" -f DarkYellow
$ChassisCodesList     = Get-GenericChassisCodes
$ChassisCodesJsonData = $ChassisCodesList | ConvertTo-Json
Write-Host "Writing Body Chassis Json File `"$ChassisCodesJsonFilePath`"" -f DarkCyan
Set-Content -Path "$ChassisCodesJsonFilePath" -Value "$ChassisCodesJsonData"


Write-Host "`n=========================================" -f DarkYellow
Write-Host "Updating Chassis Codes" -f DarkRed
Write-Host "=========================================`n`n" -f DarkYellow
$NetworkCodesList     = Get-GenericNetworkCodes
$NetworkCodesJsonData = $NetworkCodesList | ConvertTo-Json
Write-Host "Writing Body Chassis Json File `"$NetworkCodesJsonFilePath`"" -f DarkCyan
Set-Content -Path "$NetworkCodesJsonFilePath" -Value "$NetworkCodesJsonData"


