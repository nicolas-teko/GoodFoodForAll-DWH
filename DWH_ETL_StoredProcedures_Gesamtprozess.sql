USE DWHGoodFoodForAll;
GO

-- ============================================
-- ETL als Stored Procedures
-- Fasst die vier bisherigen Einzelskripte zusammen, damit
-- ein neuer ETL-Lauf (z. B. mit einer neuen CSV) nicht mehr
-- vier Skripte einzeln braucht, sondern nur noch einen Aufruf:
--   EXEC usp_ETL_Gesamtprozess 'C:\Temp\NeueDatei.csv';
-- ============================================

-- ---------- Schritt 1: Staging / Import ----------
CREATE OR ALTER PROCEDURE usp_ETL_01_Staging_Import
    @CsvPfad NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS Staging_Import;
    CREATE TABLE Staging_Import (
        StandortName NVARCHAR(100) NULL,
        ProduzentName NVARCHAR(100) NULL,
        ProduktBezeichnung NVARCHAR(100) NULL,
        Datum NVARCHAR(20) NULL,
        GelieferteMenge NVARCHAR(20) NULL,
        VerkaufteMenge NVARCHAR(20) NULL,
        Umsatz NVARCHAR(20) NULL,
        EinkaufsMenge NVARCHAR(20) NULL,
        EinkaufsBetrag NVARCHAR(20) NULL
    );

    -- BULK INSERT erlaubt keinen Variablen-Pfad direkt,
    -- deshalb per dynamischem SQL ausgefuehrt.
    DECLARE @sql NVARCHAR(MAX) = N'
        BULK INSERT Staging_Import
        FROM ''' + @CsvPfad + N'''
        WITH (
            FORMAT = ''CSV'',
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\r\n'',
            CODEPAGE = ''65001'',
            TABLOCK
        );';
    EXEC sp_executesql @sql;

    DECLARE @Anzahl1 INT = (SELECT COUNT(*) FROM Staging_Import);
    PRINT 'Schritt 1 (Staging/Import) abgeschlossen: ' + CAST(@Anzahl1 AS NVARCHAR) + ' Zeilen.';
END
GO

