# ADR 0001: SwiftUI First

## Status

Accepted

## Kontext

BrickCanvas ist als Apple-Plattform-App mit SwiftUI als primärem UI-Stack angelegt. Fuer die kommenden PRs braucht das Projekt eine klare Regel, ob neue UI-Funktionen nativ in SwiftUI oder ueber UIKit beziehungsweise AppKit gebaut werden sollen.

Ohne eine explizite Entscheidung steigt das Risiko, dass:

- neue Screens uneinheitlich umgesetzt werden
- vermeidbare Bridge-Layer zwischen SwiftUI und UIKit/AppKit entstehen
- Architektur- und Testaufwand fuer UI-Code unnötig wachsen

## Entscheidung

BrickCanvas verwendet fuer neue UI-Implementierungen grundsaetzlich natives SwiftUI.

UIKit oder AppKit duerfen nur verwendet werden, wenn eine tragfaehige SwiftUI-Implementierung nicht moeglich ist oder wesentliche Produktanforderungen in SwiftUI nicht angemessen umgesetzt werden koennen.

Falls UIKit oder AppKit eingesetzt werden, muss die konkrete technische Begruendung im jeweiligen PR oder in einer nachgelagerten ADR dokumentiert werden.

## Konsequenzen

- Neue Screens, Navigation, Komponenten und Zustandsdarstellung sollen zuerst in SwiftUI entworfen werden.
- Gemeinsame UI-Muster sollen als SwiftUI-Kompositionen aufgebaut werden, nicht als UIKit-Wrapper ohne Not.
- Plattform-Bridge-Code ist die Ausnahme und muss bewusst klein gehalten werden.
- Review-Kommentare duerfen UIKit- oder AppKit-Einsatz ohne dokumentierte Begruendung zurueckweisen.

## Ausnahmen

Typische moegliche Ausnahmen sind:

- Plattform-APIs, die in SwiftUI nicht oder nicht ausreichend zugreifbar sind
- systemnahe Interaktionen, fuer die Apple nur UIKit- oder AppKit-Komponenten bereitstellt
- Performance- oder Integrationsfaelle, in denen ein SwiftUI-Ansatz nachweislich nicht tragfaehig ist

Auch in diesen Faellen bleibt SwiftUI die aeussere Integrationsschicht, sofern das praktikabel ist.

