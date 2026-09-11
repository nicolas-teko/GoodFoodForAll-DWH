-- ============================================
-- Atomaren Bereich befüllen
-- Gehört konzeptionell zum ETL-Prozess (Laden), ist aber
-- KEIN Teil des CSV-basierten Flusses: Die Standortstatistiken
-- stammen laut Auftrag vom Statistik-Dienstleister, einer
-- separaten Datenquelle. Da dafür keine eigene Statistik-CSV
-- und kein eigener Ladeschritt umgesetzt wurde, werden hier für
-- den Prototyp direkt Zufallswerte erzeugt, statt einen
-- eigenen Mini-ETL-Import zu simulieren.
-- ============================================

USE DWHGoodFoodForAll;
GO

-- ---------- Merkmalskatalog (falls noch leer) ----------
IF NOT EXISTS (SELECT 1 FROM Atomar_Merkmal)
BEGIN
    INSERT INTO Atomar_Merkmal (MerkmalName, Einheit) VALUES
    ('Kaufkraftindex', 'Index'),
    ('Altersgruppe (mehrheitlich)', NULL),
    ('Kundenfrequenz pro Tag', 'Anzahl');
END
GO

-- ---------- Werte pro Standort und Merkmal ----------
INSERT INTO Atomar_Wert (StandortKey, MerkmalID, Wert)
SELECT s.StandortKey, m.MerkmalID,
    CASE m.MerkmalName
        WHEN 'Kaufkraftindex' THEN CAST(80 + (ABS(CHECKSUM(NEWID())) % 60) AS NVARCHAR)
        WHEN 'Altersgruppe (mehrheitlich)' THEN
            CASE ABS(CHECKSUM(NEWID())) % 3
                WHEN 0 THEN '20-35' WHEN 1 THEN '35-55' ELSE '55+'
            END
        WHEN 'Kundenfrequenz pro Tag' THEN CAST(150 + (ABS(CHECKSUM(NEWID())) % 400) AS NVARCHAR)
    END
FROM Dim_Standort s
CROSS JOIN Atomar_Merkmal m
WHERE NOT EXISTS (
    SELECT 1 FROM Atomar_Wert w WHERE w.StandortKey = s.StandortKey AND w.MerkmalID = m.MerkmalID
);
GO

-- ============================================
-- Kurzcheck
-- ============================================
SELECT COUNT(*) AS AnzahlWerte FROM Atomar_Wert;
SELECT TOP 5 ds.Name, m.MerkmalName, w.Wert
FROM Atomar_Wert w
JOIN Dim_Standort ds ON ds.StandortKey = w.StandortKey
JOIN Atomar_Merkmal m ON m.MerkmalID = w.MerkmalID
ORDER BY ds.Name;
