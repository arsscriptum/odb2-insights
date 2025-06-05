#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Import-DataInDb.ps1                                                          ║
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



function Add-Odb2Data {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Use INSERT OR REPLACE instead of INSERT")]
        [switch]$ReplaceOnError
    )

    Write-Host "`n`n=====================================" -f DarkYellow
    Write-Host "New-Odb2Tables" -f DarkRed
    Write-Host "=====================================" -f DarkYellow

    $Res = New-Odb2Tables -ReplaceOnError:$ReplaceOnError
    if ($Res) {
        Write-Host "New-Odb2Tables → SUCCESS" -f DarkGreen
    } else {
        Write-Host "New-Odb2Tables → FAILED" -f DarkRed
        return
    }

    Write-Host "`n`n=====================================" -f DarkYellow
    Write-Host "Add-PartTypesInTable" -f DarkRed
    Write-Host "=====================================" -f DarkYellow

    $Res = Add-PartTypesInTable -ReplaceOnError:$ReplaceOnError
    if ($Res) {
        Write-Host "Add-PartTypesInTable → SUCCESS" -f DarkGreen
    } else {
        Write-Host "Add-PartTypesInTable → FAILED" -f DarkRed
        return
    }
    Write-Host "`n`n=====================================" -f DarkYellow
    Write-Host "Add-CarMakesInTable" -f DarkRed
    Write-Host "=====================================" -f DarkYellow

    $Res = Add-CarMakesInTable -ReplaceOnError:$ReplaceOnError
    if ($Res) {
        Write-Host "Add-CarMakesInTable → SUCCESS" -f DarkGreen
    } else {
        Write-Host "Add-CarMakesInTable → FAILED" -f DarkRed
        return
    }
    Write-Host "`n`n=====================================" -f DarkYellow
    Write-Host "Add-SystemCategoriesInTable" -f DarkRed
    Write-Host "=====================================" -f DarkYellow


    $Res = Add-SystemCategoriesInTable -ReplaceOnError:$ReplaceOnError
    if ($Res) {
        Write-Host "Add-SystemCategoriesInTable → SUCCESS" -f DarkGreen
    } else {
        Write-Host "Add-SystemCategoriesInTable → FAILED" -f DarkRed
        return
    }
    Write-Host "`n`n=====================================" -f DarkYellow
    Write-Host "Add-CodeTypesInTable" -f DarkRed
    Write-Host "=====================================" -f DarkYellow
    $Res = Add-CodeTypesInTable -ReplaceOnError:$ReplaceOnError
    if ($Res) {
        Write-Host "Add-CodeTypesInTable → SUCCESS" -f DarkGreen
    } else {
        Write-Host "Add-CodeTypesInTable → FAILED" -f DarkRed
        return
    }
    Write-Host "`n`n=====================================" -f DarkYellow
    Write-Host "Add-KellyBlueBookCodesInTable" -f DarkRed
    Write-Host "=====================================" -f DarkYellow
    $Res = Add-KellyBlueBookCodesInTable
    if ($Res) {
        Write-Host "Add-KellyBlueBookCodesInTable → SUCCESS" -f DarkGreen
    } else {
        Write-Host "Add-KellyBlueBookCodesInTable → FAILED" -f DarkRed
        return
    }

    Write-Host "`n`n=====================================" -f DarkYellow
    Write-Host "Add-ManufacturerSpecificCodes" -f DarkRed
    Write-Host "=====================================" -f DarkYellow
    $Res = Add-ManufacturerSpecificCodes
    if ($Res) {
        Write-Host "Add-ManufacturerSpecificCodes → SUCCESS" -f DarkGreen
    } else {
        Write-Host "Add-ManufacturerSpecificCodes → FAILED" -f DarkRed
        return
    }


}

Register-SqlLib
Register-HtmlAgilityPack

Add-Odb2Data