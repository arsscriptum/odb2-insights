#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   database.ps1                                                                 ║
#║                                                                                ║
#║   function to parse the site obd-codes.com                                     ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaumep  <guillaumep@luminator.com>                                       ║
#║   Copyright (C) Luminator Technology Group.  All rights reserved.              ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Write-DebugLog {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [Alias('f')]
        [ConsoleColor]$ForegroundColor = "White",

        [Parameter(Mandatory = $false)]
        [Alias('b')]
        [ConsoleColor]$BackgroundColor,

        [Parameter(Mandatory = $false)]
        [Alias('n')]
        [switch]$NoNewLine
    )

    begin {
        # Read the DebugLog environment variable
        $debugLogEnabled = $ENV:DebugLog -ne $false
    }

    process {
        if ($debugLogEnabled) {
            # Build Write-DebugLog command dynamically
            $params = @{ "Object" = $Message; "ForegroundColor" = $ForegroundColor }
            if ($PSBoundParameters.ContainsKey("BackgroundColor")) {
                $params["BackgroundColor"] = $BackgroundColor
            }
            if ($NoNewLine) {
                $params["NoNewLine"] = $true
            }

            Write-Host @params
        }
    }
}

function Write-DebugLogToFile {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [Alias('f')]
        [ConsoleColor]$ForegroundColor = "White",

        [Parameter(Mandatory = $false)]
        [Alias('b')]
        [ConsoleColor]$BackgroundColor,

        [Parameter(Mandatory = $false)]
        [Alias('n')]
        [switch]$NoNewLine
    )

    begin {
        # Determine log file path
        $logFile = "d:\Tmp\Logs\TestOpenPortChecks.log"
        if (!([string]::IsNullOrEmpty($ENV:DebugLogFilePath))) {
            $logFile = "$ENV:DebugLogFilePath"
        }

        if (!(Test-Path -Path "$logFile" -PathType Leaf)) {
            New-Item -Path "$logFile" -ItemType File -Force -ErrorAction Ignore | Out-Null
            [datetime]$StartTime = [datetime]::Now
            $StartimStr = $StartTime.GetDateTimeFormats()[23]
            $StartTimeStrLen = $StartimStr.Length
            $sep = [string]::new('=', $StartTimeStrLen)
            $LogHeader = @"
`n`n===================================================================
  ================== TEST STARTED AT $StartimStr =================
===================================================================
`n`n
"@
            Set-Content -Path $logFile -Value $LogHeader -Force
        }
        $debugLogToFileEnabled = $ENV:DebugLogToFile -ne $false
        $debugLogConsoleEnabled = $ENV:DebugLogToConsole -ne $false
    }

    process {
        if ($debugLogToFileEnabled) {
            # Format log message with timestamp
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] $Message"

            # Handle NoNewLine flag
            Add-Content -Path $logFile -Value $logEntry
        }
        if ($debugLogConsoleEnabled) {
            # Build Write-DebugLog command dynamically
            $params = @{ "Object" = $Message; "ForegroundColor" = $ForegroundColor }
            if ($PSBoundParameters.ContainsKey("BackgroundColor")) {
                $params["BackgroundColor"] = $BackgroundColor
            }
            if ($NoNewLine) {
                $params["NoNewLine"] = $true
            }

            Write-Host @params
        }
    }
}


function Write-DebugDbCommand {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Statement,
        [Parameter(Position = 1, Mandatory = $true)]
        [System.Data.Common.DbCommand]$Command,
        [Parameter(Position = 2, Mandatory = $false)]
        [string]$TableName
    )

    begin {
        # Read the DebugLog environment variable
        $debugLogEnabled = $ENV:DebugLog -ne $false
        $tname = 'table'
        if ($TableName) {
            $tname = $TableName
        }

    }

    process {
        if ($debugLogEnabled) {
            $lt1 = ''
            $lt2 = ''

            $insertCommand.Parameters | % {
                $n = $_.ParameterName.TrimStart('@')
                $v = $_.Value
                $lt1 += "$n "
                $lt2 += "$v "
            }
            $lt1 = $lt1.TrimEnd(', ')
            $lt2 = $lt2.TrimEnd(', ')
            Write-DebugLog "`n$Statement $TableName ($lt1) VALUES ($lt2)`n" -f DarkMagenta

        }
    }
}


