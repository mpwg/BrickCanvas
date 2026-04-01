# BrickCanvas Architektur-Leitplanken (MVP)

Dieses Dokument definiert die minimalen Architekturregeln für den BrickCanvas-MVP. Ziel ist eine klare Trennung zwischen UI, Orchestrierung, Domäne und technischen Services, damit spätere Implementierungen ohne große Umbauten möglich bleiben.

Relevante Architekturentscheidungen:
- `docs/adr/0001-swiftui-first.md`

## Architekturziele

- End-to-End-Flow aus `docs/issues/mvp-flow.md` stabil umsetzbar halten
- Verantwortlichkeiten pro Modul früh festziehen
- Algorithmische Logik von UI-Code trennen
- Persistenz und Export als austauschbare Infrastruktur behandeln

## Schichtenmodell

### 1. UI / Feature Layer

Beispiele:
- `Home`
- `New Project / Import`
- `Crop & Frame`
- `Mosaic Configuration`
- `Mosaic Result`
- `Part Summary`
- `Build Plan`

Verantwortung:
- Darstellung
- Nutzerinteraktionen
- lokale, kurzlebige View-Zustände
- neue UI-Implementierungen standardmäßig in SwiftUI

Nicht verantwortlich für:
- Farbmatching-Algorithmik
- Mosaik-Generierung
- Speicher-/Export-Details

Zusatzregel:
- UIKit oder AppKit sind nur zulässig, wenn keine tragfähige SwiftUI-Implementierung möglich ist. Siehe `docs/adr/0001-swiftui-first.md`.

### 2. Workflow / Orchestration Layer

Empfohlener Typ:
- `ProjectWorkflowCoordinator` (Name noch offen)

Verantwortung:
- Screen-Übergänge gemäß MVP-Flow
- Verwaltung des Projekt-Lebenszyklus (`Draft` → `Generated` → `Saved`)
- Aufrufreihenfolge der Services
- Fehler- und Ladezustände als UI-konsumierbarer Zustand

Regel:
- Features sprechen nicht direkt miteinander, sondern über den Orchestrator.

### 3. Domain Layer

Verantwortung:
- Kernmodelle (Projekt, Grid, Farben, Teileliste, Bauplan-Artefakte)
- Invarianten und semantische Typen
- Serialisierung auf Modellebene (wo sinnvoll)

Regel:
- Keine UI- oder Framework-Abhängigkeiten in den Modellen.

### 4. Service Layer

Geplante Service-Gruppen:
- `ImageImportService`
- `PaletteService`
- `ColorMatcherService`
- `MosaicGeneratorService`
- `PartPlannerService`
- `ExportEngine`
- `ProjectStorage`

Verantwortung:
- konkrete technische oder algorithmische Arbeit
- klar definierte Ein-/Ausgaben über Protokolle/Interfaces

Regel:
- Services kennen einander nur über explizite Schnittstellen.

Geplante Contract-Einstiegspunkte:
- `ImageImportService.importImage(_:)`
- `PaletteService.availablePalettes()` und `PaletteService.palette(for:)`
- `ColorMatcherService.nearestColor(for:)`
- `MosaicGeneratorService.generateMosaic(from:)`
- `PartPlannerService.planParts(for:)`
- `ExportEngine.export(_:)`
- `ProjectStorage.save(_:)`, `loadProject(id:)`, `listProjects()`, `deleteProject(id:)`

Verantwortung pro Service:
- `ImageImportService`: importiert und normalisiert Rohbilddaten in ein UI-freies Service-Artefakt
- `PaletteService`: liefert versionierte Farbpaletten und Palette-Metadaten
- `ColorMatcherService`: mappt einzelne Farbproben deterministisch auf erlaubte Brick-Farben
- `MosaicGeneratorService`: erzeugt das zentrale `MosaicGrid` aus Bild, Crop und Konfiguration
- `PartPlannerService`: leitet Teileanforderungen aus einem Grid ab
- `ExportEngine`: erzeugt exportierbare Dateien aus Projektartefakten
- `ProjectStorage`: persistiert und lädt Projekte unabhaengig von UI und Export

## Abhängigkeitsregeln

Erlaubte Richtung:
- UI → Orchestrator → Services + Domain
- Services → Domain

Nicht erlaubt:
- Domain → UI
- Domain → konkrete Infrastruktur
- UI → tiefe Service-Implementierungsdetails
- Feature A → Feature B (direkte Kopplung)
- Service-Implementierung A → Service-Implementierung B ohne Protokollgrenze

## Datenfluss im MVP

1. Import liefert normalisiertes Quellbild.
2. Crop liefert Bildausschnitt und Framing-Parameter.
3. Konfiguration liefert Zielgröße und Konvertierungsoptionen.
4. Generierung liefert Grid, Vorschauzustand und Teilebasis.
5. Teileplanung liefert aggregierte Teileliste.
6. Bauplan-Service liefert baubare Schritt-/Rasterdarstellung.
7. Storage/Export persistiert oder exportiert Projektartefakte.

## Fehler- und Zustandsmodell

- Jede Workflow-Phase hat mindestens: `Idle`, `Running`, `Success`, `Error`.
- Fehler werden im Orchestrator in einen UI-tauglichen, domänennahen Fehlerzustand gemappt.
- UI zeigt Fehler an, entscheidet aber nicht über Recovery-Strategien.
- Service-Grenzen liefern fachliche Fehler über klar benannte Contract-Fehler oder domänennahe Fehlerzustände.

## Service-Design-Regeln

- Service-Protokolle bleiben klein und fokussiert.
- Ein Service soll nur einen fachlichen Verantwortungsbereich besitzen.
- Requests und Responses bleiben `Sendable` und UI-frei.
- UIKit oder SwiftUI-Typen dürfen nicht durch Service- oder Storage-Verträge leaken.
- Konkrete Implementierungen leben spaeter hinter diesen Protokollen und bleiben austauschbar.

## Testleitplanken

- Domain-Modelle: deterministische Unit-Tests
- Service-Verträge: Contract-Tests gegen Schnittstellen
- Workflow: Zustandsübergangs-Tests (Flow-Szenarien)
- UI: nur zustandsgetriebene Darstellungstests, keine Algorithmik-Tests

## Offene Architekturentscheidungen

- Ein zentraler globaler Coordinator vs. ein Coordinator pro Flow-Abschnitt
- Persistenzformat für Projekte (JSON-only vs. hybrid mit Binärartefakten)
- Synchrones vs. asynchrones Pipeline-Orchestrieren mit Abbruchfähigkeit
- Minimaler Umfang der Export-Engine im MVP (nur Bauplan oder inkl. Teileliste als separates Format)
