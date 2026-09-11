USE GoodFoodForAll;
GO

-- ============================================
-- Testdaten für GoodFoodForAll
-- 5 Standorte, 10 Produkte, 3 Produzenten
-- ============================================

-- ---------- Produzent ----------
INSERT INTO Produzent (Name, Adresse) VALUES
('Bio Gmüeshof Müller', 'Dorfstrasse 12, 3011 Bern'),
('Hofladen Kunz', 'Landstrasse 4, 8001 Zürich'),
('Ökofarm Steiner', 'Bauernweg 7, 4001 Basel');

-- ---------- Produkt ----------
-- 10 Produkte, davon einige nur an bestimmten Standorten geliefert/verkauft
INSERT INTO Produkt (Bezeichnung, Einheit) VALUES
('Tomaten', 'kg'),
('Gurken', 'kg'),
('Karotten', 'kg'),
('Zucchetti', 'kg'),
('Kopfsalat', 'Stück'),
('Kartoffeln', 'kg'),
('Zwiebeln', 'kg'),
('Randen', 'kg'),
('Peperoni', 'kg'),      -- nur in Bern verkauft
('Broccoli', 'kg');      -- nur in Zürich verkauft

-- ---------- Standort ----------
INSERT INTO Standort (Name, Adresse, FranchisenehmerName) VALUES
('Kiosk Bern Bahnhof', 'Bahnhofplatz 1, 3011 Bern', 'Anna Frei'),
('Kiosk Zürich HB', 'Bahnhofplatz 15, 8001 Zürich', 'Marco Bieri'),
('Kiosk Basel SBB', 'Centralbahnplatz 3, 4051 Basel', 'Sara Meier'),
('Kiosk Luzern Bahnhof', 'Zentralstrasse 5, 6003 Luzern', 'Tom Iten'),
('Kiosk Thun Bahnhof', 'Bahnhofstrasse 2, 3600 Thun', 'Lea Wenger');

-- ============================================
-- Einkauf: GoodFoodForAll kauft zentral bei den Produzenten ein
-- ============================================
INSERT INTO Einkauf (ProduzentID, ProduktID, Datum, Menge, Preis) VALUES
(1, 1, '2026-08-03', 80.0, 160.00),   -- Müller liefert Tomaten
(1, 2, '2026-08-03', 50.0, 75.00),    -- Müller liefert Gurken
(1, 9, '2026-08-03', 20.0, 60.00),    -- Müller liefert Peperoni
(2, 3, '2026-08-04', 60.0, 54.00),    -- Kunz liefert Karotten
(2, 4, '2026-08-04', 40.0, 68.00),    -- Kunz liefert Zucchetti
(2, 10, '2026-08-04', 15.0, 45.00),   -- Kunz liefert Broccoli
(3, 5, '2026-08-05', 100.0, 90.00),   -- Steiner liefert Kopfsalat (Stück, hier vereinfacht als Menge)
(3, 6, '2026-08-05', 120.0, 84.00),   -- Steiner liefert Kartoffeln
(3, 7, '2026-08-05', 45.0, 40.50),    -- Steiner liefert Zwiebeln
(3, 8, '2026-08-05', 30.0, 36.00);    -- Steiner liefert Randen

-- ============================================
-- Lieferung: GoodFoodForAll beliefert die Standorte
-- Peperoni (9) nur nach Bern, Broccoli (10) nur nach Zürich
-- ============================================
INSERT INTO Lieferung (StandortID, ProduktID, Datum, Menge) VALUES
-- Bern
(1, 1, '2026-08-06', 20.0),
(1, 2, '2026-08-06', 12.0),
(1, 3, '2026-08-06', 15.0),
(1, 9, '2026-08-06', 20.0),  -- Peperoni exklusiv Bern
-- Zürich
(2, 1, '2026-08-06', 18.0),
(2, 4, '2026-08-06', 10.0),
(2, 6, '2026-08-06', 25.0),
(2, 10, '2026-08-06', 15.0), -- Broccoli exklusiv Zürich
-- Basel
(3, 2, '2026-08-06', 10.0),
(3, 3, '2026-08-06', 12.0),
(3, 7, '2026-08-06', 15.0),
-- Luzern
(4, 5, '2026-08-06', 25.0),
(4, 6, '2026-08-06', 20.0),
(4, 8, '2026-08-06', 10.0),
-- Thun
(5, 1, '2026-08-06', 10.0),
(5, 5, '2026-08-06', 20.0),
(5, 7, '2026-08-06', 15.0);

