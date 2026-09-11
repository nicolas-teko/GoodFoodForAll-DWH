USE DWHGoodFoodForAll;
GO

-- ============================================
-- Staging-Tabelle
-- Nimmt die CSV 1:1 als Text auf (auch fehlerhafte
-- oder leere Werte), damit der reine Import nie an
-- einem Datentyp-Fehler scheitert. Bereinigung und
-- Umwandlung passieren erst im nächsten Schritt.
-- ============================================

DROP TABLE IF EXISTS Staging_Import;
GO

CREATE TABLE Staging_Import (
    StandortName NVARCHAR(100) NULL,
    ProduzentName NVARCHAR(100) NULL,
    ProduktBezeichnung NVARCHAR(100) NULL,
    Datum NVARCHAR(20) NULL,          -- bewusst Text, da Datumsformat in der CSV uneinheitlich ist
    GelieferteMenge NVARCHAR(20) NULL,
    VerkaufteMenge NVARCHAR(20) NULL,
    Umsatz NVARCHAR(20) NULL,
    EinkaufsMenge NVARCHAR(20) NULL,
    EinkaufsBetrag NVARCHAR(20) NULL
);
GO

-- ============================================
-- BULK INSERT
-- Pfad anpassen an den Speicherort der CSV-Datei
-- ============================================

BULK INSERT Staging_Import
FROM 'C:\Temp\GoodFoodForAll_Import_75Standorte.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,              -- Header-Zeile überspringen
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\r\n',    -- CSV nutzt Windows-Zeilenumbrüche, sonst bleibt \r am letzten Feld hängen
    CODEPAGE = '65001',        -- UTF-8
    TABLOCK
);
GO

-- ============================================
-- Kurzcheck nach dem Import
-- ============================================
SELECT COUNT(*) AS AnzahlZeilenGesamt FROM Staging_Import;
SELECT TOP 10 * FROM Staging_Import;
