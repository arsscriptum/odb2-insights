#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║    Import-OnlineOdb2Data.ps1                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝




[CmdletBinding(SupportsShouldProcess)]
param()

# ======================================================================
# Register-HtmlAgilityPack
# ======================================================================


function Register-HtmlAgilityPack {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Path
    )
    begin {
        if ([string]::IsNullOrEmpty($Path)) {
            $Path = "{0}\lib\{1}\HtmlAgilityPack.dll" -f "$PSScriptRoot", "$($PSVersionTable.PSEdition)"
        }
    }
    process {
        try {
            if (-not (Test-Path -Path "$Path" -PathType Leaf)) { throw "no such file `"$Path`"" }
            if (!("HtmlAgilityPack.HtmlDocument" -as [type])) {
                Write-Verbose "Registering HtmlAgilityPack... "
                add-type -Path "$Path"
            } else {
                Write-Verbose "HtmlAgilityPack already registered "
            }
        } catch {
            throw $_
        }
    }
}

# ======================================================================
# Get-ManufacturerCodeUrl
# ======================================================================

function Get-ManufacturerCodeUrl {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("acura", "audi", "bmw", "chevrolet", "dodge", "ford", "honda", "hyundai", "infiniti", "isuzu", "jaguar", "kia", "landrover", "lexus", "mazda", "mitsubishi", "nissan", "subaru", "toyota", "volkswagen")]
        [string]$CarMake
    )

    $SubPath = "/trouble_codes/{0}/" -f $CarMake
    $Url = "https://www.obd-codes.com/{0}" -f $SubPath
    $result = [pscustomobject]@{
        SubPath = $SubPath
        Url = $Url
    }

    return $result
}


# ======================================================================
# Get-ManufacturerSpecificCodes
# ======================================================================


function Get-ManufacturerSpecificCodes {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("acura", "audi", "bmw", "chevrolet", "dodge", "ford", "honda", "hyundai", "infiniti", "isuzu", "jaguar", "kia", "landrover", "lexus", "mazda", "mitsubishi", "nissan", "subaru", "toyota", "volkswagen")]
        [string]$CarMake
    )

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Obj = Get-ManufacturerCodeUrl $CarMake

        $Url = $Obj.Url
        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "$($Obj.SubPath)"
            "scheme" = "https"
            "accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "priority" = "u=0, i"
            "referer" = "https://www.obd-codes.com/trouble_codes/"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        $Valid = $True
        $Id = 2
        while ($Valid) {
            try {
                $XPathDesc = "/html[1]/body[1]/div[1]/div[2]/table[1]/tr[{0}]" -f $Id
                $XPathCode = "/html[1]/body[1]/div[1]/div[2]/table[1]/tr[{0}]/td" -f $Id

                $XPathDesc2 = '/html/body/div/div[2]/table/tbody/tr[{0}]/td[2]' -f $Id

                $ResultNodeDesc = $HtmlNode.SelectSingleNode($XPathDesc)
                $ResultNodeCode = $HtmlNode.SelectSingleNode($XPathCode)
                Write-Verbose "Id = $Id"

                if (!$ResultNodeCode) {
                    Write-Verbose "EMPTY"
                    $Valid = $False
                    break;
                }

                [string]$Code = $ResultNodeCode.InnerText.Trim()
                [string]$Desc = $ResultNodeDesc.InnerText.Trim().TrimStart($Code).Trim()
                $Desc = [System.Net.WebUtility]::HtmlDecode($Desc)

                $l = $Code.Length
                if ($l -gt 5) {
                    $Code = $Code.SubString(0, 5)
                }
                [pscustomobject]$o = [pscustomobject]@{
                    Code = "$Code"
                    Description = "$Desc"
                }
                $Id++
                Write-Verbose "ok"
                [void]$ParsedList.Add($o)
            } catch {
                Write-Verbose "$_"
                continue;
            }

        }
        if ($Json) {
            $ParsedList | ConvertTo-Json
        } else {
            return $ParsedList
        }


    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}


# ======================================================================
# Export-ManufacturerSpecificCodesJson
# ======================================================================


function Export-ManufacturerSpecificCodesJson {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $BackupPath = Join-Path "$PSScriptRoot" "ManufacturerSpecificCodes"
    if (![System.IO.Directory]::Exists($BackupPath)) { $Null = [System.IO.Directory]::CreateDirectory($BackupPath) }

    [string[]]$AllMakes = "acura", "audi", "bmw", "chevrolet", "dodge", "ford", "honda", "hyundai", "infiniti", "isuzu", "jaguar", "kia", "landrover", "lexus", "mazda", "mitsubishi", "nissan", "subaru", "toyota", "volkswagen"
    foreach ($make in $AllMakes) {
        $Name = '{0}.json' -f $make
        $JsonData = Get-ManufacturerSpecificCodes $make | ConvertTo-Json
        $CarMakeJson = Join-Path "$BackupPath" "$Name"
        $JsonData | Set-Content -Path $CarMakeJson
        Write-Host "Wrote $Name"
    }
}

function Get-AllCarMakes {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Path
    )

    $FilePath = Get-CarMakeListJsonPath
    $JsonData = Get-Content -Path $FilePath | ConvertFrom-Json
    $JsonData
}


# ======================================================================
# Update-CarMakeList
# ======================================================================


function Get-CarMakeList {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Url = "https://www.obd-codes.com/trouble_codes/"
        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "/trouble_codes/"
            "scheme" = "https"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "priority" = "u=0, i"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        [System.Collections.ArrayList]$MakesList = [System.Collections.ArrayList]::new()
        [pscustomobject]$undef = [pscustomobject]@{
            Name = "none"
            Description = "UNDEFINED"
        }
        [void]$MakesList.Add($undef)
        for ($x = 1; $x -lt 6; $x++) {
            for ($y = 1; $y -lt 6; $y++) {
                try {
                    $XPath = "/html/body/div/div[2]/div[3]/div[{0}]/ul/li[{1}]/a" -f $x, $y
                    $ResultNodeDesc = $HtmlNode.SelectSingleNode($XPath)

                    if (!$ResultNodeDesc) {
                        Write-Verbose "[$x,$y] EMPTY"
                        continue;
                    }

                    [string]$CarMake = $ResultNodeDesc.InnerText
                    Write-Verbose "[$x,$y] FOUND $CarMake"
                    [void]$ParsedList.Add($CarMake)
                } catch {
                    Write-Verbose "$_"
                    continue;
                }
            }
        }

        foreach ($item in $ParsedList) {
            $name = $item.Replace(' ', '_').Replace('/', '').Replace('__', '_').ToLower()
            $desc = $item
            if ($name.StartsWith('dodge')) {
                $name = 'dodge'
            }
            if ($name.StartsWith('vw')) {
                $name = 'volkswagen'
                $desc = 'Volkswagen'
            }
            if ($name.StartsWith('land_rover')) {
                $name = 'landrover'
            }


            [pscustomobject]$o = [pscustomobject]@{
                Name = "$name"
                Description = "$desc"
            }
            [void]$MakesList.Add($o)
        }

        $MakesList
    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}


function Update-CarMakeList {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    try {

        [System.Collections.ArrayList]$CarMakeList = Get-CarMakeList
        $JsonValues = $CarMakeList | ConvertTo-Json

        New-Item -Path "$Path" -ItemType File -Force -ErrorAction Stop -Value $JsonValues

        $List = $JsonValues | ConvertFrom-JSon
        $List
    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}


# ======================================================================
# Get-GenericPowertrainCodesUrls
# ======================================================================


function Get-GenericPowertrainCodesUrls {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Url = "https://www.obd-codes.com/p00-codes"
        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "/p00-codes"
            "scheme" = "https"
            "accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "priority" = "u=0, i"
            "referer" = "https://www.obd-codes.com/p01-codes"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        $Valid = $True
        $Id = 1
        while ($Valid) {
            try {
                $XPathLinks = "/html/body/div/div[2]/p[3]/a[{0}]" -f $Id
                $Id++

                $ResultNodeLinks = $HtmlNode.SelectSingleNode($XPathLinks)

                if (!$ResultNodeLinks) {
                    Write-Verbose "EMPTY"
                    $Valid = $False
                    break;
                }

                $TagEnd = '">{0}</a>' -f $ResultNodeLinks.InnerHtml
                $UrlSuffix = $ResultNodeLinks.OuterHtml.TrimStart('<a href="').TrimEnd($TagEnd)

                $CodesUrl = 'https://www.obd-codes.com{0}' -f $UrlSuffix
                [void]$ParsedList.Add($CodesUrl)
            } catch {
                Write-Verbose "$_"
                continue;
            }

        }

        return $ParsedList
    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}

# ======================================================================
# Get-GenericBodyCodesUrls
# ======================================================================


function Get-GenericBodyCodesUrls {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Url = "https://www.obd-codes.com/body-codes"
        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "/body-codes"
            "scheme" = "https"
            "accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "priority" = "u=0, i"
            "referer" = "https://www.obd-codes.com/body-codes"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        $Valid = $True
        $Id = 1
        while ($Valid) {
            try {
                $XPathLinks = "/html/body/div/div[2]/p[3]/a[{0}]" -f $Id
                $Id++

                $ResultNodeLinks = $HtmlNode.SelectSingleNode($XPathLinks)

                if (!$ResultNodeLinks) {
                    Write-Verbose "EMPTY"
                    $Valid = $False
                    break;
                }

                $CodeValue = $ResultNodeLinks.InnerText
                $CodeUrlSuffix = $ResultNodeLinks.Attributes[0].Value

                $CodesUrl = 'https://www.obd-codes.com{0}' -f $CodeUrlSuffix
                [void]$ParsedList.Add($CodesUrl)

            } catch {
                Write-Verbose "$_"
                continue;
            }

        }

        return $ParsedList
    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}

# ======================================================================
# Get-Obd2CodeRange
# ======================================================================


function Get-Obd2CodeRange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidatePattern('^[PpBbCcUu][0-3][0-9A-Ca-c][0-9A-Fa-f]{2}$')]
        [string]$StartCode,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidatePattern('^[PpBbCcUu][0-3][0-9A-Ca-c][0-9A-Fa-f]{2}$')]
        [string]$EndCode
    )
    $StartCodeCat = $StartCode.SubString(0,1)
    $EndCodeCat = $EndCode.SubString(0,1)
    if($StartCodeCat -ne $EndCodeCat){throw "must be tghe same type"}

    # Strip the leading 'P' and convert hex to decimal
    $startHex = $StartCode.SubString(1)
    $endHex = $EndCode.SubString(1)

    $startInt = [Convert]::ToInt32($startHex, 16)
    $endInt = [Convert]::ToInt32($endHex, 16)

    if ($startInt -gt $endInt) {
        throw "StartCode must be less than or equal to EndCode"
    }

    # Generate codes
    for ($i = $startInt; $i -le $endInt; $i++) {
        '{0}{1:X4}' -f $StartCodeCat, $i
    }
}



# ======================================================================
# Get-GenericBodyCodeDescriptionFromUrl
# ======================================================================

function Get-GenericBodyCodeDescriptionFromUrl {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$UrlSuffix
    )

    try {
        $FullUrl = "https://www.obd-codes.com{0}" -f $UrlSuffix

        $Ret = $False

        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "$UrlSuffix"
            "scheme" = "https"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "referer" = "https://www.obd-codes.com/body-codes"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $FullUrl -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        $XPathLinks = "/html/body/div/div[2]/p[1]"


        $ResultNodeLinks = $HtmlNode.SelectSingleNode($XPathLinks)

        if (!$ResultNodeLinks) {
            return ""
        }

        $CodeDesc = $ResultNodeLinks.InnerText
        return $CodeDesc

    } catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}
# ======================================================================
# Get-GenericBodyCodes
# ======================================================================


function Get-GenericBodyCodes {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Url = "https://www.obd-codes.com/body-codes"
        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "/body-codes"
            "scheme" = "https"
            "accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "priority" = "u=0, i"
            "referer" = "https://www.obd-codes.com/body-codes"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        $Valid = $True
        $Id = 1
        Write-Host "Fetching Description for Body Codes..." -f DarkCyan
        while ($Valid) {
            try {
                $XPathLinks = "/html/body/div/div[2]/p[3]/a[{0}]" -f $Id
                $Id++

                $ResultNodeLinks = $HtmlNode.SelectSingleNode($XPathLinks)

                if (!$ResultNodeLinks) {
                    Write-Verbose "EMPTY"
                    $Valid = $False
                    break;
                }

                $CodeValue = $ResultNodeLinks.InnerText
                $CodeUrlSuffix = $ResultNodeLinks.Attributes[0].Value
                Write-Host -n " -> $CodeValue" -f DarkYellow


                $CodesUrl = 'https://www.obd-codes.com{0}' -f $CodeUrlSuffix
                $BodyCodeDescription = Get-GenericBodyCodeDescriptionFromUrl $CodeUrlSuffix

                [pscustomobject]$o = [pscustomobject]@{
                    Code = "$CodeValue"
                    Description = $BodyCodeDescription
                    Url = "$CodesUrl"
                    Type = 'Body'
                }
                [void]$ParsedList.Add($o)
                Write-Host "OK" -f DarkGreen
            } catch {
                Write-Verbose "$_"
                continue;
            }

        }

        return $ParsedList
    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}




# ======================================================================
# TryParseErrorCode
# ======================================================================



function TryParseErrorCode {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $True)]
        [string]$String
    )
    process {
        try {
            $TmpString = $String.Trim()
            [regex]$pattern = '^[PpBbCcUu][0-3][0-9A-Ca-c][0-9A-Fa-f]{2}'

            $TryCode = $TmpString.SubString(0, 5)
            if ($pattern.Match($TryCode).Success) {
                $Code = $TryCode
                [pscustomobject]$o = [pscustomobject]@{
                    Code = $Code
                    Description = $TmpString.SubString(5).Trim()
                    Success = $True
                }
                return $o
            } elseif ($pattern.Match($TmpString).Success) {
                $Code = $pattern.Match($TmpString).Value
                [pscustomobject]$o = [pscustomobject]@{
                    Code = $Code
                    Description = $TmpString.Replace($Code, '').Trim().TrimStart('-', '').Trim()
                    Success = $True
                }
                return $o
            }
            [pscustomobject]$o = [pscustomobject]@{
                Code = 'null'
                Description = 'null'
                Success = $False
            }
            return $o
        } catch {
            Write-Warning "Error occurred: $_"
            return $null
        }
    }
}

# ======================================================================
# Get-GenericPowertrainCodesFromUrl
# ======================================================================


function Get-GenericPowertrainCodesFromUrl {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Url
    )

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $SubPath = $Url.Replace('https://www.obd-codes.com/', '')


        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "$SubPath)"
            "scheme" = "https"
            "accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "priority" = "u=0, i"
            "referer" = "https://www.obd-codes.com/trouble_codes/"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        $Valid = $True
        $Id = 2
        [regex]$pattern = '^[PpBbCcUu][0-3][0-9A-Ca-c][0-9A-Fa-f]{2}'
        while ($Valid) {
            try {

                $XPathCode = "/html/body/div/div[2]/ul/li[{0}]/a" -f $Id

                $ResultNodeCode = $HtmlNode.SelectSingleNode($XPathCode)

                if (!$ResultNodeCode) {
                    Write-Verbose "EMPTY"
                    $Valid = $False
                    break;
                }

                [string]$Text = $ResultNodeCode.InnerText.Trim()
                [bool]$IsSuccess = $pattern.Match($Text).Success
                if ($IsSuccess) {
                    $IsSpecial = $False
                    [string]$CodeValue = $pattern.Match($Text).Value
                    $UrlCodeValue = ($ResultNodeCode.Attributes[0].Value).TrimStart(" ").Trim()
                    $FullUrl = 'https://www.obd-codes.com{0}' -f $UrlCodeValue
                    $Desc1 = $Text.Replace($CodeValue, '').Trim()
                    if (($Desc1[0] -eq ',') -or ($Desc1[0] -eq '-')) {
                        $IsSpecial = $True
                    }
                    $Desc2 = [System.Net.WebUtility]::HtmlDecode($Desc1)
                    [pscustomobject]$o = [pscustomobject]@{
                        Code = $CodeValue.Trim()
                        Description = $Desc2.Trim()
                        Url = $FullUrl
                        Type = 'Powertrain'
                    }
                    if ($IsSpecial) {
                        if ($Desc1[0] -eq ',') {
                            $Array = $Desc1.Split(',').Trim()
                            foreach ($s in $Array) {
                                if ($pattern.Match($s).Success) {
                                    $c = $pattern.Match($s).Value
                                    $d = 'ISO/SAE Reserved'
                                    [pscustomobject]$o = [pscustomobject]@{
                                        Code = $c
                                        Description = $d
                                        Url = $FullUrl
                                        Type = 'Powertrain'
                                    }
                                    [void]$ParsedList.Add($o)
                                }
                            }
                        } elseif ($Desc1[0] -eq '-') {
                            $TmpDesc = $Desc1.TrimStart('- ')
                            $CodeValue1 = $CodeValue
                            [string]$CodeValue2 = $pattern.Match($TmpDesc).Value

                            Get-Obd2CodeRange $CodeValue1 $CodeValue2 | % {
                                $NewDesc = $Desc2.Trim('- ').Trim($CodeValue2).Trim()
                                [pscustomobject]$o = [pscustomobject]@{
                                    Code = "$_"
                                    Description = $NewDesc
                                    Url = $FullUrl
                                    Type = 'Powertrain'
                                }
                                [void]$ParsedList.Add($o)
                            }
                        }
                    } else {
                        [void]$ParsedList.Add($o)
                    }

                }

                $Id++
                Write-Verbose "ok"

            } catch {
                Write-Verbose "$_"
                continue;
            }

        }
        $ParsedList


    } catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}

# ======================================================================
# Get-GenericPowertrainCodes
# ======================================================================



function Get-GenericPowertrainCodes {
    [CmdletBinding(SupportsShouldProcess)]
    param()


    $CodeUrls = Get-GenericPowertrainCodesUrls
    $CodeUrlsCount = $CodeUrls.Count
    Write-Host "[Powertrain Codes] Found $CodeUrlsCount Urls"
    $i = 0

    $All = $CodeUrls.ForEach({
            Write-Host "[Powertrain Codes] $i) Listing Codes from `"$_`"..."
            Get-GenericPowertrainCodesFromUrl -Url "$_"
            $i++
        })

    $All
}

