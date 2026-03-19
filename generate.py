#!/usr/bin/env python3
"""
Zense Mail Signature Generator

Reads team.json and signature-template.html, generates personalized
.mailsignature files for each team member.

Usage:
    python3 generate.py              # Generate all signatures
    python3 generate.py janick       # Generate for one person
    python3 generate.py --install    # Generate + install into Apple Mail
"""

import json
import os
import sys
import glob
import shutil
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
TEMPLATE_PATH = SCRIPT_DIR / "signature-template.html"
TEAM_PATH = SCRIPT_DIR / "team.json"
OUTPUT_DIR = SCRIPT_DIR / "output"

MAILSIG_HEADER = """\
Content-Transfer-Encoding: quoted-printable
Content-Type: text/html;
\tcharset=utf-8
Mime-Version: 1.0 (Mac OS X Mail 16.0 \\(3696.120.41.1.1\\))

"""


def load_team():
    with open(TEAM_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def load_template():
    with open(TEMPLATE_PATH, "r", encoding="utf-8") as f:
        return f.read()


DEFAULT_PHONE = "+41 44 521 73 90"


def generate_signature(template, member):
    html = template
    html = html.replace("{{NAME}}", member["name"])
    html = html.replace("{{ROLE}}", member["role"])
    html = html.replace("{{PHONE}}", member.get("phone") or DEFAULT_PHONE)
    return html


def save_signature(member_id, html):
    OUTPUT_DIR.mkdir(exist_ok=True)
    out_path = OUTPUT_DIR / f"{member_id}.html"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"  Generated: {out_path}")
    return out_path


def find_apple_mail_signatures_dir():
    """Find the Apple Mail signatures directory."""
    home = Path.home()
    mail_base = home / "Library" / "Mail"
    # Search for the Signatures directory (varies by Mail version)
    for vdir in sorted(mail_base.glob("V*"), reverse=True):
        sig_dir = vdir / "MailData" / "Signatures"
        if sig_dir.exists():
            return sig_dir
    return None


def install_signature(member_id, html):
    """Install signature into Apple Mail."""
    sig_dir = find_apple_mail_signatures_dir()
    if not sig_dir:
        print("  ERROR: Could not find Apple Mail Signatures directory.")
        print("  Make sure Apple Mail has been set up with at least one signature.")
        return False

    # Find existing .mailsignature files
    sig_files = list(sig_dir.glob("*.mailsignature"))
    if not sig_files:
        print("  ERROR: No existing .mailsignature files found.")
        print("  Create a placeholder signature in Apple Mail first.")
        return False

    if len(sig_files) == 1:
        target = sig_files[0]
    else:
        print(f"  Found {len(sig_files)} signature files:")
        for i, f in enumerate(sig_files):
            # Read first few lines to identify
            with open(f, "r", encoding="utf-8", errors="ignore") as fh:
                content = fh.read(500)
            print(f"    [{i}] {f.name}")
            # Show a snippet to help identify
            for line in content.split("\n"):
                if "PLACEHOLDER" in line.upper() or member_id.lower() in line.lower():
                    print(f"        Contains: {line.strip()[:80]}")
        choice = input("  Which file to replace? Enter number: ")
        target = sig_files[int(choice)]

    # Unlock the file if locked
    os.system(f'chflags nouchg "{target}"')

    # Read the existing header (everything before the HTML)
    with open(target, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # Find the Mime-Version line and keep everything up to and including it
    lines = content.split("\n")
    header_end = 0
    for i, line in enumerate(lines):
        if line.startswith("Mime-Version:"):
            header_end = i + 1
            break

    if header_end == 0:
        # No header found, use default
        header = MAILSIG_HEADER
    else:
        header = "\n".join(lines[:header_end]) + "\n\n"

    # Write new signature
    with open(target, "w", encoding="utf-8") as f:
        f.write(header)
        f.write(html)

    # Lock the file
    os.system(f'chflags uchg "{target}"')

    print(f"  Installed: {target}")
    print(f"  File locked to prevent Apple Mail from overwriting it.")
    return True


def main():
    team = load_team()
    template = load_template()
    install = "--install" in sys.argv
    filter_id = None

    for arg in sys.argv[1:]:
        if arg != "--install":
            filter_id = arg

    members = team if not filter_id else [m for m in team if m["id"] == filter_id]

    if not members:
        print(f"No team member found with id '{filter_id}'")
        print(f"Available: {', '.join(m['id'] for m in team)}")
        sys.exit(1)

    for member in members:
        print(f"\n{member['name']}:")
        html = generate_signature(template, member)
        save_signature(member["id"], html)

        if install:
            install_signature(member["id"], html)

    print("\nDone!")


if __name__ == "__main__":
    main()
