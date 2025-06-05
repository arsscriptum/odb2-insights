#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   common.ps1                                                                   ║
#║                                                                                ║
#║   function to parse the site obd-codes.com                                     ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaumep  <guillaumep@luminator.com>                                       ║
#║   Copyright (C) Luminator Technology Group.  All rights reserved.              ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-RootPath {
    return (Resolve-Path "$PSScriptRoot\..\..").Path
}

function Get-HtmlPath {
    return Join-Path -Path (Get-RootPath) -ChildPath "html"
}

function Get-ScriptsPath {
    return Join-Path -Path (Get-RootPath) -ChildPath "scripts"
}

function Get-ScriptsPsPath {
    return Join-Path -Path (Get-ScriptsPath) -ChildPath "ps"
}

function Get-ScriptsSqlPath {
    return Join-Path -Path (Get-ScriptsPath) -ChildPath "sql"
}

function Get-ScriptsLibsPath {
    return Join-Path -Path (Get-ScriptsPsPath) -ChildPath "lib"
}

function Get-HtmlDataPath {
    return Join-Path -Path (Get-HtmlPath) -ChildPath "data"
}

function Get-JsonDataPath {
    return Join-Path -Path (Get-HtmlDataPath) -ChildPath "json"
}

function Get-HtmlDbPath {
    return Join-Path -Path (Get-HtmlPath) -ChildPath "db"
}

function Get-CarMakeListJsonPath {
    return Join-Path -Path (Get-JsonDataPath) -ChildPath "carmakes.json"
}


function Get-DatabaseFilePath {
    return Join-Path -Path (Get-HtmlDbPath) -ChildPath "code.db"
}

function Register-SqlLib {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    # Array to store jobs
    $SqlLib = Join-Path (Get-ScriptsLibsPath) "System.Data.SQLite.dll"
    $Success = $True
        
    try{
        Add-Type -Path "$SqlLib"
        [System.Data.SQLite.SQLiteConnection] -as [System.Data.SQLite.SQLiteConnection]
        $Success = $True
    }catch{
        $Success = $False
        throw "$_"
    }
    return $Success
}

function Update-AllLists {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Path
    )

    $FilePath = Get-CarMakeListJsonPath
    Update-CarMakeList -Path "$FilePath"
}



function Register-HtmlAgilityPack {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Path
    )
    # Array to store jobs
    $HtmlAgilityPackLib = Join-Path (Get-ScriptsLibsPath) "Core\HtmlAgilityPack.dll"
    $Success = $True
        
    try{
        Add-Type -Path "$HtmlAgilityPackLib"
        [HtmlAgilityPack.HtmlDocument] -as [HtmlAgilityPack.HtmlDocument]
        $Success = $True
    }catch{
        $Success = $False
        throw "$_"
    }
    return $Success
}
