#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Test.ps1                                                                     ║
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
Test-GetDataFromWeb -Path "$PSSCriptRoot\TestResults.json"
Write-Host "Output in `"$PSSCriptRoot\TestResults.json`"" -f Red