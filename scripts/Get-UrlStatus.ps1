#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Get-CodesUrlStatus.ps1                                                       ║
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

function Get-CodesUrlStatus {
    [CmdletBinding()]
    param()

    Import-Module ThreadJob -ErrorAction SilentlyContinue

    [string]$DatabasePath = Get-DatabaseFilePath
    [System.Collections.Concurrent.ConcurrentQueue[object]]$Queue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

    Write-Host "`n`n=====================================" -ForegroundColor DarkYellow
    Write-Host "Validating URLs for 'Code' Table (Threaded Batches)" -ForegroundColor DarkRed
    Write-Host "=====================================" -ForegroundColor DarkYellow

    # Step 1: Load all codes from DB
    $connectionString = "Data Source=$DatabasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection $connectionString
    $connection.Open()

    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "SELECT Id, DiagnosticCode FROM Code"
    $reader = $cmd.ExecuteReader()

    $codeList = @()
    while ($reader.Read()) {
        $codeList += [PSCustomObject]@{
            Id             = $reader["Id"]
            DiagnosticCode = $reader["DiagnosticCode"]
        }
    }
    $reader.Close()
    $connection.Close()

    $batchSize = 500
    $total = $codeList.Count
    $batches = [math]::Ceiling($total / $batchSize)
    $counter = 0

    for ($i = 0; $i -lt $batches; $i++) {
        $batch = $codeList | Select-Object -Skip ($i * $batchSize) -First $batchSize
        $jobs = @()

        foreach ($code in $batch) {
            $jobs += Start-ThreadJob -ScriptBlock {
                param($id, $code, $queue)

                $url = "https://www.obd-codes.com/$code"
                $valid = $null

                try {
                    $resp = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
                    if ($resp.StatusCode -eq 200) {
                        $valid = $url
                    }
                } catch {}

                $queue.Enqueue([PSCustomObject]@{
                    Id  = $id
                    Url = $valid
                })

            } -ArgumentList $code.Id, $code.DiagnosticCode, $Queue
        }

        Write-Host "`n[Batch $($i + 1)/$batches] Started $($jobs.Count) jobs..." -ForegroundColor Cyan
        $jobs | Wait-Job

        foreach ($job in $jobs) {
            Receive-Job -Job $job | Out-Null
            Remove-Job $job
        }

        $counter += $jobs.Count
        Write-Progress -Activity "Validating URLs..." -Status "$counter of $total complete" -PercentComplete (($counter / $total) * 100)
    }

    Write-Progress -Activity "Validating URLs..." -Completed

    # Step 3: Collect results
    $codeTable = [ordered]@{}
    $item = $null
    while ($Queue.TryDequeue([ref]$item)) {
        $codeTable[$item.Id] = $item.Url
    }

    # Step 4: Save to JSON
    $JsonData = $codeTable | ConvertTo-Json -Depth 3
    Set-Content -Path "$PWD\UrlsStates.json" -Value $JsonData

    Write-Host "`n✅ URL validation complete. Results saved to UrlsStates.json." -ForegroundColor Green
}

Get-CodesUrlStatus