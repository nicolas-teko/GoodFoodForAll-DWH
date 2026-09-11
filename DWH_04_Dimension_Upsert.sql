USE DWHGoodFoodForAll;
GO

-- ============================================
-- Dimension-Upsert
-- Legt fuer jeden noch unbekannten Namen/Datum eine neue
-- Zeile in der jeweiligen Dimension an. Bereits vorhandene
-- Werte werden nicht doppelt angelegt (Name/Datum = Abgleich).
-- Quelle: Staging_Bereinigt
-- ============================================

-- ---------- Dim_Produkt ----------
INSERT INTO Dim_Produkt (Bezeichnung, Einheit)
SELECT DISTINCT s.ProduktBezeichnung, NULL
FROM Staging_Bereinigt s
WHERE s.ProduktBezeichnung IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM Dim_Produkt d WHERE d.Bezeichnung = s.ProduktBezeichnung
  );
GO

-- ---------- Dim_Standort ----------
INSERT INTO Dim_Standort (Name, Adresse, FranchisenehmerName)
SELECT DISTINCT s.StandortName, NULL, NULL
FROM Staging_Bereinigt s
WHERE s.StandortName IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM Dim_Standort d WHERE d.Name = s.StandortName
  );
GO

-- ---------- Dim_Produzent ----------
INSERT INTO Dim_Produzent (Name, Adresse)
SELECT DISTINCT s.ProduzentName, NULL
FROM Staging_Bereinigt s
WHERE s.ProduzentName IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM Dim_Produzent d WHERE d.Name = s.ProduzentName
  );
GO

-- ---------- Dim_Zeit ----------
-- ZeitKey als Smart Key im Format JJJJMMTT
INSERT INTO Dim_Zeit (ZeitKey, Datum, Jahr, Monat, Kalenderwoche, Wochentag)
SELECT DISTINCT
    CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd')) AS ZeitKey,
    s.Datum,
    YEAR(s.Datum),
    MONTH(s.Datum),
    DATEPART(ISO_WEEK, s.Datum),
    FORMAT(s.Datum, 'dddd', 'de-CH')   -- deutscher Wochentagsname, unabhaengig von der Session-Sprache
FROM Staging_Bereinigt s
WHERE s.Datum IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM Dim_Zeit d WHERE d.ZeitKey = CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd'))
  );
GO

-- ============================================
-- Kurzcheck
-- ============================================
SELECT 'Dim_Produkt' AS Tabelle, COUNT(*) AS AnzahlZeilen FROM Dim_Produkt
UNION ALL SELECT 'Dim_Standort', COUNT(*) FROM Dim_Standort
UNION ALL SELECT 'Dim_Produzent', COUNT(*) FROM Dim_Produzent
UNION ALL SELECT 'Dim_Zeit', COUNT(*) FROM Dim_Zeit;