function Write-SqlScriptStats {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path -Path "$_" -PathType Leaf })]
        [string]$Path
    )

    try {
        [string[]]$Statements = @(
            "CREATE TABLE", "INSERT INTO", "DROP TABLE", "CREATE INDEX",
            "ALTER TABLE", "CREATE VIEW", "DROP VIEW", "CREATE TRIGGER", "DROP TRIGGER",
            "CREATE FUNCTION", "DROP FUNCTION", "CREATE PROCEDURE", "DROP PROCEDURE",
            "UPDATE", "DELETE FROM", "SELECT",
            "ANALYZE", "VACUUM", "REINDEX",
            "BEGIN TRANSACTION", "COMMIT", "ROLLBACK"
        )
        $l = $Path.Length + 19
        $sep = [string]::new('=', $l)

        Write-DebugLog "$sep" -f DarkGray
        Write-DebugLog " Sql Script Stats $Path" -f White
        Write-DebugLog "$sep" -f DarkGray
        $File = Get-Item $Path
        $FileSize = $File.Length
        $log = "{0} bytes`tFile Size" -f $FileSize

        Write-DebugLog "$log" -f Cyan

        foreach ($st in $Statements) {
            $matchArray = Select-String -Path $Path -Pattern "$st"
            $matchCount = $matchArray.Count
            if ($matchCount -gt 0) {
                $log = "{0}`t`t{1}" -f $matchCount, "`"$st`""
                Write-DebugLog "$log" -f DarkCyan
            }
        }
        Write-DebugLog "$sep" -f DarkGray
    }
    catch {
        Write-Error "An error occurred in Write-SqlScriptStats: $_"
        throw "Error in Write-SqlScriptStats function."
    }
}

function Invoke-ExecuteSqlScript {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path -Path "$_" -PathType Leaf })]
        [string]$Path
    )

    try {
        # Load the SQLite assembly using Add-SqlLiteTypes function

        [int]$AffectedRows = 0


        # Create and open the SQLite connection

        $databasePath = Get-DatabaseFilePath
        $connectionString = "Data Source=$databasePath;Version=3;"
        $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
        $connection.Open()

        try {
            $Size = (Get-Item -Path "$Path").Length
            Write-SqlScriptStats $Path
            Write-DebugLog "Invoke-ExecuteSqlScript `"$Path`"" -f Blue
            # SQL command to create the schema_version table if it doesn't exist
            $sqlScriptContent = Get-Content -Path "$Path" -Raw
            # Execute the SQL command to create the table
            $command = $connection.CreateCommand()
            $command.CommandText = $sqlScriptContent
            $AffectedRows = $command.ExecuteNonQuery()

        }

        catch {
            Write-Error "An error occurred while adding the version table: $_"
            throw "Error executing SQL commands. Please verify the database connection and SQL syntax."
        }
        finally {
            # Close the connection
            if ($connection.State -eq 'Open') {
                $connection.Close()
            }
            $connection.Dispose()
        }
        return $AffectedRows
    }
    catch {
        Show-ExceptionDetails ($_) -ShowStack
    }

}

function New-Odb2Tables {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ReplaceOnError
    )
    $Script = Join-Path (Get-ScriptsSqlPath) "create_tables.sql"
    try {
        Invoke-ExecuteSqlScript $Script
    } catch {
        Write-Host "$_"
        return $false
    }
    return $true
}

function Add-CarMakesInTable {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ReplaceOnError
    )

    # Connect to the SQLite database
    $databasePath = Get-DatabaseFilePath
    $connectionString = "Data Source=$databasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
    $connection.Open()
    try {
        $Makes = Get-AllCarMakes
        foreach ($m in $Makes) {
            $Name = $m.Name
            $Description = $m.Description
            $InsertStatement = 'INSERT INTO'
            if ($ReplaceOnError) { $InsertStatement = 'INSERT OR REPLACE INTO' }

            $FullCommand = "{0} CarMake (Name, DisplayName) VALUES (@Name, @DisplayName)" -f $InsertStatement


            # Step 3: Insert into SpeedTestResult table
            $insertCommand = $connection.CreateCommand()
            $insertCommand.CommandText = $FullCommand

            $insertCommand.Parameters.AddWithValue("@Name", $Name) | Out-Null
            $insertCommand.Parameters.AddWithValue("@DisplayName", $Description) | Out-Null

            $insertCommand.ExecuteNonQuery() | Out-Null

            Write-Host -n "Inserted: " -f DarkGray
            Write-Host "$Name → $Description" -f Blue
        }



        return $True


    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    }
    finally {
        $connection.Close()
    }
}


