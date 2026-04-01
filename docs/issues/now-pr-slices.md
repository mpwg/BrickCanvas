# BrickCanvas Now-Issues: Empfohlene PR-Slice-Reihenfolge

Diese Reihenfolge zerlegt die aktuellen `Now`-Issues in kleine, mergebare Pull Requests. Ziel ist eine Serie von PRs mit klarer Verantwortung, wenig Überschneidung und niedriger Rework-Wahrscheinlichkeit.

## Grundsätze

- Jede PR sollte für sich reviewbar und mergebar sein.
- Zuerst Dokumentation und Schnittstellen, dann tragende Implementierungen.
- Datenmodelle und Modulgrenzen vor konkreter Pipeline-Logik festziehen.
- Farb- und Matching-Logik in separaten PRs halten, damit Verhalten isoliert testbar bleibt.
- Fixtures früh anlegen, damit Tests und visuelle Checks dieselbe Basis nutzen.

## Empfohlene PR-Reihenfolge

### PR 1 — MVP Flow und Architektur-Leitplanken

Bezieht sich auf:
- `#37`
- teilweise `#3`

Ziel:
- den End-to-End-Flow und die ersten Modulgrenzen schriftlich festziehen, bevor Code-Struktur und APIs konkret werden

Enthaltene Änderungen:
- Flow-Dokument für den MVP-Nutzerpfad
- Zustandsdefinitionen pro Screen/Schritt
- erste Architektur-Notiz mit Orchestrierungspunkt und Modulverantwortlichkeiten
- Liste offener Entscheidungen

Warum separat:
- minimiert spätere Strukturänderungen
- schafft ein Review-Artefakt für Produkt- und Architekturentscheidungen

Merge-Kriterium:
- Team/Owner sind sich auf Flow, Zustände und grobe Verantwortlichkeiten einig

### PR 2 — iOS App-Skelett und Navigationsrahmen

Bezieht sich auf:
- `#1`

Abhängig von:
- PR 1

Ziel:
- lauffähiges SwiftUI-Projekt mit Platzhalter-Navigation und sauberer Ordnerstruktur

Enthaltene Änderungen:
- Xcode-Projekt / App-Target
- Root-Navigation
- Platzhalter-Screens
- Basis-Projektstruktur
- Startansicht und Build-Verifikation

Warum separat:
- UI-Grundgerüst ist unabhängig von der späteren Pipeline-Logik reviewbar
- reduziert Konflikte mit Domain- und Algorithmus-PRs

Merge-Kriterium:
- App startet lokal und Navigationsrahmen steht

### PR 3 — Domainmodell-Grundlage

Bezieht sich auf:
- `#2`

Abhängig von:
- PR 1
- idealerweise PR 2 bereits gemergt

Ziel:
- stabile, UI-freie Kernmodelle für Projekt, Grid, Farben und Teile

Enthaltene Änderungen:
- Domänentypen
- Beispielinstanzen / Preview- und Testdaten-Builder
- Basiskommentare für Kernmodelle
- Serialisierbarkeits- und Identitätsentscheidungen

Warum separat:
- Modelle sind die Grundlage für fast alle Folge-PRs
- spätere Diff-Flut wird reduziert, wenn Typen zuerst stabil sind

Merge-Kriterium:
- Kernmodelle kompilieren und decken die MVP-Artefakte sauber ab

### PR 4 — Modulgrenzen und Service-Schnittstellen

Bezieht sich auf:
- Rest von `#3`

Abhängig von:
- PR 1
- PR 3

Ziel:
- technische Schichten und Modulverantwortungen in Code-nahes Design überführen

Enthaltene Änderungen:
- definierte Service-/Protocol-Schnittstellen
- Schichten- oder Modulübersicht
- klare Ownership von `ImageImport`, `Palette`, `ColorMatcher`, `MosaicGenerator`, `PartPlanner` etc.
- Abgrenzung Domain vs. Services vs. UI

Warum separat:
- verhindert, dass Implementierungs-PRs implizit Architektur festlegen
- erleichtert parallele Arbeit in späteren Tracks

Merge-Kriterium:
- Verantwortlichkeiten und öffentliche Schnittstellen sind klar dokumentiert

### PR 5 — Initiale LEGO-Farbpalette

Bezieht sich auf:
- `#11`

