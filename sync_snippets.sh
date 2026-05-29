#!/usr/bin/env bash
# sync_snippets.sh — keeps package.json in sync with your snippets folder
# - Adds entries for new .json files
# - Removes entries for deleted .json files
# - Preserves the order of existing entries; new ones are appended at the end
#
# Usage:
#   ./sync_snippets.sh                          # defaults to ~/.config/nvim/snippets
#   ./sync_snippets.sh /path/to/snippets        # use a custom path

set -euo pipefail

SNIPPETS_DIR="${1:-$HOME/.config/nvim/snippets}"
PACKAGE_JSON="$SNIPPETS_DIR/package.json"

# ── Validations ───────────────────────────────────────────────────────────────

if [ ! -d "$SNIPPETS_DIR" ]; then
  echo "✗ Directory not found: $SNIPPETS_DIR"
  exit 1
fi

if [ ! -f "$PACKAGE_JSON" ]; then
  echo "⚠ package.json not found. Creating a new one at: $PACKAGE_JSON"
  cat > "$PACKAGE_JSON" << 'PKGJSON'
{
  "name": "custom-snippets",
  "version": "1.0.0",
  "contributes": {
    "snippets": []
  }
}
PKGJSON
fi

# ── Sync via Python ───────────────────────────────────────────────────────────

python3 - "$SNIPPETS_DIR" "$PACKAGE_JSON" << 'PYEOF'
import sys, json
from pathlib import Path

snippets_dir = Path(sys.argv[1]).resolve()
package_path = Path(sys.argv[2])

# Mapping of folder name / filename prefix → VSCode language identifier
LANG_MAP = {
    "python": "python",
    "lua": "lua",
    "javascript": "javascript",
    "typescript": "typescript",
    "typescriptreact": "typescriptreact",
    "javascriptreact": "javascriptreact",
    "rust": "rust",
    "go": "go",
    "ruby": "ruby",
    "java": "java",
    "kotlin": "kotlin",
    "cpp": "cpp",
    "c": "c",
    "cs": "csharp",
    "csharp": "csharp",
    "bash": "shellscript",
    "sh": "shellscript",
    "zsh": "shellscript",
    "fish": "fish",
    "html": "html",
    "css": "css",
    "scss": "scss",
    "sass": "sass",
    "sql": "sql",
    "json": "json",
    "yaml": "yaml",
    "toml": "toml",
    "markdown": "markdown",
    "vim": "vim",
    "docker": "dockerfile",
    "dockerfile": "dockerfile",
    "terraform": "terraform",
    "elixir": "elixir",
    "php": "php",
    "swift": "swift",
    "dart": "dart",
    "r": "r",
    "julia": "julia",
}

def detect_language(filepath: Path) -> str:
    """Detect language from the parent folder name, then from the filename prefix."""
    parent = filepath.parent.name.lower()
    stem   = filepath.stem.lower()

    # 1. Exact parent folder match  (e.g. snippets/python/flask.json → python)
    if parent in LANG_MAP:
        return LANG_MAP[parent]

    # 2. Filename prefix with hyphen (e.g. python-flask.json → python)
    for key, lang in LANG_MAP.items():
        if stem == key or stem.startswith(f"{key}-"):
            return lang

    # 3. Fallback: use the parent folder name as-is
    return parent

# Read the current package.json
with open(package_path, "r", encoding="utf-8") as f:
    pkg = json.load(f)

pkg.setdefault("contributes", {}).setdefault("snippets", [])
old_entries = pkg["contributes"]["snippets"]

# Collect every .json file currently on disk
disk_files = {
    str(p.relative_to(snippets_dir))
    for p in sorted(snippets_dir.rglob("*.json"))
    if p.name != "package.json"
}

# Normalise the paths already registered in package.json
old_paths = {e["path"].lstrip("./"): e for e in old_entries}

# Entries to remove (in package.json but no longer on disk)
removed = [p for p in old_paths if p not in disk_files]

# Entries to add (on disk but not yet in package.json)
added_paths = [p for p in sorted(disk_files) if p not in old_paths]

# Rebuild the list: keep existing entries that still exist + append new ones
new_entries = [e for e in old_entries if e["path"].lstrip("./") in disk_files]
for rel_str in added_paths:
    lang = detect_language(snippets_dir / rel_str)
    new_entries.append({"language": lang, "path": f"./{rel_str}"})

pkg["contributes"]["snippets"] = new_entries

# Write only if something changed
if removed or added_paths:
    with open(package_path, "w", encoding="utf-8") as f:
        json.dump(pkg, f, indent=2, ensure_ascii=False)
        f.write("\n")

    if added_paths:
        print(f"✓ {len(added_paths)} entry/entries added:\n")
        for p in added_paths:
            lang = detect_language(snippets_dir / p)
            print(f"   + [{lang}]  {p}")

    if removed:
        print(f"\n✓ {len(removed)} entry/entries removed:\n")
        for p in removed:
            print(f"   - {p}")
else:
    print("✓ package.json is already up to date. No changes needed.")

print(f"\n   Total snippets registered: {len(new_entries)}")
PYEOF