function Add-PartTypesInTable {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Use INSERT OR REPLACE instead of INSERT")]
        [switch]$ReplaceOnError
    )

    # Connect to the SQLite database
    $databasePath = Get-DatabaseFilePath
    $connectionString = "Data Source=$databasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
    $connection.Open()

    try {
        [enum]::GetValues([PartType]) | ForEach-Object {
            $PartType = $_.ToString()
            $DisplayName = Get-PartTypeDescription $_
            $FamilyLetter = $PartType.Substring(0, 1).ToUpper()
            if ($FamilyLetter -eq 'N') {
                $FamilyLetter = 'U'
            }

            $InsertStatement = if ($ReplaceOnError) {
                'INSERT OR REPLACE INTO'
            } else {
                'INSERT INTO'
            }

            $Sql = "$InsertStatement PartType (Name, DisplayName, FamilyLetter) VALUES (@Name, @DisplayName, @FamilyLetter)"

            $cmd = $connection.CreateCommand()
            $cmd.CommandText = $Sql
            $cmd.Parameters.AddWithValue("@Name", $PartType) | Out-Null
            $cmd.Parameters.AddWithValue("@DisplayName", $DisplayName) | Out-Null
            $cmd.Parameters.AddWithValue("@FamilyLetter", $FamilyLetter) | Out-Null

            $cmd.ExecuteNonQuery() | Out-Null
            Write-Host -n "Inserted: " -f DarkGray
            Write-Host "$PartType → $DisplayName ($FamilyLetter)" -f DarkMagenta

        }

        return $true
    } catch {
        Show-ExceptionDetails $_ -ShowStack
    } finally {
        $connection.Close()
    }
}


function Add-SystemCategoriesInTable {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Use INSERT OR REPLACE instead of INSERT")]
        [switch]$ReplaceOnError
    )

    # Connect to the SQLite database
    $databasePath = Get-DatabaseFilePath
    $connectionString = "Data Source=$databasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
    $connection.Open()

    try {
        [enum]::GetValues([SystemCategory]) | ForEach-Object {
            $CategoryName = $_.ToString()
            $CategoryDesc = Get-SystemCategoryDescription $_

            $InsertStatement = if ($ReplaceOnError) {
                'INSERT OR REPLACE INTO'
            } else {
                'INSERT INTO'
            }

            $Sql = "$InsertStatement SystemCategory (Name, DisplayName) VALUES (@Name, @DisplayName)"

            $cmd = $connection.CreateCommand()
            $cmd.CommandText = $Sql
            $cmd.Parameters.AddWithValue("@Name", $CategoryName) | Out-Null
            $cmd.Parameters.AddWithValue("@DisplayName", $CategoryDesc) | Out-Null

            $cmd.ExecuteNonQuery() | Out-Null
            Write-Host -n "Inserted: " -f DarkGray
            Write-Host "$CategoryName → $CategoryDesc" -f DarkBlue

        }

        return $true
    } catch {
        Show-ExceptionDetails $_ -ShowStack
    } finally {
        $connection.Close()
    }
}

function Add-CodeTypesInTable {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Use INSERT OR REPLACE instead of INSERT")]
        [switch]$ReplaceOnError
    )

    # Connect to the SQLite database
    $databasePath = Get-DatabaseFilePath
    $connectionString = "Data Source=$databasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
    $connection.Open()

    try {
        [enum]::GetValues([CodeType]) | ForEach-Object {
            $CodeTypeName = $_.ToString()
            $CodeTypeDesc = Get-CodeTypeDescription $_

            $InsertStatement = if ($ReplaceOnError) {
                'INSERT OR REPLACE INTO'
            } else {
                'INSERT INTO'
            }

            $Sql = "$InsertStatement CodeType (Name, Description) VALUES (@Name, @Description)"

            $cmd = $connection.CreateCommand()
            $cmd.CommandText = $Sql
            $cmd.Parameters.AddWithValue("@Name", $CodeTypeName) | Out-Null
            $cmd.Parameters.AddWithValue("@Description", $CodeTypeDesc) | Out-Null

            $cmd.ExecuteNonQuery() | Out-Null

            Write-Host -n "Inserted: " -f DarkGray
            Write-Host "$CodeTypeName → $CodeTypeDesc" -f DarkCyan
        }

        return $true
    } catch {
        Show-ExceptionDetails $_ -ShowStack
    } finally {
        $connection.Close()
    }
}

