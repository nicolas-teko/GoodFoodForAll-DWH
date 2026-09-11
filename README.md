# GoodFoodForAll – DWH-Projektarbeit

Dieses Repository enthält alle SQL-Abfragen, Daten und Auswertungen, die im Rahmen der Projektarbeit "Wir bauen ein DWH" für die fiktive Firma GoodFoodForAll erarbeitet wurden (operative ERP-Datenbank, Data Warehouse mit Kimball-Sternschema und atomarem Bereich, ETL-Prozess, Auswertungen).

**Verwendete Werkzeuge:** Microsoft SQL Server (Express Edition) mit SQL Server Management Studio (SSMS), T-SQL, Microsoft Excel.

## Inhalt

| Datei | Beschreibung |
|---|---|
| `GoodFoodForAll_CreateTables.sql` | Erstellt die operative ERP-Datenbank (7 Tabellen) |
| `GoodFoodForAll_Testdaten.sql` | Befüllt die ERP-Datenbank mit Testdaten |
| `DWHGoodFoodForAll_CreateTables.sql` | Erstellt das DWH (Sternschema + atomarer Bereich) |
| `DWH_02_Staging_BulkInsert.sql` | Importiert die CSV in eine Staging-Tabelle |
| `DWH_03_Bereinigung.sql` | Bereinigt und validiert die Staging-Daten |
| `DWH_04_Dimension_Upsert.sql` | Befüllt die Dimensionen |
| `DWH_05_Fakten_Laden.sql` | Befüllt die Faktentabellen |
| `DWH_06b_Atomar_Befuellen.sql` | Befüllt den atomaren Bereich mit Standortstatistiken |
| `DWH_ETL_StoredProcedures_Gesamtprozess.sql` | Fasst den ganzen ETL-Prozess in Stored Procedures zusammen |
| `DWH_Auswertung_*.sql` | Die drei Auswertungsabfragen (Umsatz, Zahlung, Standortmerkmale) |
| `GoodFoodForAll_Import_75Standorte.csv` | Fiktive Import-Datei mit Verkaufs-, Lieferungs- und Einkaufsdaten für 75 Standorte |
| `Ergebnisse_*.csv` | Exportierte Ergebnisse der drei Auswertungen |
| `Auswertung_*.xlsx` | Excel-Dateien zur Veranschaulichung der Auswertungen (Tabelle + Diagramm) |

## Reihenfolge zum Nachvollziehen

1. `GoodFoodForAll_CreateTables.sql` → `GoodFoodForAll_Testdaten.sql`
2. `DWHGoodFoodForAll_CreateTables.sql`
3. `DWH_02` bis `DWH_06b` der Reihe nach, oder direkt `DWH_ETL_StoredProcedures_Gesamtprozess.sql` mit `EXEC usp_ETL_Gesamtprozess 'Pfad\zur\CSV.csv'`
4. Die drei `DWH_Auswertung_*.sql`-Abfragen
