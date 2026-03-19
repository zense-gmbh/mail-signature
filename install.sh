#!/bin/bash
#
# Zense Mail Signature Installer
#
# Einmalig ausführen:
#   curl -sL https://zense-gmbh.github.io/mail-signature/install.sh | bash -s DEINE_ID
#
# Oder manuell:
#   ./install.sh janick
#

set -e

MEMBER_ID="${1}"
BASE_URL="https://zense-gmbh.github.io/mail-signature"

if [ -z "$MEMBER_ID" ]; then
  echo ""
  echo "Usage: ./install.sh <member_id>"
  echo "  e.g. ./install.sh janick"
  echo ""
  echo "Or via curl:"
  echo "  curl -sL ${BASE_URL}/install.sh | bash -s janick"
  echo ""
  exit 1
fi

echo ""
echo "=== Zense Mail Signature Installer ==="
echo "Installing signature for: ${MEMBER_ID}"
echo ""

# Download the signature HTML
SIG_URL="${BASE_URL}/signatures/${MEMBER_ID}.html"
echo "Downloading from: ${SIG_URL}"
SIG_HTML=$(curl -sL "${SIG_URL}")

if [ -z "$SIG_HTML" ] || echo "$SIG_HTML" | grep -q "404"; then
  echo "ERROR: Signature not found for '${MEMBER_ID}'"
  echo "Check team.json for available IDs."
  exit 1
fi

echo "OK - Signature downloaded"

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
  echo "ERROR: Apple Mail Signatures directory not found."
  echo ""
  echo "Please do this first:"
  echo "  1. Open Apple Mail > Settings > Signatures"
  echo "  2. Create a new signature with text: PLACEHOLDER"
  echo "  3. Close Apple Mail (Cmd+Q)"
  echo "  4. Run this script again"
  exit 1
fi

echo "Signatures directory: ${SIG_DIR}"

# Close Apple Mail if running
if pgrep -x "Mail" > /dev/null 2>&1; then
  echo ""
  echo "Apple Mail is running. Closing it now..."
  osascript -e 'quit app "Mail"'
  sleep 2
fi

# Find .mailsignature files
SIG_FILES=($(ls "${SIG_DIR}"/*.mailsignature 2>/dev/null))

if [ ${#SIG_FILES[@]} -eq 0 ]; then
  echo ""
  echo "ERROR: No .mailsignature files found."
  echo "Create a placeholder signature in Apple Mail first."
  exit 1
fi

# Pick the target file
if [ ${#SIG_FILES[@]} -eq 1 ]; then
  TARGET="${SIG_FILES[0]}"
  echo "Found signature file: $(basename ${TARGET})"
else
  echo ""
  echo "Found ${#SIG_FILES[@]} signature files:"
  for i in "${!SIG_FILES[@]}"; do
    fname=$(basename "${SIG_FILES[$i]}")
    echo "  [${i}] ${fname}"
  done
  echo ""
  read -p "Which file to replace? Enter number: " choice
  TARGET="${SIG_FILES[$choice]}"
fi

# Unlock the file
chflags nouchg "${TARGET}" 2>/dev/null || true

# Read existing header
HEADER=$(awk '/^Mime-Version:/{print; exit} {print}' "${TARGET}")

# Write new signature
{
  echo "${HEADER}"
  echo ""
  echo "${SIG_HTML}"
} > "${TARGET}"

# Lock the file to prevent Apple Mail from overwriting
chflags uchg "${TARGET}"

echo ""
echo "Signature installed and locked."
echo ""
echo "Open Apple Mail - your new signature is active."
echo ""
echo "=== To update later ==="
echo "  curl -sL ${BASE_URL}/install.sh | bash -s ${MEMBER_ID}"
echo ""
