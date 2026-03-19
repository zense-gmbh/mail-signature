#!/usr/bin/env python3
"""
Zense Mail Signature Generator

Reads team.json and signature-template.html, generates personalized
HTML signatures for each team member into the signatures/ directory.

GitHub Action runs this on every push → deployed via GitHub Pages.

Usage:
    python3 generate.py              # Generate all signatures
    python3 generate.py janick       # Generate for one person
"""

import json
import os
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
TEMPLATE_PATH = SCRIPT_DIR / "signature-template.html"
TEAM_PATH = SCRIPT_DIR / "team.json"
SIGNATURES_DIR = SCRIPT_DIR / "signatures"

DEFAULT_PHONE = "+41 44 521 73 90"

OFFICES = {
    "zurich": {
        "company": "Zense GmbH",
        "street": "Badenerstr. 75",
        "city": "CH-8004 Zürich",
    },
    "berlin": {
        "company": "Zense Berlin GmbH",
        "street": "Mahlower Str. 23-24",
        "city": "DE-12049 Berlin",
    },
}
DEFAULT_OFFICE = "zurich"


def load_team():
    with open(TEAM_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def load_template():
    with open(TEMPLATE_PATH, "r", encoding="utf-8") as f:
        return f.read()


def generate_signature(template, member):
    office = OFFICES.get(member.get("office", DEFAULT_OFFICE), OFFICES[DEFAULT_OFFICE])
    html = template
    html = html.replace("{{NAME}}", member["name"])
    html = html.replace("{{ROLE}}", member["role"])
    html = html.replace("{{PHONE}}", member.get("phone") or DEFAULT_PHONE)
    html = html.replace("{{EMAIL}}", member.get("email", ""))
    html = html.replace("{{COMPANY}}", office["company"])
    html = html.replace("{{STREET}}", office["street"])
    html = html.replace("{{CITY}}", office["city"])
    return html


def save_signature(member_id, html):
    SIGNATURES_DIR.mkdir(exist_ok=True)
    out_path = SIGNATURES_DIR / f"{member_id}.html"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"  Generated: {out_path}")
    return out_path


def generate_index(team):
    """Generate an index page listing all signatures."""
    SIGNATURES_DIR.mkdir(exist_ok=True)
    rows = ""
    for m in team:
        rows += f'<tr><td>{m["name"]}</td><td>{m["role"]}</td>'
        rows += f'<td><a href="{m["id"]}.html">{m["id"]}.html</a></td></tr>\n'

    index_html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Zense Mail Signatures</title>
<style>
body {{ font-family: 'Sofia Pro', 'Century Gothic', sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; }}
h1 {{ font-weight: normal; }}
table {{ border-collapse: collapse; width: 100%; }}
th, td {{ text-align: left; padding: 8px 12px; border-bottom: 1px solid #eee; }}
th {{ font-weight: bold; }}
a {{ color: #EF7DBE; }}
</style></head>
<body>
<h1>Zense Mail Signatures</h1>
<p>{len(team)} team members</p>
<table>
<tr><th>Name</th><th>Role</th><th>Signature</th></tr>
{rows}
</table>
</body></html>"""

    with open(SIGNATURES_DIR / "index.html", "w", encoding="utf-8") as f:
        f.write(index_html)
    print(f"  Generated: signatures/index.html")


def main():
    team = load_team()
    template = load_template()
    filter_id = None

    for arg in sys.argv[1:]:
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

    # Always generate index when building all
    if not filter_id:
        generate_index(team)

    print("\nDone!")


if __name__ == "__main__":
    main()