function Insert-Batch {
    param(
        [Parameter(Mandatory = $true)]
        [System.Data.SQLite.SQLiteConnection]$Connection,

        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Rows
    )

    if (-not $Rows.Count) { return }

    $sb = New-Object System.Text.StringBuilder
    $sb.Append("INSERT OR IGNORE INTO Code (DiagnosticCode, Description, CodeTypeId, SystemCategoryId, PartTypeId, CarMakeId) VALUES ") | Out-Null

    $cmd = $Connection.CreateCommand()
    $paramIndex = 0

    foreach ($row in $Rows) {
        $paramSet = @(
            "@code$paramIndex", "@desc$paramIndex", "@ctype$paramIndex",
            "@scat$paramIndex", "@ptype$paramIndex", "@cmake$paramIndex"
        )

        $sb.Append("(" + ($paramSet -join ", ") + "),") | Out-Null

        $cmd.Parameters.AddWithValue($paramSet[0], $row.Code) | Out-Null
        $cmd.Parameters.AddWithValue($paramSet[1], $row.Description) | Out-Null
        $cmd.Parameters.AddWithValue($paramSet[2], $row.CodeTypeId) | Out-Null
        $cmd.Parameters.AddWithValue($paramSet[3], $row.SystemCategory) | Out-Null
        $cmd.Parameters.AddWithValue($paramSet[4], $row.PartTypeId) | Out-Null
        $cmd.Parameters.AddWithValue($paramSet[5], $row.CarMakeId) | Out-Null

        $paramIndex++
    }

    # Trim trailing comma
    $cmd.CommandText = $sb.ToString().TrimEnd(',')

    $cmd.ExecuteNonQuery() | Out-Null

    Write-Host "Inserted batch of $paramIndex codes."
}

function Add-KellyBlueBookCodesInTable {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$InsertBatchSize = 300
    )

    [int]$CarMakeId = 0
    $CodeTable = Get-KellyBlueBookCodesTable

    # Get all maps inside the function
    $PartTypeMap = Get-PartTypeMap
    $CodeTypeMap = Get-CodeTypeMap
    $SystemCategoryMap = Get-SystemCategoryMap


    $dbPath = Get-DatabaseFilePath
    $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath;Version=3;")
    $conn.Open()

    try {
        $batch = @()
        foreach ($codeId in $CodeTable.Keys) {
            $description = $CodeTable[$codeId]
            $parsed = Resolve-ObdCode -Code $codeId

            $PartId = $PartTypeMap[$parsed.Part].Id
            $CodeTypeId = $CodeTypeMap[$parsed.CodeType].Id
            $SystemCatId = $SystemCategoryMap[$parsed.SystemCategory].Id

            $row = [pscustomobject]@{
                Code = $codeId
                Description = $description
                CodeTypeId = $CodeTypeId
                SystemCategory = $SystemCatId
                PartTypeId = $PartId
                CarMakeId = $CarMakeId
            }

            $batch += $row

            if ($batch.Count -ge $InsertBatchSize) {
                Insert-Batch -Connection $conn -Rows $batch
                $batch = @()
            }
        }

        # Insert remaining
        if ($batch.Count -gt 0) {
            Insert-Batch -Connection $conn -Rows $batch
        }

        return $true
    } catch {
        Show-ExceptionDetails $_ -ShowStack
    } finally {
        $conn.Close()
    }
}


