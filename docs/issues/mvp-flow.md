# BrickCanvas MVP Flow

Dieses Dokument beschreibt den ersten belastbaren End-to-End-Flow für den BrickCanvas-MVP.

## Ziel

Ein Nutzer soll in einem linearen, verständlichen Ablauf von einem Eingabebild zu einem speicherbaren und exportierbaren LEGO-Mosaik geführt werden.

## Hauptfluss

1. Home
2. Neues Projekt starten
3. Bild importieren
4. Bild zuschneiden und ausrichten
5. Mosaik konfigurieren
6. Mosaik generieren
7. Ergebnis prüfen
8. Teileliste und Bauplan ansehen
9. Exportieren oder speichern

## Screens und Zustände

### 1. Home

Zweck:
- Einstiegspunkt der App
- Zugriff auf neue und bestehende Projekte

Eintritt:
- App-Start
- Rückkehr aus einem abgeschlossenen Flow

Austritt:
- `New Project`
- `Project List`
- `Settings`

Zustände:
- Standard: CTA für neues Projekt
- Leer: keine gespeicherten Projekte
- Befüllt: letzte oder gespeicherte Projekte sichtbar

### 2. New Project / Import

Zweck:
- Quelle für das Projektbild festlegen

Eintritt:
- aus `Home`

Austritt:
- erfolgreich importiertes Bild -> `Crop & Frame`
- Abbruch -> `Home`

Zustände:
- Idle: Importoptionen sichtbar
- Loading: Bild wird übernommen / normalisiert
- Error: Import fehlgeschlagen oder Berechtigung fehlt

### 3. Crop & Frame

Zweck:
- Bildausschnitt für das Mosaik festlegen

Eintritt:
- erfolgreich importiertes Bild

Austritt:
- bestätigter Zuschnitt -> `Mosaic Configuration`
- Zurück -> `New Project / Import`

Zustände:
- Editing: Pan, Zoom, Crop aktiv
- Preview: Ergebnis des Zuschnitts sichtbar
- Error: Bilddaten ungültig oder Zuschnitt nicht anwendbar

### 4. Mosaic Configuration

Zweck:
- Mosaikgröße und spätere Konvertierungsoptionen setzen

Eintritt:
- bestätigter Zuschnitt

Austritt:
- `Generate` -> `Generating`
- Zurück -> `Crop & Frame`

Zustände:
- Idle: Größe auswählbar
- Validation Error: Konfiguration unvollständig oder inkonsistent

### 5. Generating

Zweck:
- Bildpipeline orchestrieren

Eintritt:
- Benutzer startet Generierung

Austritt:
- Erfolg -> `Mosaic Result`
- Fehler -> zurück in `Mosaic Configuration` mit Fehlermeldung

Zustände:
- Running: Fortschritt oder Busy-Zustand
- Success: Grid, Vorschau und Teilebasis liegen vor
- Error: Pipelinefehler, leere Palette, Bildverarbeitungsfehler

### 6. Mosaic Result

Zweck:
- visuelle Prüfung des generierten Mosaiks

Eintritt:
- erfolgreiche Generierung

Austritt:
- `Parts` -> `Part Summary`
- `Build Plan` -> `Build Plan`
- `Save` -> Speichern
- `Export` -> Exportieren
- `Edit Settings` -> zurück zu `Mosaic Configuration`

Zustände:
- Ready: Vorschau sichtbar
- Regenerating: Einstellungen wurden geändert
- Error: Ergebnis kann nicht dargestellt werden

### 7. Part Summary

Zweck:
- Stückliste nach Farbe und Menge anzeigen

Eintritt:
- aus `Mosaic Result`

Austritt:
- zurück zu `Mosaic Result`
- weiter zu `Build Plan` oder `Export`

Zustände:
- Ready: Teileliste korrekt geladen
- Empty/Error: keine Teileinformationen verfügbar

### 8. Build Plan

Zweck:
- baubare Rasteransicht und Anweisungsausgabe anzeigen

Eintritt:
- aus `Mosaic Result` oder `Part Summary`

Austritt:
- zurück zu `Mosaic Result`
- weiter zu `Export`

Zustände:
- Ready: Bauplan gerendert
- Error: Plan kann nicht erzeugt oder dargestellt werden

### 9. Save / Export

Zweck:
- Projektdaten sichern oder Bauplan exportieren

Eintritt:
- aus `Mosaic Result`, `Part Summary` oder `Build Plan`

Austritt:
- Erfolg -> zurück zu Ergebnis oder Projektliste
- Fehler -> Rückkehr mit Fehlermeldung und Retry-Möglichkeit

Zustände:
- Saving / Exporting
- Success
- Error

## Projektlebenszyklus

### Draft Project
- existiert nach erfolgreichem Bildimport
- enthält Rohbild, Zuschnitt und Konfiguration in Arbeit

### Generated Project
- existiert nach erfolgreicher Mosaikgenerierung
- enthält Grid, Vorschaugrundlage, Teileliste und Bauplandaten

### Saved Project
- persistierte Version eines generierten Projekts
- kann aus Projektliste wieder geöffnet werden

## Orchestrierung

Empfohlener Orchestrierungspunkt:
- ein zentraler Workflow-/Coordinator-Typ auf App-Ebene

Verantwortung des Orchestrators:
- Screen-Übergänge
- Übergabe des aktuellen Projektzustands
- Starten der Bild- und Mosaikpipeline
- Fehler- und Ladezustände
- Übergang von Draft zu Generated zu Saved

## Datenübergaben

- `Import` liefert normalisiertes Quellbild
- `Crop & Frame` liefert zugeschnittenes Bild plus Framing-Parameter
- `Mosaic Configuration` liefert Zielgröße und Konvertierungsparameter
- `Generating` erzeugt Grid, Farbauflösung, Teilebasis und Vorschauzustand
- `Part Summary` konsumiert Teileanforderungen
- `Build Plan` konsumiert Grid plus Anzeigen-/Koordinatendaten
- `Save / Export` konsumiert Projektmodell plus Ergebnisartefakte

## Minimale offene Entscheidungen

- Soll `Settings` globale App-Einstellungen oder auch Projekt-Defaults enthalten?
- Wird ein Draft-Projekt schon vor der ersten Generierung lokal gesichert?
- Soll der Nutzer aus `Mosaic Result` direkt regenerieren oder erst zurück in die Konfiguration müssen?
- Reicht für den MVP eine lineare Navigation oder braucht es bereits Tab-/Split-Navigation?
