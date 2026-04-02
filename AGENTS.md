# AGENTS.md

## Arbeitsregeln

- Verwende deutsche Umlaute.
- Für neue UI-Implementierungen gilt `SwiftUI first`.
- `UIKit` oder `AppKit` dürfen nur verwendet werden, wenn eine tragfähige SwiftUI-Implementierung nicht möglich ist oder wesentliche Anforderungen anders nicht angemessen umgesetzt werden können.
- Jede Verwendung von `UIKit` oder `AppKit` muss im Pull Request oder in einer nachgelagerten ADR technisch begründet werden.
- Bestehende ADRs unter `docs/adr/` sind verbindlich und vor Änderungen an Architektur, UI-Stack oder Modulgrenzen zu prüfen.
- Wenn eine Änderung von einer bestehenden ADR abweicht oder eine neue Grundsatzentscheidung trifft, muss das im Pull Request dokumentiert und bei Bedarf durch eine neue oder aktualisierte ADR festgehalten werden.
- `project.yml` ist die einzige Quelle für das Xcode-Projekt.
- Generierte Dateien unter `BrickCanvas.xcodeproj/` werden nicht versioniert und bei Bedarf lokal oder in CI neu erzeugt.
- Für das Erzeugen des Projekts ist das Repo-Skript `scripts/generate-xcode-project.sh` zu verwenden.
- Nach jeder Änderung muss sofort ein Commit erstellt werden, damit ein sauberes Rollback auf eine vorherige Version möglich bleibt.
- Lokale Commits dürfen niemals direkt auf `main` erfolgen. Vor dem ersten Commit ist immer ein Arbeitsbranch zu erstellen und darauf zu committen.
- Verlinke Pull Requests immer mit den zugehörigen Issues.
- Wenn ein Pull Request ein Issue vollständig behebt, muss der Pull Request das Issue beim Merge automatisch schließen, zum Beispiel mit `Closes #123`.
- Prüfe nach Merges, ob Issues bereits automatisch geschlossen wurden oder manuell geschlossen werden müssen.
