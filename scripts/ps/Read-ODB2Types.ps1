#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Read-ODB2Types.ps1                                                           ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaumep  <guillaumep@luminator.com>                                       ║
#║   Copyright (C) Luminator Technology Group.  All rights reserved.              ║
#╚════════════════════════════════════════════════════════════════════════════════╝


enum PartType {
    Powertrain
    Body
    Chassis
    Network
}

enum CodeType {
    Generic
    ManufacturerSpecific
}

enum SystemCategory {
    FuelAirMetering
    FuelAirMeteringInjector
    IgnitionOrMisfire
    EmissionControl
    SpeedIdleControl
    ComputerOutput
    Transmission
    HybridPropulsion
    Unknown
}

function Get-PartTypeDescription {
    param (
        [Parameter(Mandatory = $true)]
        [PartType]$Part
    )
    switch ($Part) {
        'Powertrain' { 'Powertrain (engine, transmission)' }
        'Body'       { 'Body (AC, airbags)' }
        'Chassis'    { 'Chassis (ABS, suspension)' }
        'Network'    { 'Network (CAN bus, communication)' }
        default      { 'Unknown Part Type' }
    }
}


function Get-CodeTypeDescription {
    param (
        [Parameter(Mandatory = $true)]
        [CodeType]$CodeType
    )
    switch ($CodeType) {
        'Generic'               { 'Generic OBD-II code' }
        'ManufacturerSpecific'  { 'Manufacturer-specific code' }
        default                 { 'Unknown Code Type' }
    }
}


function Get-SystemCategoryDescription {
    param (
        [Parameter(Mandatory = $true)]
        [SystemCategory]$System
    )
    switch ($System) {
        'FuelAirMetering'          { 'Fuel & Air Metering' }
        'FuelAirMeteringInjector' { 'Fuel & Air Metering (injector circuit)' }
        'IgnitionOrMisfire'       { 'Ignition System or Misfire' }
        'EmissionControl'         { 'Auxiliary Emission Control' }
        'SpeedIdleControl'        { 'Vehicle Speed & Idle Control System' }
        'ComputerOutput'          { 'Computer Output Circuit' }
        'Transmission'            { 'Transmission (gearbox)' }
        'HybridPropulsion'        { 'Hybrid Propulsion System' }
        'Unknown'                 { 'Unknown or Reserved System' }
        default                   { 'Unknown System Category' }
    }
}

function Get-ObdCodeType {
    param (
        [string]$Code
    )

    $Code = $Code.ToUpper()
    $prefix = $Code.Substring(0,1)
    $digit1 = $Code.Substring(1,1)
    $digit2 = $Code.Substring(2,1)

    switch ($prefix) {
        'P' {
            if ($digit1 -eq '0' -or $digit1 -eq '2') { return 'Generic' }
            if ($digit1 -eq '1') { return 'ManufacturerSpecific' }
            if ($digit1 -eq '3') {
                if ($Code -match '^P3[0-3]') { return 'ManufacturerSpecific' }
                if ($Code -match '^P3[4-9]') { return 'Generic' }
            }
        }
        'B' {
            if ($digit1 -eq '0' -or $digit1 -eq '3') { return 'Generic' }
            if ($digit1 -eq '1' -or $digit1 -eq '2') { return 'ManufacturerSpecific' }
        }
        'C' {
            if ($digit1 -eq '0' -or $digit1 -eq '3') { return 'Generic' }
            if ($digit1 -eq '1' -or $digit1 -eq '2') { return 'ManufacturerSpecific' }
        }
        'U' {
            if ($digit1 -eq '0' -or $digit1 -eq '3') { return 'Generic' }
            if ($digit1 -eq '1' -or $digit1 -eq '2') { return 'ManufacturerSpecific' }
        }
    }

    return 'Unknown'
}


function Resolve-ObdCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^[PpBbCcUu][0-3][0-9A-Fa-f]{3}$")]
        [string]$Code
    )

    $upperCode = $Code.ToUpper()
    $prefix    = $upperCode.Substring(0, 1)
    $first     = $upperCode.Substring(1, 1)
    $second    = $upperCode.Substring(2, 1)
    $faultCode = $upperCode.Substring(3, 2)

    # Determine PartType from first letter
    $part = switch ($prefix) {
        'P' { 'Powertrain' }
        'B' { 'Body' }
        'C' { 'Chassis' }
        'U' { 'Network' }
        default { 'Unknown' }
    }

    # Determine CodeType
    $codeType = Get-ObdCodeType -Code $upperCode

    # Determine SystemCategory from the second hex digit
    $systemCategory = switch ($second) {
        { $_ -in '0','1' } { 'FuelAirMetering' }
        '2'               { 'FuelAirMeteringInjector' }
        '3'               { 'IgnitionOrMisfire' }
        '4'               { 'EmissionControl' }
        '5'               { 'SpeedIdleControl' }
        '6'               { 'ComputerOutput' }
        { $_ -in '7','8','9' } { 'Transmission' }
        { $_ -match '[A-Fa-f]' } { 'HybridPropulsion' }
        default           { 'Unknown' }
    }

    return [PSCustomObject]@{
        Code                   = $upperCode
        Part                   = $part
        PartDescription        = Get-PartTypeDescription -Part $part
        CodeType               = $codeType
        CodeTypeDescription    = Get-CodeTypeDescription -CodeType $codeType
        SystemCategory         = $systemCategory
        SystemCategoryDescription = Get-SystemCategoryDescription -System $systemCategory
        FaultDetailCode        = $faultCode
    }
}
