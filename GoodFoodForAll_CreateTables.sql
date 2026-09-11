-- ============================================
-- GoodFoodForAll - operative ERP-Prototyp-Datenbank
-- 7 Tabellen gemäss ERM (3. Normalform)
-- ============================================

CREATE DATABASE GoodFoodForAll;
GO

USE GoodFoodForAll;
GO

CREATE TABLE Produzent (
    ProduzentID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Adresse NVARCHAR(200) NOT NULL
);
GO

CREATE TABLE Produkt (
    ProduktID INT IDENTITY(1,1) PRIMARY KEY,
    Bezeichnung NVARCHAR(100) NOT NULL,
    Einheit NVARCHAR(20) NOT NULL
);
GO

CREATE TABLE Standort (
    StandortID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Adresse NVARCHAR(200) NOT NULL,
    FranchisenehmerName NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE Einkauf (
    EinkaufID INT IDENTITY(1,1) PRIMARY KEY,
    ProduzentID INT NOT NULL,
    ProduktID INT NOT NULL,
    Datum DATE NOT NULL,
    Menge DECIMAL(10,2) NOT NULL,
    Preis DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Einkauf_Produzent FOREIGN KEY (ProduzentID) REFERENCES Produzent(ProduzentID),
    CONSTRAINT FK_Einkauf_Produkt FOREIGN KEY (ProduktID) REFERENCES Produkt(ProduktID)
);
GO

CREATE TABLE Lieferung (
    LieferungID INT IDENTITY(1,1) PRIMARY KEY,
    StandortID INT NOT NULL,
    ProduktID INT NOT NULL,
    Datum DATE NOT NULL,
    Menge DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Lieferung_Standort FOREIGN KEY (StandortID) REFERENCES Standort(StandortID),
    CONSTRAINT FK_Lieferung_Produkt FOREIGN KEY (ProduktID) REFERENCES Produkt(ProduktID)
);
GO

CREATE TABLE Verkauf (
    VerkaufID INT IDENTITY(1,1) PRIMARY KEY,
    StandortID INT NOT NULL,
    ProduktID INT NOT NULL,
    Datum DATE NOT NULL,
    Menge DECIMAL(10,2) NOT NULL,
    Preis DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Verkauf_Standort FOREIGN KEY (StandortID) REFERENCES Standort(StandortID),
    CONSTRAINT FK_Verkauf_Produkt FOREIGN KEY (ProduktID) REFERENCES Produkt(ProduktID)
);
GO

CREATE TABLE Zahlung (
    ZahlungID INT IDENTITY(1,1) PRIMARY KEY,
    ProduzentID INT NOT NULL,
    ProduktID INT NOT NULL,
    ZeitraumVon DATE NOT NULL,
    ZeitraumBis DATE NOT NULL,
    Betrag DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Zahlung_Produzent FOREIGN KEY (ProduzentID) REFERENCES Produzent(ProduzentID),
    CONSTRAINT FK_Zahlung_Produkt FOREIGN KEY (ProduktID) REFERENCES Produkt(ProduktID)
);
GO