Abhängig von:
- PR 3
- PR 4

Ziel:
- kuratierte MVP-Palette als verwendbare Datenquelle einführen

Enthaltene Änderungen:
- Palette-Datensatz
- Lade-/Zugriffs-API
- Validierung auf eindeutige IDs und gültige Farbwerte
- kleine Anzeigehilfe oder Preview-Unterstützung

Warum separat:
- Datengrundlage für alle Farbalgorithmen
- leicht reviewbar ohne Algorithmuslogik

Merge-Kriterium:
- Palette ist versioniert, dokumentiert und konsumierbar

### PR 6 — Fixtures und Referenzfälle

Bezieht sich auf:
- `#39`

Abhängig von:
- PR 3
- PR 4

Ziel:
- reproduzierbare Beispielbilder und Referenzfälle für die Pipeline etablieren

Enthaltene Änderungen:
- Fixture-Assets
- Ablagestruktur und Konventionen
- Helper für Tests / QA
- dokumentierte Referenzfälle

Warum separat:
- schafft frühe Testbasis
- kann unabhängig von Farbdistanz und Matcher reviewed werden

Merge-Kriterium:
- Fixtures liegen im Repo und sind in mindestens einem Test-/QA-Pfad referenzierbar

### PR 7 — Perzeptuelle Farbdistanz-Utility

Bezieht sich auf:
- `#12`

Abhängig von:
- PR 5
- PR 6

Ziel:
- isolierte, getestete Distanzberechnung ohne bereits den vollständigen Matcher zu bauen

Enthaltene Änderungen:
- RGB-Konvertierung in Vergleichsfarbraum
- Distanzfunktion
- Vergleichstests gegen naive RGB-Distanz
- kurze technische Begründung der Metrik

Warum separat:
- mathematische Logik lässt sich isoliert besser reviewen
- Fehlerquelle klar vom eigentlichen Matching trennbar

Merge-Kriterium:
- Distanzfunktion ist deterministisch, dokumentiert und getestet

### PR 8 — Pixel-zu-LEGO-Matcher

Bezieht sich auf:
- `#13`

Abhängig von:
- PR 5
- PR 6
- PR 7

Ziel:
- vollständige Matching-API auf Basis von Palette und Distanzmetrik bereitstellen

Enthaltene Änderungen:
- Matching-API
- Palette-Restriktionen
- Tie-Breaking-Regeln
- repräsentative Matching-Tests
- optionale Performance-Optimierung oder Vorberechnung

Warum separat:
- das ist die erste wirklich produktkritische Algorithmus-PR
- sollte ohne UI- oder App-Strukturrauschen reviewt werden

Merge-Kriterium:
- Eingabepixel werden deterministisch und testbar auf erlaubte LEGO-Farben gemappt

## Was noch nicht in die Now-PR-Serie gehört

Diese Themen sollten erst in der nächsten Slice-Serie folgen:
- `#30` Tests für Color Matching als Ausbau/Vertiefung, falls nicht bereits vollständig in PR 7/8 enthalten
- `#4` Fotoimport
- `#6` Crop/Framing
- `#8` Mosaikgrößenwahl
- `#38` Lade- und Fehlerzustände

## Empfohlene Branch-/PR-Namen

1. `codex/mvp-flow-and-architecture`
2. `codex/ios-app-skeleton`
3. `codex/domain-model-foundation`
4. `codex/module-boundaries-and-interfaces`
5. `codex/lego-palette-dataset`
6. `codex/pipeline-fixtures`
7. `codex/perceptual-color-distance`
8. `codex/pixel-to-lego-matcher`

## Review-Strategie

- PR 1 bis 4: Fokus auf Struktur, Verantwortlichkeiten, Änderbarkeit
- PR 5 bis 6: Fokus auf Datenqualität und Reproduzierbarkeit
- PR 7 bis 8: Fokus auf Korrektheit, Determinismus und Testabdeckung

## Kurzfassung

Wenn nur die Reihenfolge gebraucht wird:

1. PR 1 — `#37` + Architektur-Leitplanken aus `#3`
2. PR 2 — `#1`
3. PR 3 — `#2`
4. PR 4 — Rest von `#3`
5. PR 5 — `#11`
6. PR 6 — `#39`
7. PR 7 — `#12`
8. PR 8 — `#13`