function Add-CodesListInTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,Position=0)]
        [system.Collections.ArrayList]$List,
        [Parameter(Mandatory = $false)]
        [int]$InsertBatchSize = 300
    )

    [int]$CarMakeId = 0

    # Get all maps inside the function
    $PartTypeMap = Get-PartTypeMap
    $CodeTypeMap = Get-CodeTypeMap
    $SystemCategoryMap = Get-SystemCategoryMap


    $dbPath = Get-DatabaseFilePath
    $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath;Version=3;")
    $conn.Open()

    try {
        $batch = @()
        foreach ($item in $List) {
            $codeId = $item.Code.ToUpper()
            $description = $item.Description
            $parsed = Resolve-ObdCode -Code $codeId

            $PartId = $PartTypeMap[$parsed.Part].Id
            $CodeTypeId = $CodeTypeMap[$parsed.CodeType].Id
            $SystemCatId = $SystemCategoryMap[$parsed.SystemCategory].Id

            $row = [pscustomobject]@{
                Code = $codeId
                Description = $description
                CodeTypeId = $CodeTypeId
                SystemCategory = $SystemCatId
                PartTypeId = $PartId
                CarMakeId = $CarMakeId
            }

            $batch += $row

            if ($batch.Count -ge $InsertBatchSize) {
                Insert-Batch -Connection $conn -Rows $batch
                $batch = @()
            }
        }

        # Insert remaining
        if ($batch.Count -gt 0) {
            Insert-Batch -Connection $conn -Rows $batch
        }

        return $true
    } catch {
        Show-ExceptionDetails $_ -ShowStack
    } finally {
        $conn.Close()
    }
}

function Add-AllGenericCodeLists{
    $GenericBodyCodes = Get-GenericBodyCodes
    $GenericChassisCodes=Get-GenericChassisCodes
    $GenericPowertrainCodes=Get-GenericPowertrainCodes
    $GenericNetworkCodes=Get-GenericNetworkCodes
    $ret = $True
    Write-Host "Insert Generic Body Codes... $ret" -f DarkYellow
    $ret = $ret -and (Add-CodesListInTable $GenericBodyCodes)
    Write-Host "Insert Generic Chassis Codes... $ret" -f DarkYellow
    $ret = $ret -and (Add-CodesListInTable $GenericChassisCodes)
    Write-Host "Insert Generic PowerTrain Codes...$ret" -f DarkYellow
    $ret = $ret -and (Add-CodesListInTable $GenericPowertrainCodes)
    Write-Host "Insert Generic Network Codes...$ret" -f DarkYellow
    $ret = $ret -and (Add-CodesListInTable $GenericNetworkCodes)
    $ret
}

function Get-CarMakeMap {
    $dbPath = Get-DatabaseFilePath
    $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath;Version=3;")
    $conn.Open()

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = 'SELECT CarMakeId, Name FROM CarMake'
    $reader = $cmd.ExecuteReader()

    $map = @{}
    while ($reader.Read()) {
        $name = $reader["Name"]
        $id = $reader["CarMakeId"]
        $map[$name] = [pscustomobject]@{
            Name = $name
            Id = $id
        }
    }

    $reader.Close()
    $conn.Close()
    return $map
}


function Get-PartTypeMap {
    $dbPath = Get-DatabaseFilePath
    $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath;Version=3;")
    $conn.Open()

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = 'SELECT PartTypeId, Name FROM PartType'
    $reader = $cmd.ExecuteReader()

    $map = @{}
    while ($reader.Read()) {
        $name = $reader["Name"]
        $id = $reader["PartTypeId"]
        $map[$name] = [pscustomobject]@{
            Name = $name
            Id = $id
        }
    }

    $reader.Close()
    $conn.Close()
    return $map
}


function Get-CodeTypeMap {
    $dbPath = Get-DatabaseFilePath
    $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath;Version=3;")
    $conn.Open()

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = 'SELECT CodeTypeId, Name FROM CodeType'
    $reader = $cmd.ExecuteReader()

    $map = @{}
    while ($reader.Read()) {
        $name = $reader["Name"]
        $id = $reader["CodeTypeId"]
        $map[$name] = [pscustomobject]@{
            Name = $name
            Id = $id
        }
    }

    $reader.Close()
    $conn.Close()
    return $map
}

function Get-SystemCategoryMap {
    $dbPath = Get-DatabaseFilePath
    $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath;Version=3;")
    $conn.Open()

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = 'SELECT SystemCategoryId, Name FROM SystemCategory'
    $reader = $cmd.ExecuteReader()

    $map = @{}
    while ($reader.Read()) {
        $name = $reader["Name"]
        $id = $reader["SystemCategoryId"]
        $map[$name] = [pscustomobject]@{
            Name = $name
            Id = $id
        }
    }

    $reader.Close()
    $conn.Close()
    return $map
}

