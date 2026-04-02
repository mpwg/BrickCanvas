# Fixtures und Referenzfaelle

Diese Datei beschreibt die deterministischen Beispiel-Faelle fuer PR 6 (`#39`), damit Pipeline-, Preview- und spaetere QA-Checks auf derselben Datengrundlage arbeiten.

## Ziele

- kleine, reviewbare Referenzfaelle im Repo versionieren
- Test- und spaetere Preview-Validierung auf dieselben erwarteten Artefakte ausrichten
- keine Algorithmuslogik vorwegnehmen, sondern nur stabile Eingabe-/Ausgabe-Faelle festhalten

## Ablage

- Katalog: `BrickCanvas/Resources/Fixtures/pipeline-fixtures-v1.json`
- Test-Support: `BrickCanvasTests/Support/PipelineFixtureSupport.swift`
- Referenztests: `BrickCanvasTests/Fixtures/PipelineFixtureCatalogTests.swift`

## Katalogformat

Jeder Fixture-Fall enthaelt:

- `id` und `name` als stabile Kennung
- `paletteID` fuer die erwartete Farbmenge
- `mosaicSize` und `cropRegion` als reproduzierbare Pipeline-Eingaben
- `sourcePixels` als kleine Hex-RGB-Matrix fuer deterministische Quellwerte
- `expectedColorRows` als erwartetes Farb-Grid
- `expectedPartRequirements` fuer Teilelisten-Checks
- `expectedBuildPlanRows` fuer einfache Bauplan-/Preview-Checks

## Aktuelle Referenzfaelle

- `warm-sunrise-4x4`: deckt den gemeinsamen 4x4-Domain-Fall ab und spiegelt Grid, Teileliste und Build Plan aus `DomainFixtures`
- `neutral-spectrum-3x2`: kleiner QA-Fall fuer neutrale und warme Farben mit geringer Datenmenge

## Konventionen

- IDs bleiben stabil, auch wenn spaeter weitere Felder hinzukommen
- Farbwerte in `sourcePixels` werden als `#RRGGBB` gespeichert
- Erwartete Zeilen sind stets oben nach unten und links nach rechts sortiert
- Teilanforderungen verwenden bereits die Domaintypen (`BrickPart`, `colorID`, `quantity`)

## Nicht Teil dieses Slices

- kein echter Bildimport
- keine Distanz- oder Matching-Implementierung
- keine visuelle Snapshot-Infrastruktur

Diese Referenzfaelle sollen die Grundlage fuer PR 7 und PR 8 bilden, ohne deren Implementierungsentscheidungen vorwegzunehmen.
