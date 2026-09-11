-- ============================================
-- Auswertung: Standortmerkmale / Statistikwerte (Atomar/EAV)
-- Deckt F09 ab. Sortiert nach höchstem Kaufkraftindex,
-- damit die kaufkräftigsten Standorte zuoberst stehen.
-- ============================================

USE DWHGoodFoodForAll;
GO

SELECT
    ds.Name AS Standort,
    MAX(CASE WHEN m.MerkmalName = 'Kaufkraftindex' THEN CAST(w.Wert AS INT) END) AS Kaufkraftindex,
    MAX(CASE WHEN m.MerkmalName = 'Altersgruppe (mehrheitlich)' THEN w.Wert END) AS Altersgruppe,
    MAX(CASE WHEN m.MerkmalName = 'Kundenfrequenz pro Tag' THEN w.Wert END) AS KundenfrequenzProTag
FROM Atomar_Wert w
JOIN Dim_Standort ds ON ds.StandortKey = w.StandortKey
JOIN Atomar_Merkmal m ON m.MerkmalID = w.MerkmalID
GROUP BY ds.Name
ORDER BY Kaufkraftindex DESC;
