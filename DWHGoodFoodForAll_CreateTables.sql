-- ============================================
-- DWHGoodFoodForAll - Neuaufbau
-- Kimball-Sternschema + Atomarer Bereich (EAV)
--
-- Design-Entscheidung zu Schluesseln:
-- Alle drei Faktentabellen (Verkauf, Lieferung, Einkauf)
-- werden aus derselben externen CSV-Datei befuellt, nicht
-- aus der operativen ERP-DB. Die ERP-DB dient nur zum
-- Nachweis, dass das ERM funktioniert (3NF, Testdaten),
-- hat aber keine Verbindung zum DWH. Deshalb haben alle
-- Dimensionen bewusst KEINE ERP-ID, sondern werden beim
-- ETL-Laden ausschliesslich per NAME abgeglichen
-- (Dimension-Upsert: Name vorhanden -> Key verwenden,
-- sonst neu anlegen).
-- ============================================

CREATE DATABASE DWHGoodFoodForAll;
GO

USE DWHGoodFoodForAll;
GO

-- ============================================
-- Dimensionen
-- ============================================

CREATE TABLE Dim_Produkt (
    ProduktKey INT IDENTITY(1,1) PRIMARY KEY,
    Bezeichnung NVARCHAR(100) NOT NULL,
    Einheit NVARCHAR(20) NULL
);
GO

CREATE TABLE Dim_Standort (
    StandortKey INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Adresse NVARCHAR(200) NULL,
    FranchisenehmerName NVARCHAR(100) NULL
);
GO

CREATE TABLE Dim_Produzent (
    ProduzentKey INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Adresse NVARCHAR(200) NULL
);
GO

CREATE TABLE Dim_Zeit (
    ZeitKey INT PRIMARY KEY,          -- Smart Key im Format JJJJMMTT
    Datum DATE NOT NULL,
    Jahr INT NOT NULL,
    Monat INT NOT NULL,
    Kalenderwoche INT NOT NULL,
    Wochentag NVARCHAR(20) NOT NULL
);
GO

-- ============================================
-- Faktentabellen
-- ============================================

CREATE TABLE Fakt_Verkauf (
    VerkaufKey INT IDENTITY(1,1) PRIMARY KEY,
    ProduktKey INT NOT NULL,
    StandortKey INT NOT NULL,
    ZeitKey INT NOT NULL,
    Menge DECIMAL(10,2) NOT NULL,
    Umsatz DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_FaktVerkauf_Produkt FOREIGN KEY (ProduktKey) REFERENCES Dim_Produkt(ProduktKey),
    CONSTRAINT FK_FaktVerkauf_Standort FOREIGN KEY (StandortKey) REFERENCES Dim_Standort(StandortKey),
    CONSTRAINT FK_FaktVerkauf_Zeit FOREIGN KEY (ZeitKey) REFERENCES Dim_Zeit(ZeitKey)
);
GO

CREATE TABLE Fakt_Einkauf (
    EinkaufKey INT IDENTITY(1,1) PRIMARY KEY,
    ProduktKey INT NOT NULL,
    ProduzentKey INT NOT NULL,
    ZeitKey INT NOT NULL,
    Menge DECIMAL(10,2) NOT NULL,
    EinkaufsBetrag DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_FaktEinkauf_Produkt FOREIGN KEY (ProduktKey) REFERENCES Dim_Produkt(ProduktKey),
    CONSTRAINT FK_FaktEinkauf_Produzent FOREIGN KEY (ProduzentKey) REFERENCES Dim_Produzent(ProduzentKey),
    CONSTRAINT FK_FaktEinkauf_Zeit FOREIGN KEY (ZeitKey) REFERENCES Dim_Zeit(ZeitKey)
);
GO

CREATE TABLE Fakt_Lieferung (
    LieferungKey INT IDENTITY(1,1) PRIMARY KEY,
    ProduktKey INT NOT NULL,
    StandortKey INT NOT NULL,
    ZeitKey INT NOT NULL,
    Menge DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_FaktLieferung_Produkt FOREIGN KEY (ProduktKey) REFERENCES Dim_Produkt(ProduktKey),
    CONSTRAINT FK_FaktLieferung_Standort FOREIGN KEY (StandortKey) REFERENCES Dim_Standort(StandortKey),
    CONSTRAINT FK_FaktLieferung_Zeit FOREIGN KEY (ZeitKey) REFERENCES Dim_Zeit(ZeitKey)
);
GO

-- ============================================
-- Atomares Schema (EAV: Objekt-Merkmal-Wert)
-- Bezug: Dim_Standort
-- ============================================

CREATE TABLE Atomar_Merkmal (
    MerkmalID INT IDENTITY(1,1) PRIMARY KEY,
    MerkmalName NVARCHAR(50) NOT NULL,
    Einheit NVARCHAR(20) NULL
);
GO

CREATE TABLE Atomar_Wert (
    WertID INT IDENTITY(1,1) PRIMARY KEY,
    StandortKey INT NOT NULL,
    MerkmalID INT NOT NULL,
    Wert NVARCHAR(100) NOT NULL,
    CONSTRAINT FK_AtomarWert_Standort FOREIGN KEY (StandortKey) REFERENCES Dim_Standort(StandortKey),
    CONSTRAINT FK_AtomarWert_Merkmal FOREIGN KEY (MerkmalID) REFERENCES Atomar_Merkmal(MerkmalID)
);
GO

-- ============================================
-- Kurzcheck nach dem Erstellen
-- ============================================
SELECT 'Dim_Produkt' AS Tabelle, COUNT(*) AS AnzahlZeilen FROM Dim_Produkt
UNION ALL SELECT 'Dim_Standort', COUNT(*) FROM Dim_Standort
UNION ALL SELECT 'Dim_Produzent', COUNT(*) FROM Dim_Produzent
UNION ALL SELECT 'Dim_Zeit', COUNT(*) FROM Dim_Zeit
UNION ALL SELECT 'Fakt_Verkauf', COUNT(*) FROM Fakt_Verkauf
UNION ALL SELECT 'Fakt_Einkauf', COUNT(*) FROM Fakt_Einkauf
UNION ALL SELECT 'Fakt_Lieferung', COUNT(*) FROM Fakt_Lieferung
UNION ALL SELECT 'Atomar_Merkmal', COUNT(*) FROM Atomar_Merkmal
UNION ALL SELECT 'Atomar_Wert', COUNT(*) FROM Atomar_Wert;
