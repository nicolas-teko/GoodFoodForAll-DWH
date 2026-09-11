USE DWHGoodFoodForAll;
GO

-- ============================================
-- Bereinigung / Validierung (Z05)
-- Prueft jede Zeile aus Staging_Import und trennt sie in:
--   - Staging_Bereinigt: gueltige Zeilen, richtig typisiert
--   - Staging_Fehlerprotokoll: fehlerhafte Zeilen mit Grund
-- ============================================

-- Referenzliste der gueltigen Produkte (Whitelist).
-- Damit werden Tippfehler wie "Tomatten" erkannt, auch wenn
-- Dim_Produkt beim ersten Lauf noch leer ist.
DROP TABLE IF EXISTS Ref_GueltigeProdukte;
GO
CREATE TABLE Ref_GueltigeProdukte (Bezeichnung NVARCHAR(100) PRIMARY KEY);
GO
INSERT INTO Ref_GueltigeProdukte (Bezeichnung) VALUES
('Tomaten'), ('Gurken'), ('Karotten'), ('Zucchetti'), ('Kopfsalat'),
('Kartoffeln'), ('Zwiebeln'), ('Randen'), ('Peperoni'), ('Broccoli');
GO

-- ============================================
-- Vorbereitung: Zeilen nummerieren und Datum parsen
-- (beide Formate abfangen: JJJJ-MM-TT und TT.MM.JJJJ)
-- ============================================
DROP TABLE IF EXISTS Staging_Vorbereitet;
GO
SELECT
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ZeilenNr,
    StandortName,
    ProduzentName,
    ProduktBezeichnung,
    COALESCE(
        TRY_CONVERT(DATE, REPLACE(Datum, CHAR(13), ''), 23),   -- JJJJ-MM-TT
        TRY_CONVERT(DATE, REPLACE(Datum, CHAR(13), ''), 104)   -- TT.MM.JJJJ
    ) AS DatumBereinigt,
    TRY_CAST(REPLACE(GelieferteMenge, CHAR(13), '') AS DECIMAL(10,2)) AS GelieferteMengeBereinigt,
    TRY_CAST(REPLACE(VerkaufteMenge, CHAR(13), '') AS DECIMAL(10,2)) AS VerkaufteMengeBereinigt,
    TRY_CAST(REPLACE(Umsatz, CHAR(13), '') AS DECIMAL(10,2)) AS UmsatzBereinigt,
    TRY_CAST(REPLACE(EinkaufsMenge, CHAR(13), '') AS DECIMAL(10,2)) AS EinkaufsMengeBereinigt,
    TRY_CAST(REPLACE(EinkaufsBetrag, CHAR(13), '') AS DECIMAL(10,2)) AS EinkaufsBetragBereinigt
INTO Staging_Vorbereitet
FROM Staging_Import;
GO

-- ============================================
-- Duplikate markieren (exakt gleiche Zeile mehrfach)
-- ============================================
DROP TABLE IF EXISTS Staging_MitDuplikatKennung;
GO
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY StandortName, ProduzentName, ProduktBezeichnung, DatumBereinigt,
                     GelieferteMengeBereinigt, VerkaufteMengeBereinigt, UmsatzBereinigt,
                     EinkaufsMengeBereinigt, EinkaufsBetragBereinigt
        ORDER BY ZeilenNr
    ) AS DuplikatRang
INTO Staging_MitDuplikatKennung
FROM Staging_Vorbereitet;
GO

-- ============================================
-- Fehlerprotokoll: jede Zeile mit mind. einem Fehlergrund
-- ============================================
DROP TABLE IF EXISTS Staging_Fehlerprotokoll;
GO
SELECT
    ZeilenNr, StandortName, ProduzentName, ProduktBezeichnung,
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
INTO Staging_Fehlerprotokoll_Temp
FROM Staging_MitDuplikatKennung;
GO

SELECT * INTO Staging_Fehlerprotokoll FROM Staging_Fehlerprotokoll_Temp WHERE Fehlergrund IS NOT NULL;
DROP TABLE Staging_Fehlerprotokoll_Temp;
GO

-- ============================================
-- Staging_Bereinigt: nur fehlerfreie, eindeutige Zeilen,
-- richtig typisiert, bereit fuer Dimension-Upsert und Load
-- ============================================
DROP TABLE IF EXISTS Staging_Bereinigt;
GO
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
GO

-- ============================================
-- Kurzcheck
-- ============================================
SELECT COUNT(*) AS ZeilenGesamt FROM Staging_Import;
SELECT COUNT(*) AS ZeilenBereinigt FROM Staging_Bereinigt;
SELECT COUNT(*) AS ZeilenMitFehler FROM Staging_Fehlerprotokoll;
SELECT Fehlergrund, COUNT(*) AS Anzahl FROM Staging_Fehlerprotokoll GROUP BY Fehlergrund ORDER BY Anzahl DESC;