# ======================================================================
# Get-GenericChassisCodes
# ======================================================================



function Get-GenericChassisCodes {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Url = "https://www.obd-codes.com/trouble_codes/obd-ii-c-chassis-codes.php"
        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "/trouble_codes/obd-ii-c-chassis-codes.php"
            "scheme" = "https"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "priority" = "u=0, i"
            "referer" = "https://www.obd-codes.com/trouble_codes/"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        $Valid = $True
        $Id = 1
        while ($Valid) {
            try {
                $XPathLinks = "/html/body/div/div[2]/p[2]/text()[{0}]" -f $Id
                $Id++

                $ResultNodeLinks = $HtmlNode.SelectSingleNode($XPathLinks)

                if (!$ResultNodeLinks) {
                    Write-Verbose "EMPTY"
                    $Valid = $False
                    break;
                }

                $TmpString = $ResultNodeLinks.InnerText.Trim()

                $Code = $TmpString.SubString(0, 5)
                $Desc = $TmpString.SubString(7).Trim()
                $Url = 'n/a'
                [pscustomobject]$o = [pscustomobject]@{
                    Code = "$Code"
                    Description = "$Desc"
                    Url = "$Url"
                    Type = 'Chassis'
                }

                [void]$ParsedList.Add($o)
            } catch {
                Write-Verbose "$_"
                continue;
            }

        }

        return $ParsedList
    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}

