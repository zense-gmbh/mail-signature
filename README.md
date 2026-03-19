# Zense Mail Signature

Zentral gehostete E-Mail-Signatur für das Zense-Team.

## Wie es funktioniert

1. **Template** (`signature-template.html`) - Die HTML-Signatur mit Platzhaltern
2. **Team** (`team.json`) - Personalisierte Daten pro Teammitglied
3. **Assets** (`assets/`) - Logo und Icons, gehostet via GitHub Pages
4. **Generator** (`generate.py`) - Erzeugt personalisierte Signaturen

## Signatur generieren

```bash
# Alle Signaturen generieren
python3 generate.py

# Nur für eine Person
python3 generate.py janick

# Generieren und direkt in Apple Mail installieren
python3 generate.py janick --install
```

## Erstmalige Einrichtung (Apple Mail)

1. Öffne Apple Mail > Einstellungen > Signaturen
2. Erstelle eine neue Signatur mit dem Text `PLACEHOLDER`
3. Schliesse Apple Mail (Cmd+Q)
4. Führe aus: `python3 generate.py DEIN_ID --install`
5. Öffne Apple Mail - die Signatur ist aktiv

## Änderungen vornehmen

Wenn sich etwas an der Signatur ändern soll (Banner, Layout, Icons):

1. Änderung in `signature-template.html` oder `assets/` vornehmen
2. Push zu GitHub
3. **Bilder/Assets**: Werden automatisch aktualisiert (via GitHub Pages URL)
4. **HTML-Struktur**: `python3 generate.py --install` erneut ausführen

## Assets aktualisieren

Bilder werden von GitHub Pages geladen:
`https://zense-gmbh.github.io/mail-signature/assets/`

Wenn du ein Asset (z.B. Logo) austauschst und pushst, wird es automatisch
in allen bestehenden Signaturen aktualisiert.
