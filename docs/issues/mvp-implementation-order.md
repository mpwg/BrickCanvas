# BrickCanvas MVP Umsetzungsreihenfolge mit Abhängigkeiten

Diese Reihenfolge priorisiert einen möglichst kurzen Weg zu einem benutzbaren MVP: vom App-Gerüst über die Bildpipeline bis zu Vorschau, Teileliste, Bauplan und lokaler Speicherung.

## Zielbild

Am Ende des kritischen Pfads soll ein Nutzer:
- ein Bild aus der Fotobibliothek importieren
- es zuschneiden
- eine Mosaikgröße wählen
- ein LEGO-farbreduziertes Mosaik erzeugen
- Vorschau, Teileliste und Bauplan sehen
- das Ergebnis als Bild exportieren
- das Projekt lokal speichern und wieder öffnen können

## Planungsprinzipien

- `P0` vor `P1` und `P2`, aber nur soweit echte Blocker vorliegen
- zuerst Architektur- und Pipeline-Entscheidungen, dann UI-Flächen darauf aufbauen
- Tests und Fixtures nicht ans Ende schieben, sondern direkt an die Kernalgorithmen koppeln
- Persistenz erst dann voll anbinden, wenn das Projektmodell und der Kern-Workflow stabil genug sind

## Priorisierte Reihenfolge

### Phase 0 — Leitplanken und Arbeitsbasis

1. `#37` Define end-to-end project workflow and screen states
   Abhängig von: nichts
   Blockiert: `#1`, `#4`, `#6`, `#8`, `#17`, `#20`, `#22`, `#24`, `#27`, `#28`, `#38`
   Warum zuerst: Ohne klaren End-to-End-Flow werden UI- und Pipeline-Entscheidungen früh auseinanderlaufen.

2. `#1` Set up iOS app skeleton
   Abhängig von: `#37`
   Blockiert: fast alle UI-bezogenen Issues
   Warum hier: Das App-Skelett schafft Navigationspunkte, Targets und die Integrationsfläche für die nächsten Schritte.

3. `#2` Define project domain models
   Abhängig von: `#37`
   Blockiert: `#11`, `#13`, `#16`, `#19`, `#22`, `#24`, `#27`
   Warum hier: Die Datenformen müssen vor Pipeline, Persistenz und Export stabilisiert werden.

4. `#3` Establish app module boundaries
   Abhängig von: `#1`, `#2`, `#37`
   Blockiert: nichts hart, reduziert aber Rework bei `#11` bis `#24`
   Warum früh: Kleine Investition mit hohem Hebel für saubere Verantwortlichkeiten.

### Phase 1 — Kernalgorithmik und Verifikation

5. `#11` Define initial LEGO color palette dataset
   Abhängig von: `#2`, `#3`
   Blockiert: `#12`, `#13`, `#10`
   Warum zuerst: Die Palette ist die Grundlage der gesamten Konvertierung.

6. `#39` Add deterministic sample fixtures for pipeline and preview validation
   Abhängig von: `#2`, `#3`
   Blockiert: nichts formal, erhöht aber die Sicherheit für `#12`, `#13`, `#15`, `#16`, `#17`, `#19`
   Warum hier: Fixtures müssen direkt verfügbar sein, wenn die Kernpipeline gebaut wird.

7. `#12` Implement perceptual color distance utility
   Abhängig von: `#11`, `#39`
   Blockiert: `#13`, `#30`
   Warum hier: Erst Distanzmetrik, dann tatsächliches Matching.

8. `#13` Implement pixel-to-LEGO color matcher
   Abhängig von: `#11`, `#12`, `#39`
   Blockiert: `#10`, `#16`, `#17`, `#19`, `#22`, `#30`
   Warum hier: Das ist der Kern der MVP-Qualität.

9. `#30` Add unit tests for color matching
   Abhängig von: `#12`, `#13`, `#39`
   Blockiert: nichts funktional, sollte aber vor breiter UI-Integration abgeschlossen sein
   Warum hier: Farbqualität ist ein Hauptproduktrisiko und darf nicht ungetestet bleiben.

### Phase 2 — Import und Eingangsdaten

10. `#4` Import photo from library
    Abhängig von: `#1`, `#37`
    Blockiert: `#6`, indirekt den gesamten Nutzerfluss
    Warum hier: Fotobibliothek ist der schnellste MVP-Eingang; Kamera kann warten.

11. `#6` Build crop and framing UI
    Abhängig von: `#4`, `#37`
    Blockiert: `#15`, `#17`, `#22`
    Warum hier: Ohne reproduzierbaren Zuschnitt ist die Pipeline zwar technisch lauffähig, aber nicht nutzbar.

12. `#8` Add mosaic size selection
    Abhängig von: `#1`, `#2`, `#37`
    Blockiert: `#15`, `#16`, `#17`, `#22`
    Warum hier: Die Zielauflösung muss vor dem Resize feststehen.

13. `#38` Add loading, progress, and recoverable error states for core user flows
    Abhängig von: `#1`, `#4`, `#6`, `#8`, `#37`
    Blockiert: nichts formal, ist aber für einen benutzbaren MVP praktisch Pflicht
    Warum hier: Ab jetzt entstehen asynchrone Flows; Zustandsführung muss sichtbar werden.

### Phase 3 — Mosaikpipeline

14. `#15` Downsample crop to stud-aligned working raster
    Abhängig von: `#6`, `#8`
    Blockiert: `#16`
    Warum hier: Das direkte Downsampling aus dem Original-Crop liefert die fachlich sauberen Eingangsdaten für Quantisierung und Dithering.

