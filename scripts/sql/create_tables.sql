-- ╔════════════════════════════════════════════════════════════════════════════════╗
-- ║                                                                                ║
-- ║   create_tables.sql                                                            ║
-- ║                                                                                ║
-- ╟────────────────────────────────────────────────────────────────────────────────╢
-- ║   Guillaume Plante <codegp@icloud.com>                                         ║
-- ║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
-- ╚════════════════════════════════════════════════════════════════════════════════╝


DROP TABLE IF EXISTS CarMake;
-- Table: CarMake
CREATE TABLE CarMake (
    CarMakeId     INTEGER PRIMARY KEY AUTOINCREMENT,
    Name          TEXT NOT NULL UNIQUE,        -- e.g., 'audi'
    DisplayName   TEXT NOT NULL                -- e.g., 'Audi'
);
DROP TABLE IF EXISTS PartType;
-- Table: PartType
CREATE TABLE PartType (
    PartTypeId    INTEGER PRIMARY KEY AUTOINCREMENT,
    Name          TEXT NOT NULL UNIQUE,        -- e.g., 'Powertrain'
    DisplayName   TEXT NOT NULL,               -- e.g., 'Powertrain (engine, transmission)'
    FamilyLetter  TEXT NOT NULL CHECK (LENGTH(FamilyLetter) = 1 AND FamilyLetter IN ('B', 'C', 'P', 'U'))
);
DROP TABLE IF EXISTS SystemCategory;
-- Table: SystemCategory
CREATE TABLE SystemCategory (
    SystemCategoryId  INTEGER PRIMARY KEY AUTOINCREMENT,
    Name              TEXT NOT NULL UNIQUE,    -- e.g., 'FuelAirMetering'
    DisplayName       TEXT NOT NULL            -- e.g., 'Fuel & Air Metering'
);
DROP TABLE IF EXISTS CodeType;
-- Table: CodeType
CREATE TABLE CodeType (
    CodeTypeId   INTEGER PRIMARY KEY AUTOINCREMENT,
    Name         TEXT NOT NULL UNIQUE,         -- e.g., 'Generic'
    Description  TEXT NOT NULL
);
DROP TABLE IF EXISTS Code;
-- Table: Code,allow multiple entries with the same DiagnosticCode as long as the CarMakeId
CREATE TABLE Code (
    Id                INTEGER PRIMARY KEY AUTOINCREMENT,
    DiagnosticCode    TEXT NOT NULL CHECK (
        LENGTH(DiagnosticCode) = 5 AND 
        DiagnosticCode GLOB '[PCBUpcbu][0-3][0-9A-Ca-c][0-9A-Fa-f][0-9A-Fa-f]'
    ),
    Description       TEXT NOT NULL,
    DetailsUrl        TEXT NULL,
    CodeTypeId        INTEGER NOT NULL,
    SystemCategoryId  INTEGER NOT NULL,
    PartTypeId        INTEGER NOT NULL,
    CarMakeId         INTEGER NOT NULL,

    -- Ensure uniqueness of DiagnosticCode per CarMake
    UNIQUE (DiagnosticCode, CarMakeId),

    FOREIGN KEY (CodeTypeId) REFERENCES CodeType(CodeTypeId),
    FOREIGN KEY (SystemCategoryId) REFERENCES SystemCategory(SystemCategoryId),
    FOREIGN KEY (PartTypeId) REFERENCES PartType(PartTypeId),
    FOREIGN KEY (CarMakeId) REFERENCES CarMake(CarMakeId)
);