function Get-CodesWithNonNullUrl {
    $dbPath = Get-DatabaseFilePath
    $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath;Version=3;")
    $conn.Open()

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = 'SELECT Id,DiagnosticCode,DetailsUrl FROM Code Where DetailsUrl is NOT Null'
    $reader = $cmd.ExecuteReader()

    [System.Collections.ArrayList]$List = [System.Collections.ArrayList]::new()
    while ($reader.Read()) {
        $Id = $reader["Id"]
        $DiagnosticCode = $reader["DiagnosticCode"]
        $DetailsUrl  = $reader["DetailsUrl"]
        [pscustomobject]$o = [pscustomobject]@{
            Id = $Id
            DiagnosticCode = $DiagnosticCode
            DetailsUrl = $DetailsUrl
        }
        [void]$List.Add($o)
    }

    $reader.Close()
    $conn.Close()
    return $List 
}


function update-CodesUrlInDb {
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
            Write-Host "[$CodeId] Invalid URL: $Url" -ForegroundColor DarkGray
        }
    }

    $reader.Close()
    $connection.Close()

    Write-Progress -Activity "Checking Code URLs" -Completed
    Write-Host "Update complete." -ForegroundColor Cyan
}


function Add-ManufacturerSpecificCodes {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [int]$InsertBatchSize = 300
    )

    $CarMakeMap         = Get-CarMakeMap
    $PartTypeMap        = Get-PartTypeMap
    $CodeTypeMap        = Get-CodeTypeMap
    $SystemCategoryMap  = Get-SystemCategoryMap

    try {
        $BackupPath = Join-Path "$PSScriptRoot" "ManufacturerSpecificCodes"
        if (!(Test-Path $BackupPath)) {
            [void](New-Item -ItemType Directory -Path $BackupPath)
        }

        $dbPath = Get-DatabaseFilePath
        $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath;Version=3;")
        $conn.Open()

        [string[]]$AllMakes = @(
            "acura", "audi", "bmw", "chevrolet", "dodge", "ford", "honda", "hyundai",
            "infiniti", "isuzu", "jaguar", "kia", "lexus", "mazda", "mitsubishi",
            "nissan", "subaru", "toyota", "volkswagen","landrover"
        )

        foreach ($make in $AllMakes) {
            $batch = @()
            $SpecificCodes = Get-ManufacturerSpecificCodes $make

            if (-not $SpecificCodes) {
                Write-Warning "No codes found for '$make'. Skipping..."
                continue
            }

            if (-not $CarMakeMap.ContainsKey($make)) {
                Write-Warning "CarMake '$make' not found in CarMakeMap. Skipping..."
                continue
            }

            $CarMakeId = $CarMakeMap[$make].Id
            Write-Host "Inserting codes for '$make' (CarMakeId = $CarMakeId)..."

            foreach ($c in $SpecificCodes) {
                try {
                    $codeId = $c.Code
                    $description = $c.Description
                    $parsed = Resolve-ObdCode -Code $codeId

                    if ($parsed.CodeType -ne 'ManufacturerSpecific') {
                        Write-Warning "Skipping non-manufacturer-specific code: $codeId"
                        continue
                    }

                    $PartId      = $PartTypeMap[$parsed.Part].Id
                    $CodeTypeId  = $CodeTypeMap[$parsed.CodeType].Id
                    $SystemCatId = $SystemCategoryMap[$parsed.SystemCategory].Id

                    $row = [pscustomobject]@{
                        Code           = $codeId
                        Description    = $description
                        CodeTypeId     = $CodeTypeId
                        SystemCategory = $SystemCatId
                        PartTypeId     = $PartId
                        CarMakeId      = $CarMakeId
                    }

                    $batch += $row

                    if ($batch.Count -ge $InsertBatchSize) {
                        Insert-Batch -Connection $conn -Rows $batch
                        $batch = @()
                    }
                } catch {
                    Write-Warning "Error parsing/inserting code '$($c.Code)': $_"
                    continue
                }
            }

            if ($batch.Count -gt 0) {
                Insert-Batch -Connection $conn -Rows $batch
            }

            # Optional backup
            $backupFile = Join-Path $BackupPath "$make.json"
            $SpecificCodes | ConvertTo-Json -Depth 4 | Out-File $backupFile -Encoding UTF8
        }
        return $True

    } catch {
        Show-ExceptionDetails $_ -ShowStack
        return $False
    } finally {
        if ($conn.State -eq 'Open') { $conn.Close() }
    }
}