# ======================================================================
# Get-GenericNetworkCodes
# ======================================================================

function Get-GenericNetworkCodes {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Url = "https://www.obd-codes.com/trouble_codes/obd-ii-u-network-codes.php"
        $HeadersData = @{
            "authority" = "www.obd-codes.com"
            "method" = "GET"
            "path" = "/trouble_codes/obd-ii-u-network-codes.php"
            "scheme" = "https"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content
        [regex]$pattern = '^[PpBbCcUu][0-3][0-9A-Ca-c][0-9A-Fa-f]{2}'

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        $Valid = $True
        $CategoryId = 1
        $CodeId = 1
        $ValidCodeCount = 0
        for ($CategoryId = 1; $CategoryId -lt 20; $CategoryId++) {
            for ($CodeId = 1; $CodeId -lt 300; $CodeId++) {
                try {
                    $IsSpecial = $False

                    $XPathLinks = "/html/body/div/div[2]/ul[{0}]/li[{1}]" -f $CategoryId, $CodeId
                    $ResultNodeLinks = $HtmlNode.SelectSingleNode($XPathLinks)

                    if (!$ResultNodeLinks) {
                        Write-Verbose "$tableId,$statsId EMPTY"
                        continue;
                    }
                    $ContainsValidLink = $ResultNodeLinks.InnerHtml.Contains('href')

                    $TmpString = $ResultNodeLinks.InnerText.Trim()
                    $CodeValue = $TmpString.SubString(0, 5).Trim()
                    $NetworkCodeDescription = $TmpString.Replace($CodeValue, '').Trim()
                    $NetworkCodeDescription = [System.Net.WebUtility]::HtmlDecode($NetworkCodeDescription)
                    if (($Null -ne $ResultNodeLinks.Attributes) -and ($Null -ne $ResultNodeLinks.Attributes[0].Value)) {
                        $CodeUrlSuffix = $ResultNodeLinks.Attributes[0].Value
                        $CodesUrl = 'https://www.obd-codes.com{0}' -f $CodeUrlSuffix
                    } else {
                        if ($ContainsValidLink) {
                            $CodesUrl = 'https://www.obd-codes.com/{0}' -f $CodeValue
                        } else {
                            $CodesUrl = 'https://www.obd-codes.com/trouble_codes/obd-ii-u-network-codes.php'
                        }
                    }

                    if (($NetworkCodeDescription[0] -eq ',') -or ($NetworkCodeDescription[0] -eq '-')) {
                        $IsSpecial = $True
                    } elseif (($NetworkCodeDescription.Split(' ')[0]) -eq 'through') {
                        $Splitted = $NetworkCodeDescription.Split(' ').Split("`t")
                        $Code1 = $CodeValue
                        $Code2 = $Splitted[1]
                        $DescIndex = $NetworkCodeDescription.IndexOf($Code2) + $Code2.Length + 1
                        $Desc = $NetworkCodeDescription.SubString($DescIndex)
                        if($Desc.Split(' ')[0] -eq 'and'){
                            $Code3 = $Desc.Split(' ')[1]
                            $DescIndex = $Desc.IndexOf($Code3) + $Code3.Length + 1
                            $Desc = $Desc.SubString($DescIndex)
                           
                            [pscustomobject]$o = [pscustomobject]@{
                                Code = "$Code3"
                                Description = $Desc
                                Url = 'https://www.obd-codes.com/trouble_codes/obd-ii-u-network-codes.php'
                                Type = 'Network'
                            }
                           
                            [void]$ParsedList.Add($o)
                            continue;

                        }
                        $Range = Get-Obd2CodeRange $Code1 $Code2 
                        $Range | % {
                            [pscustomobject]$o = [pscustomobject]@{
                                Code = "$_"
                                Description = $Desc
                                Url = ''
                                Type = 'Network'
                            }
                            
                            [void]$ParsedList.Add($o)
                        }
                        continue;
                    }

                    if ($IsSpecial) {
                        if ($NetworkCodeDescription[0] -eq ',') {
                            $Array = $NetworkCodeDescription.Split(',').Trim()
                            foreach ($s in $Array) {
                                if ($pattern.Match($s).Success) {
                                    $c = $pattern.Match($s).Value
                                    $d = 'ISO/SAE Reserved'
                                    [pscustomobject]$o = [pscustomobject]@{
                                        Code = $c
                                        Description = $d
                                        Url = 'https://www.obd-codes.com/trouble_codes/obd-ii-u-network-codes.php'
                                        Type = 'Network'
                                    }
                                    [void]$ParsedList.Add($o)
                                }
                            }
                        }
                    } else {
                        [pscustomobject]$o = [pscustomobject]@{
                            Code = "$CodeValue"
                            Description = $NetworkCodeDescription
                            Url = "$CodesUrl"
                            Type = 'Network'
                        }
                        [void]$ParsedList.Add($o)
                    }
                    $ValidCodeCount++
                } catch {
                    Show-ExceptionDetails ($_) -ShowStack
                    continue;
                }
            }
            #Write-Host "Codes Count $ValidCodeCount"
            $ValidCodeCount = 0
        }

        return $ParsedList
    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}

# ======================================================================
# ConvertFrom-Base64CompressedJsonBlock
# ======================================================================


function ConvertFrom-Base64CompressedJsonBlock {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ScriptBlock
    )
    process {

        # Take my B64 string and do a Base64 to Byte array conversion of compressed data
        $ScriptBlockCompressed = [System.Convert]::FromBase64String($ScriptBlock)

        # Then decompress script's data
        $InputStream = New-Object System.IO.MemoryStream (, $ScriptBlockCompressed)
        $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
        $StreamReader = New-Object System.IO.StreamReader ($GzipStream)
        $ScriptBlockDecompressed = $StreamReader.ReadToEnd()
        # And close the streams
        $GzipStream.Close()
        $InputStream.Close()

        $ScriptBlockDecompressed
    }

}

