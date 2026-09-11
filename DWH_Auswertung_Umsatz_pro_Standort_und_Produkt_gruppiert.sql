-- ============================================
-- Auswertung: Umsatz pro Standort und Produkt (Kimball)
-- Deckt F03 ab. Gruppiert nach Standort, innerhalb jedes
-- Standorts nach höchstem Umsatz sortiert (übersichtlicher
-- beim Durchsuchen pro Standort statt einer gemischten Liste).
-- ============================================

USE DWHGoodFoodForAll;
GO

SELECT
    ds.Name AS Standort,
    dp.Bezeichnung AS Produkt,
    SUM(fv.Menge) AS VerkaufteMenge,
    SUM(fv.Umsatz) AS UmsatzTotal
FROM Fakt_Verkauf fv
JOIN Dim_Standort ds ON ds.StandortKey = fv.StandortKey
JOIN Dim_Produkt dp  ON dp.ProduktKey = fv.ProduktKey
GROUP BY ds.Name, dp.Bezeichnung
ORDER BY ds.Name ASC, UmsatzTotal DESC;