15. `#16` Quantize working raster and generate mosaic grid
    Abhängig von: `#2`, `#13`, `#15`
    Blockiert: `#17`, `#18`, `#19`, `#22`, `#27`
    Warum hier: Hier entsteht das zentrale Artefakt für Vorschau, Teile und Bauplan inklusive der fachlich entscheidenden Palette-Quantisierung.

16. `#19` Create 1x1 part requirement generator
    Abhängig von: `#16`
    Blockiert: `#20`, `#22`, `#31`
    Warum hier: Teileplanung ist noch einfach und sollte direkt aus dem Grid folgen.

17. `#31` Add unit tests for parts counting
    Abhängig von: `#19`, `#39`
    Blockiert: nichts funktional, reduziert aber Risiko vor UI- und Export-Anbindung
    Warum hier: Falsche Stückzahlen machen den MVP praktisch unbrauchbar.

### Phase 4 — Nutzeroberfläche für Ergebnisse

18. `#17` Render interactive mosaic preview
    Abhängig von: `#16`, `#38`
    Blockiert: `#22`, `#24`, `#32`, `#33`
    Warum hier: Vorschau ist die zentrale Bestätigung für den Nutzer.

19. `#20` Add part requirement summary UI
    Abhängig von: `#19`, `#38`
    Blockiert: `#24`, indirekt `#26`
    Warum hier: Teileliste ist eine Kern-MVP-Ausgabe.

20. `#22` Generate simple grid-based build plan
    Abhängig von: `#16`, `#17`, `#19`
    Blockiert: `#24`, indirekt `#26`
    Warum hier: Erst wenn Grid, Vorschau und Teile stimmen, lohnt sich der Bauplan.

21. `#24` Export build plan as image
    Abhängig von: `#17`, `#20`, `#22`, `#38`
    Blockiert: MVP-Exportziel erreicht
    Warum hier: Das ist der kleinste brauchbare Export für den ersten Release.

### Phase 5 — Projektpersistenz

22. `#27` Save projects locally
    Abhängig von: `#2`, `#16`, `#19`, `#22`
    Blockiert: `#28`, `#29`
    Warum hier: Speichern ist wichtig, aber erst sinnvoll, wenn die Kernartefakte stabil sind.

23. `#28` Build project list screen
    Abhängig von: `#27`, `#1`, `#37`
    Blockiert: MVP-Abschluss bei Wiederöffnung gespeicherter Projekte
    Warum hier: Erst nach echter Persistenz lohnt sich die Listenansicht.

## Kritischer Pfad für den kleinsten starken MVP

`#37 -> #1 -> #2 -> #11 -> #39 -> #12 -> #13 -> #4 -> #6 -> #8 -> #15 -> #16 -> #19 -> #17 -> #20 -> #22 -> #24 -> #27 -> #28 -> #30 -> #31 -> #38`

Hinweis: `#38` sollte praktisch parallel ab Phase 2 mitlaufen, auch wenn es logisch kein Datenblocker ist. Für reale MVP-Benutzbarkeit darf es nicht bis zum Ende warten.

## Empfohlene Parallelisierung

### Track A — Architektur und Domain
- `#37`, `#1`, `#2`, `#3`

### Track B — Farb- und Grid-Pipeline
- `#11`, `#39`, `#12`, `#13`, `#15`, `#16`, `#19`, `#30`, `#31`

### Track C — Nutzerfluss und UI
- `#4`, `#6`, `#8`, `#17`, `#20`, `#22`, `#24`, `#28`, `#38`

### Track D — Persistenz
- `#27` nach Stabilisierung von Domainmodell und Grid/Build-Output

## Was bewusst nicht im MVP-Kernpfad liegt

Diese Issues sind sinnvoll, aber nicht nötig, um den ersten brauchbaren Release zu liefern:
- `#5` Kamera
- `#7` Bildanpassungspresets
- `#9` Stilpresets
- `#10` Auswahl erlaubter Farbsets
- `#14` Vor-Quantisierung
- `#18` Koordinatensystem im Grid
- `#21` Kostenmodell-Platzhalter
- `#23` Quadrantenansicht
- `#25` CSV-Export
- `#26` PDF-Export
- `#29` Umbenennen/Löschen
- `#32` Performance-Benchmarking
- `#33` visuelle Regressionstests
- `#34` CONTRIBUTING
- `#35` Issue-Templates
- `#36` Label-/Milestone-Dokumentation

## Empfohlene Reihenfolge nach MVP

1. `#18` Add coordinate system to mosaic grid
2. `#23` Add quadrant-based instruction view for larger mosaics
3. `#25` Export parts list as CSV
4. `#26` Export build plan as PDF
5. `#10` Add allowed color set selection
6. `#9` Add style presets for conversion
7. `#5` Capture photo with camera
8. `#29` Add delete and rename project actions
9. `#32` Benchmark preview performance for target grid sizes
10. `#33` Add snapshot or visual regression checks for preview rendering
11. `#34` Add CONTRIBUTING and development notes
12. `#35` Add issue templates for feature and bug reports
13. `#36` Add GitHub labels and milestone plan documentation

## Kurzfassung für die Umsetzung

Wenn nur eine kompakte Arbeitsliste gebraucht wird, dann diese Reihenfolge:

1. `#37`
2. `#1`
3. `#2`
4. `#3`
5. `#11`
6. `#39`
7. `#12`
8. `#13`
9. `#30`
10. `#4`
11. `#6`
12. `#8`
13. `#38`
14. `#15`
15. `#16`
16. `#19`
17. `#31`
18. `#17`
19. `#20`
20. `#22`
21. `#24`
22. `#27`
23. `#28`