# ======================================================================
# Get-KellyBlueBookCodesJson
# ======================================================================


function Get-KellyBlueBookCodesJson {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Url = "https://www.kbb.com/obd-ii/"
        $HeadersData = @{
            "method" = "GET"
            "path" = "/obd-ii/"
            "scheme" = "https"
            "cache-control" = "no-cache"
            "pragma" = "no-cache"
            "priority" = "u=0, i"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        $tag = '"allCodes":{"isZipped":true,"data":"'
        $taglen = $tag.Length
        $Found = ($HtmlContent.IndexOf($tag) -ne -1)
        if ($Found) {
            $start = $HtmlContent.IndexOf($tag) + $taglen
            $end = $HtmlContent.IndexOf('"', $start)
            $size = $end - $start
            $CompressedData = $HtmlContent.SubString($start, $size)
            $DecompressedData = ConvertFrom-Base64CompressedJsonBlock $CompressedData
            return $DecompressedData
        }
        return ""

    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}

# ======================================================================
# Get-KellyBlueBookCodesTable
# ======================================================================


function Get-KellyBlueBookCodesTable {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {
        $json = Get-KellyBlueBookCodesJson | ConvertFrom-Json

        $codeTable = @{}
        foreach ($family in $json.families) {
            foreach ($group in $family.groups) {
                foreach ($code in $group.codes) {
                    [string]$tmpId = $code.Id
                    $tmpIdUpper = $tmpId.ToUpper()
                    $codeTable[$tmpIdUpper] = "$($code.Description)"
                }
            }
        }

        $sortedArray = $codeTable.GetEnumerator() | Sort-Object {
            $prefix = $_.Key.SubString(0, 1)
            $number = [Convert]::ToInt32($_.Key.SubString(1), 16)
            "{0}:{1:D5}" -f $prefix, $number
        }
        $sortedCodeTable = [ordered]@{}
        foreach ($entry in $sortedArray) {
            $sortedCodeTable[$entry.Key] = $entry.Value
        }
        # Display result
        #foreach ($entry in $sortedCodeTable) {
        #    "{0} = {1}" -f $entry.Key, $entry.Value
        #}

        return $sortedCodeTable

    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}




# ======================================================================
# Test-GetGenericBodyCodes
# ======================================================================

function Test-GetDataFromWeb {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )
    New-Item -Path "$Path" -ItemType File -Force -Value ""
    Write-Host "`n`n=====================================" -f DarkCyan
    Write-Host "Test-GetDataFromWeb" -f DarkRed
    try {
        Write-Host "`n`n=====================================" -f DarkCyan
        Write-Host -n "Get-GenericChassisCodes" -f Cyan
        $o1 = Get-GenericChassisCodes
        $o1 | ConvertTo-Json | Add-Content "$Path"
        $o1Count = $o1.Count
        Write-Host "Get-GenericChassisCodes $o1Count items" -f DarkYellow
        Write-Host "`n`n=====================================" -f DarkCyan
        Write-Host -n "Get-GenericBodyCodes" -f Cyan
        $o1 = Get-GenericBodyCodes
        $o1Count = $o1.Count
        Write-Host "Get-GenericBodyCodes $o1Count items" -f DarkYellow
        $o1 | ConvertTo-Json | Add-Content "$Path"

        Write-Host "`n`n=====================================" -f DarkCyan
        Write-Host -n "Get-GenericPowertrainCodes" -f Cyan
        $o2 = Get-GenericPowertrainCodes
        $o2Count = $o2.Count
        Write-Host "Get-GenericPowertrainCodes $o2Count items" -f DarkYellow
        $o2 | ConvertTo-Json | Add-Content "$Path"
        Write-Host "`n`n=====================================" -f DarkCyan
        Write-Host -n "Get-GenericNetworkCodes" -f Cyan
        $o3 = Get-GenericNetworkCodes
        $o3Count = $o3.Count
        Write-Host "Get-GenericNetworkCodes $o3Count items" -f DarkYellow
        $o3 | ConvertTo-Json | Add-Content "$Path"
        Write-Host "`n`n=====================================" -f DarkCyan
        Write-Host -n "Get-KellyBlueBookCodesJson" -f Cyan
        $o4 = Get-KellyBlueBookCodesJson
        $o4Count = $o4.Count
        Write-Host "Get-KellyBlueBookCodesJson $o4Count items" -f DarkYellow
        $o4 | ConvertTo-Json | Add-Content "$Path"
        Write-Host "`n`n=====================================" -f DarkCyan
        Write-Host -n "Get-CarMakeList" -f Cyan
        [System.Collections.ArrayList]$AllMakes = Get-CarMakeList
        foreach ($make in $AllMakes) {
            $MakeName = $make.Name
            $MakeDesc = $make.Description
            if ($MakeName -eq 'none') {
                continue;
            }

            Write-Host "`n`n=====================================" -f DarkCyan
            Write-Host -n "ManufacturerSpecificCodes $MakeName ($MakeDesc)" -f Cyan
            $ManufacturerSpecificCodes = Get-ManufacturerSpecificCodes $MakeName
            $ManufacturerSpecificCodesCount = $ManufacturerSpecificCodes.Count
            $ManufacturerSpecificCodes | ConvertTo-Json | Add-Content "$Path"
            Write-Host "$ManufacturerSpecificCodesCount for $MakeDesc" -f DarkYellow
        }
    } catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}



# $codeTable = Get-KellyBlueBookCodesTable
# $description = $codeTable["P0420"]
# Write-Host $description  # ➜ Catalyst System Efficiency Below Threshold (Bank 1)


