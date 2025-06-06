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



function Export-DataFromDb {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory = $true, HelpMessage = 'Output directory for JSON files')]
        [string]$Path
    )

    [string]$DatabasePath = Get-DatabaseFilePath

    Write-Host "`n`n=====================================" -f DarkYellow
    Write-Host "New-Odb2Tables" -f DarkRed
    Write-Host "=====================================" -f DarkYellow

    # Connect to database
    $connectionString = "Data Source=$DatabasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection $connectionString
    $connection.Open()

    # List of tables to export
    $tables = @('CarMake', 'PartType', 'SystemCategory', 'CodeType', 'Code')

    foreach ($table in $tables) {
        Write-Host "Exporting table '$table'..."

        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "SELECT * FROM $table"

        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter $cmd
        $dataTable = New-Object System.Data.DataTable
        $adapter.Fill($dataTable) | Out-Null

        # Convert to JSON
        $json = $dataTable | ConvertTo-Json -Depth 5

        # Write to file
        $jsonPath = Join-Path $Path "$table.json"
        $json | Set-Content -Encoding UTF8 -Path $jsonPath

        Write-Host "Saved to $jsonPath"
    }

    $connection.Close()
    Write-Host "✅ All tables exported."



}

function Export-CodesFromDb {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Output directory for JSON files')]
        [string]$Path
    )

    [System.Collections.ArrayList]$List = [System.Collections.ArrayList]::new()

    [string]$DatabasePath = Get-DatabaseFilePath

    Write-Host "`n`n=====================================" -ForegroundColor DarkYellow
    Write-Host "Exporting 'Code' Table" -ForegroundColor DarkRed
    Write-Host "=====================================" -ForegroundColor DarkYellow

    # Connect to database
    $connectionString = "Data Source=$DatabasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection $connectionString
    $connection.Open()

    Write-Host "Exporting table 'Code'..."

    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "SELECT Id, DiagnosticCode, Description, CodeTypeId, SystemCategoryId, PartTypeId, CarMakeId, DetailsUrl FROM Code"

    $reader = $cmd.ExecuteReader()

    while ($reader.Read()) {
        $o = [PSCustomObject]@{
            Id               = $reader["Id"]
            DiagnosticCode   = $reader["DiagnosticCode"]
            Description      = $reader["Description"]
            CodeTypeId       = $reader["CodeTypeId"]
            SystemCategoryId = $reader["SystemCategoryId"]
            PartTypeId       = $reader["PartTypeId"]
            CarMakeId        = $reader["CarMakeId"]
            DetailsUrl       = $reader["DetailsUrl"]
        }
        [void]$List.Add($o)
    }

    $reader.Close()
    $connection.Close()

    Write-Host "Exported $($List.Count) entries." -ForegroundColor Green

    # Output to JSON
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }

    $json = $List | ConvertTo-Json -Depth 5
    $jsonPath = Join-Path $Path "Code.json"
    $json | Set-Content -Encoding UTF8 -Path $jsonPath

    Write-Host "Saved to $jsonPath"
}


function Update-CodesUrlInDb {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    [string]$DatabasePath = Get-DatabaseFilePath

    Write-Host "`n`n=====================================" -ForegroundColor DarkYellow
    Write-Host "Validating URLs for 'Code' Table" -ForegroundColor DarkRed
    Write-Host "=====================================" -ForegroundColor DarkYellow

    $connectionString = "Data Source=$DatabasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection $connectionString
    $connection.Open()

    # First, count total number of codes
    $countCmd = $connection.CreateCommand()
    $countCmd.CommandText = "SELECT COUNT(*) FROM Code"
    $total = $countCmd.ExecuteScalar()

    # Select all Ids and DiagnosticCodes
    $selectCmd = $connection.CreateCommand()
    $selectCmd.CommandText = "SELECT Id, DiagnosticCode FROM Code"
    $reader = $selectCmd.ExecuteReader()

    $current = 0
    while ($reader.Read()) {
        $current++
        $CodeId         = $reader["Id"]
        $DiagnosticCode = $reader["DiagnosticCode"]
        $Url            = "https://www.obd-codes.com/{0}" -f $DiagnosticCode

        Write-Progress -Activity "Checking Code URLs" `
                       -Status "Processing code ID $CodeId ($current of $total)" `
                       -PercentComplete (($current / $total) * 100)

        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -Method Head -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "[$CodeId] Valid URL: $Url" -ForegroundColor Green

                $updateCmd = $connection.CreateCommand()
                $updateCmd.CommandText = "UPDATE Code SET DetailsUrl = @url WHERE Id = @id"
                $updateCmd.Parameters.AddWithValue("@url", $Url) | Out-Null
                $updateCmd.Parameters.AddWithValue("@id", $CodeId) | Out-Null
                $updateCmd.ExecuteNonQuery() | Out-Null
            }
        } catch {
            Write-Host "[$CodeId] ERROR $_" -ForegroundColor DarkGray
        }
    }

    $reader.Close()
    $connection.Close()

    Write-Progress -Activity "Checking Code URLs" -Completed
    Write-Host "Update complete." -ForegroundColor Cyan
}


