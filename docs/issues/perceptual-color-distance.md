# Perzeptuelle Farbdistanz

Diese Notiz beschreibt den technischen Zuschnitt fuer PR 7 (`#12`): eine isolierte Distanz-Utility fuer spaeteres Farbmatching, ohne bereits den finalen Matcher zu bauen.

## Ziel

- RGB-Werte in einen Vergleichsfarbraum ueberfuehren
- eine deterministische Distanzfunktion bereitstellen
- den Nutzen gegenueber naiver RGB-Euklidik mit kleinen Tests absichern

## Gewaehlter Ansatz

- sRGB-Tripel werden zunaechst in lineares RGB ueberfuehrt
- danach erfolgt die Umrechnung nach CIE XYZ unter D65-Referenzweiss
- fuer den eigentlichen Vergleich werden CIE-Lab-Werte berechnet
- die Distanz wird in dieser PR als Delta-E-76-artige euklidische Distanz im Lab-Raum verwendet

## Warum dieser Zuschnitt

- klar isolierbar und gut unit-testbar
- deutlich naeher an wahrgenommener Farbaehnlichkeit als direkte RGB-Distanz
- ausreichend klein fuer diesen Slice, ohne schon die Matcher-Regeln aus PR 8 festzulegen

## Nicht Teil dieser PR

- keine Auswahl der naechsten LEGO-Farbe aus einer Palette
- kein Tie-Breaking zwischen gleich guten Kandidaten
- keine Optimierung oder Vorberechnung fuer grosse Batch-Konvertierungen

PR 8 kann auf dieser Utility direkt aufbauen und nur noch Matching-, Restriktions- und Tie-Breaking-Regeln ergaenzen.
