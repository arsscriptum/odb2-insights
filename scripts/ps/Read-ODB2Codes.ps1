

#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Read-ODB2Codes.ps1                                                           ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaumep  <guillaumep@luminator.com>                                       ║
#║   Copyright (C) Luminator Technology Group.  All rights reserved.              ║
#╚════════════════════════════════════════════════════════════════════════════════╝




function Get-CodeDescription {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter a 5-character OBD code like P0303")]
        [ValidatePattern('^[PpBbCcUu][01][0-9A-Ca-c][0-9A-Fa-f]{2}$')]
        [string]$Code,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("acura","audi","bmw","chevrolet","dodge","chrysler","jeep","ford","honda","hyundai",
                     "infiniti","isuzu","jaguar","kia","land","rover","lexus","mazda","mitsubishi","nissan",
                     "subaru","toyota","vw")]
        [string]$CarMake
    )

    $RootPath = (Resolve-Path "$PSScriptRoot\..").Path
    $FilePath = "data\specific\{0}.json" -f $CarMake
    $CarMakeJson = Join-Path $RootPath $FilePath

    if (-not (Test-Path $CarMakeJson)) {
        Write-Warning "File not found: $CarMakeJson"
        return
    }

    try {
        $Codes = Get-Content $CarMakeJson | ConvertFrom-Json
    } catch {
        Write-Error "Failed to parse JSON from file: $CarMakeJson"
        return
    }

    $Match = $Codes | Where-Object { $_.Code -eq $Code }

    if ($null -ne $Match) {
        return [PSCustomObject]@{
            Code        = $Match.Code
            Description = $Match.Description.Trim()
            CarMake     = $CarMake
        }
    } else {



        $Url = 'https://www.obd-codes.com/{0}' -f $Code
        &(Get-BravePath) "$Url"
        #$Url = 'https://www.kbb.com/obd-ii/{0}/' -f $Code
        #$Url = 'https://obd2pros.com/dtc-codes/{0}/' -f $Code

        Write-Output "Code $Code not found for $CarMake."
    }
}
