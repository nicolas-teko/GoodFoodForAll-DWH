-- ============================================
-- Auswertung: Zahlung an Produzenten (Kimball)
-- Deckt F04 ab. Sortiert nach höchstem Umsatz.
-- Vereinfachung: jedes Produkt ist genau einem Produzenten
-- zugeordnet (siehe 5.1), daher 80% des Verkaufsumsatzes
-- eines Produkts direkt an dessen Produzenten.
-- ============================================

USE DWHGoodFoodForAll;
GO

;WITH ProduktProduzent AS (
    SELECT DISTINCT ProduktKey, ProduzentKey FROM Fakt_Einkauf
),
UmsatzProProdukt AS (
    SELECT ProduktKey, SUM(Umsatz) AS UmsatzTotal FROM Fakt_Verkauf GROUP BY ProduktKey
)
SELECT
    dpz.Name AS Produzent,
    dp.Bezeichnung AS Produkt,
    u.UmsatzTotal,
    ROUND(u.UmsatzTotal * 0.8, 2) AS Auszahlung
FROM UmsatzProProdukt u
JOIN ProduktProduzent pp ON pp.ProduktKey = u.ProduktKey
JOIN Dim_Produkt dp       ON dp.ProduktKey = u.ProduktKey
JOIN Dim_Produzent dpz    ON dpz.ProduzentKey = pp.ProduzentKey
ORDER BY u.UmsatzTotal DESC;