-- ---------- Schritt 2: Bereinigung / Validierung (Z05) ----------
CREATE OR ALTER PROCEDURE usp_ETL_02_Bereinigung
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Ref_GueltigeProdukte')
    BEGIN
        CREATE TABLE Ref_GueltigeProdukte (Bezeichnung NVARCHAR(100) PRIMARY KEY);
        INSERT INTO Ref_GueltigeProdukte (Bezeichnung) VALUES
        ('Tomaten'), ('Gurken'), ('Karotten'), ('Zucchetti'), ('Kopfsalat'),
        ('Kartoffeln'), ('Zwiebeln'), ('Randen'), ('Peperoni'), ('Broccoli');
    END

    DROP TABLE IF EXISTS Staging_Vorbereitet;
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ZeilenNr,
        StandortName, ProduzentName, ProduktBezeichnung,
        COALESCE(
            TRY_CONVERT(DATE, REPLACE(Datum, CHAR(13), ''), 23),
            TRY_CONVERT(DATE, REPLACE(Datum, CHAR(13), ''), 104)
        ) AS DatumBereinigt,
        TRY_CAST(REPLACE(GelieferteMenge, CHAR(13), '') AS DECIMAL(10,2)) AS GelieferteMengeBereinigt,
        TRY_CAST(REPLACE(VerkaufteMenge, CHAR(13), '') AS DECIMAL(10,2)) AS VerkaufteMengeBereinigt,
        TRY_CAST(REPLACE(Umsatz, CHAR(13), '') AS DECIMAL(10,2)) AS UmsatzBereinigt,
        TRY_CAST(REPLACE(EinkaufsMenge, CHAR(13), '') AS DECIMAL(10,2)) AS EinkaufsMengeBereinigt,
        TRY_CAST(REPLACE(EinkaufsBetrag, CHAR(13), '') AS DECIMAL(10,2)) AS EinkaufsBetragBereinigt
    INTO Staging_Vorbereitet
    FROM Staging_Import;

    DROP TABLE IF EXISTS Staging_MitDuplikatKennung;
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY StandortName, ProduzentName, ProduktBezeichnung, DatumBereinigt,
                         GelieferteMengeBereinigt, VerkaufteMengeBereinigt, UmsatzBereinigt,
                         EinkaufsMengeBereinigt, EinkaufsBetragBereinigt
            ORDER BY ZeilenNr
        ) AS DuplikatRang
    INTO Staging_MitDuplikatKennung
    FROM Staging_Vorbereitet;

    DROP TABLE IF EXISTS Staging_Fehlerprotokoll;
    SELECT ZeilenNr, StandortName, ProduzentName, ProduktBezeichnung, Fehlergrund
    INTO Staging_Fehlerprotokoll
    FROM (
        SELECT *,
            CASE
                WHEN DuplikatRang > 1 THEN 'Duplikat'
                WHEN DatumBereinigt IS NULL THEN 'Ungueltiges Datum'
                WHEN ProduktBezeichnung NOT IN (SELECT Bezeichnung FROM Ref_GueltigeProdukte) THEN 'Unbekanntes Produkt'
                WHEN StandortName IS NOT NULL AND GelieferteMengeBereinigt IS NULL THEN 'Fehlende GelieferteMenge'
                WHEN StandortName IS NOT NULL AND VerkaufteMengeBereinigt IS NULL THEN 'Fehlende VerkaufteMenge'
                WHEN StandortName IS NOT NULL AND (GelieferteMengeBereinigt < 0 OR VerkaufteMengeBereinigt < 0) THEN 'Negative Menge'
                WHEN ProduzentName IS NOT NULL AND (EinkaufsMengeBereinigt IS NULL OR EinkaufsBetragBereinigt IS NULL) THEN 'Fehlender Einkaufswert'
                WHEN ProduzentName IS NOT NULL AND (EinkaufsMengeBereinigt < 0 OR EinkaufsBetragBereinigt < 0) THEN 'Negativer Einkaufswert'
                ELSE NULL
            END AS Fehlergrund
        FROM Staging_MitDuplikatKennung
    ) t
    WHERE Fehlergrund IS NOT NULL;

    DROP TABLE IF EXISTS Staging_Bereinigt;
    SELECT
        ZeilenNr, StandortName, ProduzentName, ProduktBezeichnung,
        DatumBereinigt AS Datum,
        GelieferteMengeBereinigt AS GelieferteMenge,
        VerkaufteMengeBereinigt AS VerkaufteMenge,
        UmsatzBereinigt AS Umsatz,
        EinkaufsMengeBereinigt AS EinkaufsMenge,
        EinkaufsBetragBereinigt AS EinkaufsBetrag
    INTO Staging_Bereinigt
    FROM Staging_MitDuplikatKennung
    WHERE ZeilenNr NOT IN (SELECT ZeilenNr FROM Staging_Fehlerprotokoll);

    DECLARE @AnzahlBereinigt INT = (SELECT COUNT(*) FROM Staging_Bereinigt);
    DECLARE @AnzahlFehler INT = (SELECT COUNT(*) FROM Staging_Fehlerprotokoll);
    PRINT 'Schritt 2 (Bereinigung) abgeschlossen: ' + CAST(@AnzahlBereinigt AS NVARCHAR) + ' saubere Zeilen, '
        + CAST(@AnzahlFehler AS NVARCHAR) + ' fehlerhafte Zeilen.';
END
GO

-- ---------- Schritt 3: Dimensionen befuellen (Stammdaten-Abgleich) ----------
CREATE OR ALTER PROCEDURE usp_ETL_03_Dimensionen
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Dim_Produkt (Bezeichnung, Einheit)
    SELECT DISTINCT s.ProduktBezeichnung, NULL
    FROM Staging_Bereinigt s
    WHERE s.ProduktBezeichnung IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM Dim_Produkt d WHERE d.Bezeichnung = s.ProduktBezeichnung);

    INSERT INTO Dim_Standort (Name, Adresse, FranchisenehmerName)
    SELECT DISTINCT s.StandortName, NULL, NULL
    FROM Staging_Bereinigt s
    WHERE s.StandortName IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM Dim_Standort d WHERE d.Name = s.StandortName);

    INSERT INTO Dim_Produzent (Name, Adresse)
    SELECT DISTINCT s.ProduzentName, NULL
    FROM Staging_Bereinigt s
    WHERE s.ProduzentName IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM Dim_Produzent d WHERE d.Name = s.ProduzentName);

    INSERT INTO Dim_Zeit (ZeitKey, Datum, Jahr, Monat, Kalenderwoche, Wochentag)
    SELECT DISTINCT
        CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd')),
        s.Datum, YEAR(s.Datum), MONTH(s.Datum), DATEPART(ISO_WEEK, s.Datum),
        FORMAT(s.Datum, 'dddd', 'de-CH')
    FROM Staging_Bereinigt s
    WHERE s.Datum IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM Dim_Zeit d WHERE d.ZeitKey = CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd')));

    PRINT 'Schritt 3 (Dimensionen) abgeschlossen.';
