# Zense Mail Signature

Zentral gehostete E-Mail-Signatur fur das Zense-Team. Eine Signatur, automatisch personalisiert.

## So funktioniert es

1. **Ein Template** (`signature-template.html`) mit Platzhaltern `{{NAME}}`, `{{ROLE}}`, `{{PHONE}}`
2. **Team-Daten** (`team.json`) mit personalisierten Infos pro Person
3. **GitHub Action** generiert bei jedem Push automatisch alle Signaturen
4. **GitHub Pages** hostet die fertigen Signaturen + Assets (Logo, Icons)

## Signatur installieren (einmalig)

Jedes Teammitglied macht das einmal:

### Vorbereitung
1. Apple Mail offnen > Einstellungen > Signaturen
2. Neue Signatur erstellen mit dem Text `PLACEHOLDER`
3. Apple Mail schliessen (Cmd+Q)

### Installation
```bash
curl -sL https://zense-gmbh.github.io/mail-signature/install.sh | bash -s DEINE_ID
```

Beispiel:
```bash
curl -sL https://zense-gmbh.github.io/mail-signature/install.sh | bash -s janick
```

Fertig. Apple Mail offnen - Signatur ist aktiv.

## Signatur andern

Wenn sich etwas andern soll (Banner, Layout, Farben, Icons):

1. Template oder Assets andern und pushen
2. GitHub Action generiert automatisch alle neuen Signaturen
3. **Bilder/Assets**: Andern sich sofort in allen Mails (via GitHub Pages URL)
4. **HTML/Text**: Jede Person fuhrt einmal den Install-Befehl aus

## Neue Person hinzufugen

In `team.json` einen Eintrag erganzen:

```json
{
  "id": "vorname",
  "name": "Vorname Nachname",
  "role": "Rolle"
}
```

Ohne `phone` wird automatisch die Buronummer +41 44 521 73 90 verwendet.

## Lokal testen

```bash
python3 generate.py           # Alle Signaturen generieren
python3 generate.py janick    # Nur eine Person
```

Die Signaturen landen in `output/`.
