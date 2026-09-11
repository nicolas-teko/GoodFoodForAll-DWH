USE DWHGoodFoodForAll;
GO

-- ============================================
-- Load: Faktentabellen befuellen
-- Liest aus Staging_Bereinigt, schlaegt die passenden
-- Dimension-Keys per Name/Datum nach und schreibt die
-- Ereigniszeilen in die drei Faktentabellen.
--
-- Hinweis: Das ist ein einmaliger Vollimport (Prototyp).
-- Bei einem wiederholten Lauf mit denselben Staging-Daten
-- wuerden die Zeilen erneut eingefuegt (keine Duplikat-
-- pruefung auf Faktenebene). Fuer einen produktiven,
-- wiederholbaren ETL-Prozess braeuchte es zusaetzlich eine
-- Lauf-/Batch-Kennung oder ein Zuruecksetzen der Fakten vor
-- jedem Lauf.
-- ============================================

-- ---------- Fakt_Verkauf ----------
INSERT INTO Fakt_Verkauf (ProduktKey, StandortKey, ZeitKey, Menge, Umsatz)
SELECT
    dp.ProduktKey,
    ds.StandortKey,
    dz.ZeitKey,
    s.VerkaufteMenge,
    s.Umsatz
FROM Staging_Bereinigt s
JOIN Dim_Produkt dp   ON dp.Bezeichnung = s.ProduktBezeichnung
JOIN Dim_Standort ds  ON ds.Name = s.StandortName
JOIN Dim_Zeit dz      ON dz.ZeitKey = CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd'))
WHERE s.StandortName IS NOT NULL
  AND s.VerkaufteMenge IS NOT NULL
  AND s.Umsatz IS NOT NULL;
GO

-- ---------- Fakt_Lieferung ----------
INSERT INTO Fakt_Lieferung (ProduktKey, StandortKey, ZeitKey, Menge)
SELECT
    dp.ProduktKey,
    ds.StandortKey,
    dz.ZeitKey,
    s.GelieferteMenge
FROM Staging_Bereinigt s
JOIN Dim_Produkt dp   ON dp.Bezeichnung = s.ProduktBezeichnung
JOIN Dim_Standort ds  ON ds.Name = s.StandortName
JOIN Dim_Zeit dz      ON dz.ZeitKey = CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd'))
WHERE s.StandortName IS NOT NULL
  AND s.GelieferteMenge IS NOT NULL;
GO

-- ---------- Fakt_Einkauf ----------
INSERT INTO Fakt_Einkauf (ProduktKey, ProduzentKey, ZeitKey, Menge, EinkaufsBetrag)
SELECT
    dp.ProduktKey,
    dpz.ProduzentKey,
    dz.ZeitKey,
    s.EinkaufsMenge,
    s.EinkaufsBetrag
FROM Staging_Bereinigt s
JOIN Dim_Produkt dp    ON dp.Bezeichnung = s.ProduktBezeichnung
JOIN Dim_Produzent dpz ON dpz.Name = s.ProduzentName
JOIN Dim_Zeit dz       ON dz.ZeitKey = CONVERT(INT, FORMAT(s.Datum, 'yyyyMMdd'))
WHERE s.ProduzentName IS NOT NULL
  AND s.EinkaufsMenge IS NOT NULL
  AND s.EinkaufsBetrag IS NOT NULL;
GO

-- ============================================
-- Kurzcheck
-- ============================================
SELECT 'Fakt_Verkauf' AS Tabelle, COUNT(*) AS AnzahlZeilen FROM Fakt_Verkauf
UNION ALL SELECT 'Fakt_Lieferung', COUNT(*) FROM Fakt_Lieferung
UNION ALL SELECT 'Fakt_Einkauf', COUNT(*) FROM Fakt_Einkauf;

-- Stichprobe: Umsatz pro Standort, absteigend
SELECT TOP 10 ds.Name AS Standort, SUM(fv.Umsatz) AS UmsatzTotal
FROM Fakt_Verkauf fv
JOIN Dim_Standort ds ON ds.StandortKey = fv.StandortKey
GROUP BY ds.Name
ORDER BY UmsatzTotal DESC;
