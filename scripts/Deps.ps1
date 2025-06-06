#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Deps.ps1                                                                     ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


$CommonScript = "$PSScriptRoot\ps\common.ps1"
$ImportOnlineOdb2DataScript = "$PSScriptRoot\ps\Import-OnlineOdb2Data.ps1"
$ODB2CodesScript = "$PSScriptRoot\ps\Read-ODB2Codes.ps1"
$ODB2TypesScript = "$PSScriptRoot\ps\Read-ODB2Types.ps1"
$DatabaseScript = "$PSScriptRoot\ps\Database.ps1"

. "$CommonScript"
. "$ImportOnlineOdb2DataScript"
. "$ODB2CodesScript"
. "$ODB2TypesScript"
. "$DatabaseScript"


Register-SqlLib
Register-HtmlAgilityPack


<#

Get-FunctionList ps | Sort-Object Base, Name | Group-Object Base | % { 
  Write-Host "`n ► $($_.Name)" -f Red
  $_.Group | % {Write-Host " • $($_.Name)"
  }
} 

 ► common
 • Get-CarMakeListJsonPath
 • Get-DatabaseFilePath
 • Get-HtmlDataPath
 • Get-HtmlDbPath
 • Get-HtmlPath
 • Get-JsonDataPath
 • Get-RootPath
 • Get-ScriptsLibsPath
 • Get-ScriptsPath
 • Get-ScriptsPsPath
 • Get-ScriptsSqlPath
 • Register-HtmlAgilityPack
 • Register-SqlLib
 • Update-AllLists

 ► Database
 • Add-AllGenericCodeLists
 • Add-CarMakesInTable
 • Add-CodesListInTable
 • Add-CodeTypesInTable
 • Add-KellyBlueBookCodesInTable
 • Add-ManufacturerSpecificCodes
 • Add-PartTypesInTable
 • Add-SystemCategoriesInTable
 • Get-CarMakeMap
 • Get-CodeTypeMap
 • Get-PartTypeMap
 • Get-SystemCategoryMap
 • Insert-Batch
 • Invoke-ExecuteSqlScript
 • New-Odb2Tables
 • update-CodesUrlInDb
 • Write-DebugDbCommand
 • Write-DebugLog
 • Write-DebugLogToFile
 • Write-SqlScriptStats

 ► Import-OnlineOdb2Data
 • ConvertFrom-Base64CompressedJsonBlock
 • Export-ManufacturerSpecificCodesJson
 • Get-AllCarMakes
 • Get-CarMakeList
 • Get-GenericBodyCodeDescriptionFromUrl
 • Get-GenericBodyCodes
 • Get-GenericBodyCodesUrls
 • Get-GenericChassisCodes
 • Get-GenericNetworkCodes
 • Get-GenericPowertrainCodes
 • Get-GenericPowertrainCodesFromUrl
 • Get-GenericPowertrainCodesUrls
 • Get-KellyBlueBookCodesJson
 • Get-KellyBlueBookCodesTable
 • Get-ManufacturerCodeUrl
 • Get-ManufacturerSpecificCodes
 • Get-Obd2CodeRange
 • Register-HtmlAgilityPack
 • Test-GetDataFromWeb
 • TryParseErrorCode
 • Update-CarMakeList

 ► Install-HtmlAgilityPack
 • Install-HtmlAgilityPack
 • Save-OnlineFile

 ► Read-ODB2Codes
 • Get-CodeDescription

 ► Read-ODB2Types
 • Get-CodeTypeDescription
 • Get-ObdCodeType
 • Get-PartTypeDescription
 • Get-SystemCategoryDescription
 • Resolve-ObdCode
 
#>