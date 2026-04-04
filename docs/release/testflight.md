# TestFlight-Upload

Dieses Dokument beschreibt die erste reproduzierbare Release-Konfiguration für BrickCanvas, ohne persönliche Signing-Daten oder Team-IDs im Repository zu hinterlegen. Private Zertifikate und Provisioning Profiles werden über `fastlane match` aus einem separaten, verschlüsselten Storage bezogen.

## Ziele

- Bundle-Identifier unter `eu.mpwg`
- Universal-App für iPhone, iPad und macOS via Mac Catalyst
- reproduzierbare Archive für iOS und Mac Catalyst
- TestFlight-Upload über `fastlane`

## Bundle-Identifier

- App iPhone/iPad: `eu.mpwg.BrickCanvas`
- App Mac Catalyst: `eu.mpwg.BrickCanvas.mac`
- Tests: `eu.mpwg.BrickCanvasTests`

Das Namensschema lässt Raum für spätere Plattform-Ableitungen wie VisionOS, ohne das `eu.mpwg`-Präfix erneut aufzubrechen.

## Lokale Konfiguration

1. Ruby-Abhängigkeiten installieren:

```bash
bundle install
```

2. Fastlane-Umgebungsdatei anlegen:

```bash
cp fastlane/.env.example fastlane/.env
```

3. Persönliche oder organisationsinterne Werte ausschließlich lokal oder als CI-Secrets setzen:

- `BRICKCANVAS_DEVELOPMENT_TEAM`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_FILEPATH` oder `APP_STORE_CONNECT_API_KEY_CONTENT`
- `APP_STORE_CONNECT_APPLE_ID`
- `APP_STORE_CONNECT_TEAM_ID`
- `MATCH_GIT_URL`
- `MATCH_GIT_BRANCH`
- `MATCH_PASSWORD`
- `MATCH_READONLY`
- `MATCH_KEYCHAIN_NAME`
- `MATCH_KEYCHAIN_PASSWORD`
- `BRICKCANVAS_BETA_CHANGELOG`
- `BRICKCANVAS_BETA_DESCRIPTION`
- `BRICKCANVAS_BETA_FEEDBACK_EMAIL`

`fastlane/.env` ist absichtlich ignoriert, damit keine persönlichen Daten in GitHub landen.

## Signing mit match

- Zertifikate und Profiles liegen nicht in diesem Repository, sondern in einem separaten `match`-Storage, typischerweise einem verschlüsselten privaten Git-Repository.
- Die Entschlüsselung erfolgt über `MATCH_PASSWORD`.
- In CI sollte `MATCH_READONLY=1` gesetzt werden, damit bestehende Signing-Artefakte nur gelesen und nicht neu erzeugt werden.
- Die Bundle-Identifier `eu.mpwg.BrickCanvas` und `eu.mpwg.BrickCanvas.mac` werden gemeinsam über `match` synchronisiert.

## Release-Lanes

Xcode-Projekt erzeugen:

```bash
bundle exec fastlane ios generate_project
```

iOS- und Mac-Signing synchronisieren:

```bash
bundle exec fastlane ios sync_signing
```

iOS-Archiv erzeugen:

```bash
bundle exec fastlane ios archive_ios
```

Mac-Catalyst-Archiv erzeugen:

```bash
bundle exec fastlane ios archive_catalyst
```

TestFlight-Upload durchführen:

```bash
bundle exec fastlane ios beta
```

## CI-Hinweis

Für CI sollten dieselben Werte als Secret hinterlegt werden. Unsignierte Archive können ohne Secrets gebaut werden, vollständige TestFlight-Uploads benötigen jedoch gültige `match`-, Signing- und App-Store-Connect-Zugangsdaten.

## Offene App-Store-Connect-Metadaten

Die folgenden Produktangaben sind nicht aus dem Code ableitbar und müssen in App Store Connect gepflegt oder als Arbeitsgrundlage abgestimmt werden:

- primäre Sprache
- Kategorie
- Copyright
- Support-URL
- Marketing-URL
- Datenschutz-URL
- Altersfreigabe und Inhaltsangaben
- TestFlight-Beschreibung
- „Was getestet werden soll“
- Feedback-E-Mail
- optionale Demo-Zugangsdaten
- Screenshots und finale App-Icons