-- ============================================
-- Verkauf: Standorte verkaufen an Kunden
-- (bewusst etwas weniger als geliefert, damit F08 "nicht verkaufte Produkte" auswertbar ist)
-- ============================================
INSERT INTO Verkauf (StandortID, ProduktID, Datum, Menge, Preis) VALUES
-- Bern
(1, 1, '2026-08-07', 16.0, 48.00),
(1, 2, '2026-08-07', 9.0, 22.50),
(1, 3, '2026-08-07', 15.0, 22.50),
(1, 9, '2026-08-07', 14.0, 56.00),
-- Zürich
(2, 1, '2026-08-07', 18.0, 54.00),
(2, 4, '2026-08-07', 7.0, 17.50),
(2, 6, '2026-08-07', 25.0, 37.50),
(2, 10, '2026-08-07', 9.0, 31.50),
-- Basel
(3, 2, '2026-08-07', 10.0, 25.00),
(3, 3, '2026-08-07', 8.0, 12.00),
(3, 7, '2026-08-07', 15.0, 18.75),
-- Luzern
(4, 5, '2026-08-07', 22.0, 33.00),
(4, 6, '2026-08-07', 20.0, 30.00),
(4, 8, '2026-08-07', 6.0, 10.80),
-- Thun
(5, 1, '2026-08-07', 10.0, 30.00),
(5, 5, '2026-08-07', 17.0, 25.50),
(5, 7, '2026-08-07', 15.0, 18.75);

-- ============================================
-- Zahlung: 80% des Verkaufsumsatzes pro Produzent/Produkt für den Zeitraum
-- (hier direkt eingefügt zur Veranschaulichung; im ETL/Report wird das später berechnet)
-- ============================================
INSERT INTO Zahlung (ProduzentID, ProduktID, ZeitraumVon, ZeitraumBis, Betrag) VALUES
(1, 1, '2026-08-01', '2026-08-07', 106.40),  -- Tomaten (Bern+Zürich+Thun) * 80%
(1, 2, '2026-08-01', '2026-08-07', 38.00),   -- Gurken (Bern+Basel) * 80%
(1, 9, '2026-08-01', '2026-08-07', 44.80),   -- Peperoni * 80%
(2, 3, '2026-08-01', '2026-08-07', 27.60),   -- Karotten * 80%
(2, 4, '2026-08-01', '2026-08-07', 14.00),   -- Zucchetti * 80%
(2, 10, '2026-08-01', '2026-08-07', 25.20),  -- Broccoli * 80%
(3, 5, '2026-08-01', '2026-08-07', 46.80),   -- Kopfsalat * 80%
(3, 6, '2026-08-01', '2026-08-07', 54.00),   -- Kartoffeln * 80%
(3, 7, '2026-08-01', '2026-08-07', 30.00),   -- Zwiebeln * 80%
(3, 8, '2026-08-01', '2026-08-07', 8.64);    -- Randen * 80%
GO

-- ============================================
-- Kurzcheck nach dem Befüllen
-- ============================================
SELECT 'Produzent' AS Tabelle, COUNT(*) AS AnzahlZeilen FROM Produzent
UNION ALL SELECT 'Produkt', COUNT(*) FROM Produkt
UNION ALL SELECT 'Standort', COUNT(*) FROM Standort
UNION ALL SELECT 'Einkauf', COUNT(*) FROM Einkauf
UNION ALL SELECT 'Lieferung', COUNT(*) FROM Lieferung
UNION ALL SELECT 'Verkauf', COUNT(*) FROM Verkauf
UNION ALL SELECT 'Zahlung', COUNT(*) FROM Zahlung;
