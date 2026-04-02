# Pixel-zu-LEGO-Matcher

Diese Notiz beschreibt den Zuschnitt fuer PR 8 (`#13`): den ersten konkreten Matcher auf Basis der MVP-Palette und der perzeptuellen Distanzmetrik aus PR 7.

## Ziel

- beliebige Eingabepixel deterministisch auf eine erlaubte LEGO-Farbe abbilden
- optionale Restriktionen auf erlaubte Farb-IDs respektieren
- Tie-Breaking explizit festlegen, damit identische Eingaben stabil dieselben Ergebnisse liefern

## Matcher-Regeln in diesem Slice

1. Kandidatenbasis sind die aktiven Farben der uebergebenen Palette
2. falls `allowedColorIDs` gesetzt ist, wird auf diese Teilmenge eingeschraenkt
3. primaere Sortierung: perzeptuelle Distanz im CIE-Lab-Raum
4. erstes Tie-Breaking: naive RGB-Distanz
5. zweites Tie-Breaking: lexikographische `colorID`

## Warum diese Reihenfolge

- die perzeptuelle Distanz bleibt das fachliche Hauptkriterium
- die naive RGB-Distanz hilft bei exacten oder nahezu exacten Distanzgleichstaenden als zusaetzliche deterministische Ordnung
- `colorID` stellt auch bei vollkommen gleichen Farben oder Testpaletten ein stabiles Endergebnis sicher

## Abdeckung in Tests

- Fixture-basierte End-to-End-Mini-Faelle aus PR 6
- Restriktionen auf erlaubte Farben
- deterministisches Tie-Breaking
- Fehlerfall bei leerer Kandidatenmenge nach Restriktion

## Nicht Teil dieser PR

- Batch-Matching-Optimierungen
- Cache/Vorberechnung fuer grosse Bilder
- Integration in Grid-Generierung oder UI