END
GO

-- ---------- Schritt 4: Fakten laden ----------
CREATE OR ALTER PROCEDURE usp_ETL_04_FaktenLaden
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Fakt_Verkauf (ProduktKey, StandortKey, ZeitKey, Menge, Umsatz)
    SELECT dp.ProduktKey, ds.StandortKey, dz.ZeitKey, s.VerkaufteMenge, s.Umsatz
    FROM Staging_Bereinigt s
    JOIN Dim_Produkt dp  ON dp.Bezeichnung = s.ProduktBezeichnung
    JOIN Dim_Standort ds ON ds.Name = s.StandortName
    JOIN Dim_Zeit dz     ON dz.ZeitKey = CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd'))
    WHERE s.StandortName IS NOT NULL AND s.VerkaufteMenge IS NOT NULL AND s.Umsatz IS NOT NULL;

    INSERT INTO Fakt_Lieferung (ProduktKey, StandortKey, ZeitKey, Menge)
    SELECT dp.ProduktKey, ds.StandortKey, dz.ZeitKey, s.GelieferteMenge
    FROM Staging_Bereinigt s
    JOIN Dim_Produkt dp  ON dp.Bezeichnung = s.ProduktBezeichnung
    JOIN Dim_Standort ds ON ds.Name = s.StandortName
    JOIN Dim_Zeit dz     ON dz.ZeitKey = CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd'))
    WHERE s.StandortName IS NOT NULL AND s.GelieferteMenge IS NOT NULL;

    INSERT INTO Fakt_Einkauf (ProduktKey, ProduzentKey, ZeitKey, Menge, EinkaufsBetrag)
    SELECT dp.ProduktKey, dpz.ProduzentKey, dz.ZeitKey, s.EinkaufsMenge, s.EinkaufsBetrag
    FROM Staging_Bereinigt s
    JOIN Dim_Produkt dp    ON dp.Bezeichnung = s.ProduktBezeichnung
    JOIN Dim_Produzent dpz ON dpz.Name = s.ProduzentName
    JOIN Dim_Zeit dz       ON dz.ZeitKey = CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd'))
    WHERE s.ProduzentName IS NOT NULL AND s.EinkaufsMenge IS NOT NULL AND s.EinkaufsBetrag IS NOT NULL;

    PRINT 'Schritt 4 (Fakten laden) abgeschlossen.';
END
GO

-- ---------- Gesamtprozess: alle vier Schritte in einem Aufruf ----------
CREATE OR ALTER PROCEDURE usp_ETL_Gesamtprozess
    @CsvPfad NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC usp_ETL_01_Staging_Import @CsvPfad;
    EXEC usp_ETL_02_Bereinigung;
    EXEC usp_ETL_03_Dimensionen;
    EXEC usp_ETL_04_FaktenLaden;

    SELECT 'Dim_Produkt' AS Tabelle, COUNT(*) AS AnzahlZeilen FROM Dim_Produkt
    UNION ALL SELECT 'Dim_Standort', COUNT(*) FROM Dim_Standort
    UNION ALL SELECT 'Dim_Produzent', COUNT(*) FROM Dim_Produzent
    UNION ALL SELECT 'Dim_Zeit', COUNT(*) FROM Dim_Zeit
    UNION ALL SELECT 'Fakt_Verkauf', COUNT(*) FROM Fakt_Verkauf
    UNION ALL SELECT 'Fakt_Lieferung', COUNT(*) FROM Fakt_Lieferung
    UNION ALL SELECT 'Fakt_Einkauf', COUNT(*) FROM Fakt_Einkauf;
END
GO

-- ============================================
-- Aufruf fuer einen neuen ETL-Lauf, z. B. mit neuer CSV:
-- EXEC usp_ETL_Gesamtprozess 'C:\Temp\GoodFoodForAll_Import_75Standorte.csv';
-- ============================================
