# BrickCanvas Now-Issues: PR-Slice Change Scope

Dieses Dokument legt pro empfohlener PR-Slice den beabsichtigten Change Scope und die voraussichtlich betroffenen Dateien oder Pfade fest.

## PR 1 — MVP Flow und Architektur-Leitplanken

Bezieht sich auf:
- `#37`
- Teile von `#3`

Ziel-Dateien:
- `docs/issues/mvp-flow.md`
- `docs/issues/mvp-implementation-order.md`
- optional `README.md`
- optional `docs/architecture.md`

Nicht in dieser PR:
- kein ausführbarer App-Code außer minimalen Platzhaltern
- keine Domänenmodelle
- keine Algorithmik

## PR 2 — iOS App-Skelett und Navigationsrahmen

Bezieht sich auf:
- `#1`

Ziel-Pfade:
- `BrickCanvas.xcodeproj/`
- `BrickCanvas/`
- `BrickCanvas/App/`
- `BrickCanvas/Features/Home/`
- `BrickCanvas/Features/NewProject/`
- `BrickCanvas/Features/ProjectDetail/`
- `BrickCanvas/Features/Settings/`
- `Assets.xcassets/`
- `README.md`

Nicht in dieser PR:
- keine endgültigen Domainmodelle
- keine Pipeline-Logik

## PR 3 — Domainmodell-Grundlage

Bezieht sich auf:
- `#2`

Ziel-Pfade:
- `BrickCanvas/Domain/`
- `BrickCanvas/Domain/Models/`
- `BrickCanvas/Domain/Fixtures/`
- `BrickCanvas/Shared/PreviewData/`
- ggf. `BrickCanvasTests/Domain/`

Nicht in dieser PR:
- keine konkrete Bildimport- oder Matching-Implementierung
- keine UI-Features außer Preview/Test-Stubs

## PR 4 — Modulgrenzen und Service-Schnittstellen

Bezieht sich auf:
- Rest von `#3`

Ziel-Pfade:
- `docs/architecture.md`
- `BrickCanvas/Services/`
- `BrickCanvas/Services/ImageImport/`
- `BrickCanvas/Services/Palette/`
- `BrickCanvas/Services/ColorMatcher/`
- `BrickCanvas/Services/MosaicGenerator/`
- `BrickCanvas/Services/PartPlanner/`
- `BrickCanvas/Services/ExportEngine/`
- `BrickCanvas/Storage/`

Nicht in dieser PR:
- keine vollständigen Service-Implementierungen
- nur Protokolle, Contracts, Platzhalter und Struktur

## PR 5 — Initiale LEGO-Farbpalette

Bezieht sich auf:
- `#11`

Ziel-Pfade:
- `BrickCanvas/Domain/Palette/`
- `BrickCanvas/Resources/Palette/`
- `BrickCanvas/Services/Palette/`
- `BrickCanvasTests/Palette/`

Nicht in dieser PR:
- keine Distanzlogik
- kein vollständiger Matcher

## PR 6 — Fixtures und Referenzfälle

Bezieht sich auf:
- `#39`

Ziel-Pfade:
- `BrickCanvasTests/Fixtures/`
- `BrickCanvasTests/Support/`
- `docs/issues/fixtures.md`
- `Resources/Fixtures/` oder `BrickCanvas/Resources/Fixtures/`

Nicht in dieser PR:
- keine Algorithmusänderungen außerhalb der minimal nötigen Test-Helper

## PR 7 — Perzeptuelle Farbdistanz-Utility

Bezieht sich auf:
- `#12`

Ziel-Pfade:
- `BrickCanvas/Services/ColorMatcher/`
- `BrickCanvas/Shared/Color/`
- `BrickCanvasTests/ColorMatcher/`

Nicht in dieser PR:
- kein finaler Palette-Matcher mit Restriktionslogik
- keine UI-Integration

## PR 8 — Pixel-zu-LEGO-Matcher

Bezieht sich auf:
- `#13`

Ziel-Pfade:
- `BrickCanvas/Services/ColorMatcher/`
- `BrickCanvas/Domain/Palette/`
- `BrickCanvasTests/ColorMatcher/`

Nicht in dieser PR:
- keine Grid-Erzeugung
- keine Import-UI
- keine Teileplanung

## Konfliktvermeidung

- PR 3 und PR 4 sollten unterschiedliche Ownership behalten:
  - PR 3: Domänenmodelle
  - PR 4: Service-Schnittstellen und Architektur
- PR 5 bis PR 8 bauen aufeinander auf, sollten aber keine UI-Dateien anfassen.
- Dokumentationsdateien aus PR 1 sollten danach nur erweitert, nicht umstrukturiert werden.
