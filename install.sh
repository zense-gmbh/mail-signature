#!/bin/bash
#
# Zense Mail Signature Installer + Auto-Updater
#
# Einmalig ausfuehren:
#   curl -sL https://zense-gmbh.github.io/mail-signature/install.sh | bash -s VORNAME
#
# Beispiel:
#   curl -sL https://zense-gmbh.github.io/mail-signature/install.sh | bash -s janick
#

set -e

MEMBER_ID="${1}"
BASE_URL="https://zense-gmbh.github.io/mail-signature"
SIG_URL="${BASE_URL}/signatures/${MEMBER_ID}.html"
UPDATER_DIR="$HOME/.zense-signature"
UPDATER_SCRIPT="$UPDATER_DIR/update-signature.sh"
PLIST_NAME="ch.zense.mail-signature"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

if [ -z "$MEMBER_ID" ]; then
  echo ""
  echo "Usage: curl -sL ${BASE_URL}/install.sh | bash -s VORNAME"
  echo "  z.B.: curl -sL ${BASE_URL}/install.sh | bash -s janick"
  echo ""
  echo "Alle verfuegbaren Signaturen: ${BASE_URL}/signatures/"
  exit 1
fi

echo ""
echo "=== Zense Mail Signature Installer ==="
echo "Mitarbeiter: ${MEMBER_ID}"
echo ""

# Download signature
echo "Lade Signatur herunter..."
SIG_HTML=$(curl -sL "${SIG_URL}")

if [ -z "$SIG_HTML" ] || echo "$SIG_HTML" | grep -q "404"; then
  echo "FEHLER: Keine Signatur gefunden fuer '${MEMBER_ID}'"
  echo "Verfuegbare Signaturen: ${BASE_URL}/signatures/"
  exit 1
fi
echo "OK"

# Find Apple Mail Signatures directory
MAIL_BASE="${HOME}/Library/Mail"
SIG_DIR=""
for vdir in $(ls -d "${MAIL_BASE}"/V* 2>/dev/null | sort -rV); do
  candidate="${vdir}/MailData/Signatures"
  if [ -d "$candidate" ]; then
    SIG_DIR="$candidate"
    break
  fi
done

if [ -z "$SIG_DIR" ]; then
  echo ""
  echo "FEHLER: Apple Mail Signaturen-Ordner nicht gefunden."
  echo ""
  echo "Bitte zuerst in Apple Mail:"
  echo "  1. Einstellungen > Signaturen"
  echo "  2. Klicke '+' fuer neue Signatur"
  echo "  3. Schreibe 'PLACEHOLDER' als Text"
  echo "  4. Schliesse Apple Mail (Cmd+Q)"
  echo "  5. Fuehre dieses Script erneut aus"
  exit 1
fi

# Close Apple Mail if running
if pgrep -x "Mail" > /dev/null 2>&1; then
  echo "Apple Mail wird geschlossen..."
  osascript -e 'quit app "Mail"'
  sleep 2
fi

# Find .mailsignature files
SIG_FILES=($(ls "${SIG_DIR}"/*.mailsignature 2>/dev/null))

if [ ${#SIG_FILES[@]} -eq 0 ]; then
  echo ""
  echo "FEHLER: Keine .mailsignature Dateien gefunden."
  echo "Erstelle zuerst eine Platzhalter-Signatur in Apple Mail."
  exit 1
fi

# Pick the target file
if [ ${#SIG_FILES[@]} -eq 1 ]; then
  TARGET="${SIG_FILES[0]}"
else
  # Try to find PLACEHOLDER first
  TARGET=""
  for f in "${SIG_FILES[@]}"; do
    if grep -qi "PLACEHOLDER" "$f" 2>/dev/null; then
      TARGET="$f"
      break
    fi
  done
  if [ -z "$TARGET" ]; then
    echo "Mehrere Signaturen gefunden:"
    for i in "${!SIG_FILES[@]}"; do
      echo "  [${i}] $(basename "${SIG_FILES[$i]}")"
    done
    read -p "Welche ersetzen? Nummer eingeben: " choice
    TARGET="${SIG_FILES[$choice]}"
  fi
fi

echo "Ziel: $(basename ${TARGET})"

# Install signature
chflags nouchg "${TARGET}" 2>/dev/null || true
HEADER=$(awk '/^Mime-Version:/{print; exit} {print}' "${TARGET}")
{
  echo "${HEADER}"
  echo ""
  echo "${SIG_HTML}"
} > "${TARGET}"
chflags uchg "${TARGET}"
echo "Signatur installiert!"

# --- Auto-Updater Setup ---
echo ""
echo "Auto-Updater wird eingerichtet..."
mkdir -p "$UPDATER_DIR"
mkdir -p "$HOME/Library/LaunchAgents"

# Create updater script
cat > "$UPDATER_SCRIPT" << 'UPDATER_HEADER'
#!/bin/bash
# Zense Signature Auto-Updater (runs daily + on login)
UPDATER_HEADER

cat >> "$UPDATER_SCRIPT" << UPDATER_VARS
SIG_URL="${SIG_URL}"
TARGET="${TARGET}"
LOG="${UPDATER_DIR}/update.log"
UPDATER_VARS

cat >> "$UPDATER_SCRIPT" << 'UPDATER_BODY'

echo "$(date): Checking for signature update..." >> "$LOG"

# Don't update while Mail is open
if pgrep -x "Mail" > /dev/null 2>&1; then
  echo "$(date): Mail is running, skipping." >> "$LOG"
  exit 0
fi

# Download latest
NEW_HTML=$(curl -sL "$SIG_URL")
if [ -z "$NEW_HTML" ]; then
  echo "$(date): Download failed, skipping." >> "$LOG"
  exit 1
fi

# Compare with current (extract HTML part after header)
CURRENT_HTML=$(sed '1,/^$/d' "$TARGET" 2>/dev/null)
if [ "$NEW_HTML" = "$CURRENT_HTML" ]; then
  echo "$(date): No changes." >> "$LOG"
  exit 0
fi

# Update signature
chflags nouchg "$TARGET" 2>/dev/null || true
HEADER=$(awk '/^Mime-Version:/{print; exit} {print}' "$TARGET")
{
  echo "$HEADER"
  echo ""
  echo "$NEW_HTML"
} > "$TARGET"
chflags uchg "$TARGET"

echo "$(date): Signature updated!" >> "$LOG"
UPDATER_BODY

chmod +x "$UPDATER_SCRIPT"

# Create LaunchAgent plist
cat > "$PLIST_PATH" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${UPDATER_SCRIPT}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>86400</integer>
    <key>StandardOutPath</key>
    <string>${UPDATER_DIR}/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${UPDATER_DIR}/stderr.log</string>
</dict>
</plist>
PLIST

# Load LaunchAgent
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "Auto-Updater aktiv!"
echo ""
echo "=== Fertig! ==="
echo ""
echo "Deine Signatur ist jetzt installiert und wird automatisch"
echo "bei jedem Login und taeglich aktualisiert."
echo ""
echo "Oeffne Apple Mail und setze die Signatur als Standard:"
echo "  Einstellungen > Signaturen > Dein Account > Standard-Signatur"
echo ""