function Export-PartTypeDataDirect {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory = $true, HelpMessage = 'Output directory for JSON files')]
        [string]$Path
    )
    $PartTypeMap        = Get-PartTypeMap

    [System.Collections.ArrayList]$List = [System.Collections.ArrayList]::new()

    [enum]::GetValues([PartType]) | ForEach-Object {
        $PartType = $_.ToString()
        $DisplayName = Get-PartTypeDescription $_
        $FamilyLetter = $PartType.Substring(0, 1).ToUpper()
        if ($FamilyLetter -eq 'N') {
            $FamilyLetter = 'U'
        }
        $Id = $PartTypeMap[$PartType].Id

        [pscustomobject]$o = [pscustomobject]@{
            PartTypeId = $Id
            PartType = "$PartType"
            DisplayName = "$DisplayName"
            FamilyLetter = "$FamilyLetter"
        }
        [void]$List.Add($o)
    }
    $json = $List | ConvertTo-Json -Depth 5
    $jsonPath = Join-Path $Path "PartType.json"
    $json | Set-Content -Encoding UTF8 -Path $jsonPath

    Write-Host "Saved to $jsonPath"

}


function Export-SystemCategoryDataDirect {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory = $true, HelpMessage = 'Output directory for JSON files')]
        [string]$Path
    )
    $SystemCategoryMap  = Get-SystemCategoryMap

    [System.Collections.ArrayList]$List = [System.Collections.ArrayList]::new()

    [enum]::GetValues([SystemCategory]) | ForEach-Object {
        $CategoryName = $_.ToString()
        $Id =  $SystemCategoryMap[$CategoryName].Id
        $CategoryDesc = Get-SystemCategoryDescription $_

        [pscustomobject]$o = [pscustomobject]@{
            SystemCategoryId = $Id
            Name = "$CategoryName"
            DisplayName = "$CategoryDesc"
        }
        [void]$List.Add($o)
    }
    $json = $List | ConvertTo-Json -Depth 5
    $jsonPath = Join-Path $Path "SystemCategory.json"
    $json | Set-Content -Encoding UTF8 -Path $jsonPath

    Write-Host "Saved to $jsonPath"

}





function Export-CodeTypeDataDirect {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory = $true, HelpMessage = 'Output directory for JSON files')]
        [string]$Path
    )
    $CodeTypeMap        = Get-CodeTypeMap

    [System.Collections.ArrayList]$List = [System.Collections.ArrayList]::new()

    [enum]::GetValues([CodeType]) | ForEach-Object {
            
            $CodeTypeName = $_.ToString()
            $Id = $CodeTypeMap[$CodeTypeName].Id
            $CodeTypeDesc = Get-CodeTypeDescription $_

        [pscustomobject]$o = [pscustomobject]@{
            CodeTypeId = $Id
            Name = "$CodeTypeName"
            Description = "$CodeTypeDesc"
        }
        [void]$List.Add($o)
    }
    $json = $List | ConvertTo-Json -Depth 5
    $jsonPath = Join-Path $Path "CodeType.json"
    $json | Set-Content -Encoding UTF8 -Path $jsonPath

    Write-Host "Saved to $jsonPath"

}


function Export-CarMakeDataDirect {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory = $true, HelpMessage = 'Output directory for JSON files')]
        [string]$Path
    )
    $CarMakeMap         = Get-CarMakeMap

    [System.Collections.ArrayList]$List = [System.Collections.ArrayList]::new()

    $Makes = Get-AllCarMakes
    foreach ($m in $Makes) {
            
            $Name = $m.Name
            $Id = $CarMakeMap[$Name].Id
            $Description = $m.Description
        [pscustomobject]$o = [pscustomobject]@{
            CarMakeId = $Id
            Name = "$Name"
            Description = "$Description"
        }
        [void]$List.Add($o)
    }
    $json = $List | ConvertTo-Json -Depth 5
    $jsonPath = Join-Path $Path "CarMake.json"
    $json | Set-Content -Encoding UTF8 -Path $jsonPath

    Write-Host "Saved to $jsonPath"

}


Register-SqlLib

$ExportPath = Get-HtmlDataPath
Export-PartTypeDataDirect -Path "$ExportPath"
Export-SystemCategoryDataDirect -Path "$ExportPath"
Export-CodeTypeDataDirect -Path "$ExportPath"
Export-CarMakeDataDirect -Path "$ExportPath"
Export-CodesFromDb -Path "$ExportPath"
