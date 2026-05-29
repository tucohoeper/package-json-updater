# sync_snippets

A small Bash script that keeps your LuaSnip / VSCode-style `package.json` in sync with the `.json` files inside your Neovim snippets directory.

Whenever you add or delete a snippet file, just run the script — it will automatically register new entries and remove stale ones. No manual editing of `package.json` needed.

---

## How it works

LuaSnip's VSCode-style loader requires a `package.json` at the root of your snippets folder that lists every snippet file and its associated language. Maintaining that file by hand is tedious. `sync_snippets.sh` automates it by:

1. Scanning your snippets folder recursively for `.json` files
2. Comparing them against the entries already in `package.json`
3. Adding entries for new files and removing entries for deleted ones
4. Writing the updated `package.json` back to disk — only if something actually changed

---

## Features

- **Auto-detects the language** from the parent folder name or the filename prefix
  - `snippets/python/flask.json` → `python`
  - `python-flask.json` → `python`
- **Adds** entries for new snippet files
- **Removes** entries for deleted snippet files
- **Preserves** the order of existing entries; new ones are appended at the end
- **Creates** `package.json` from scratch if it doesn't exist yet
- **Idempotent** — safe to run multiple times, no duplicate entries
- No external dependencies — only `bash` and `python3`

---

## Requirements

- `bash`
- `python3` (part of most Linux/macOS systems by default)

---

## Installation

```bash
# Clone or download the script
curl -O https://raw.githubusercontent.com/your-username/sync_snippets/main/sync_snippets.sh

# Make it executable
chmod +x sync_snippets.sh
```

---

## Usage

```bash
# Uses ~/.config/nvim/snippets by default
./sync_snippets.sh

# Or pass a custom path
./sync_snippets.sh /path/to/your/snippets
```

### Example output

```
✓ 1 entry/entries added:

   + [python]  python/flask.json

   Total snippets registered: 5
```

```
✓ 1 entry/entries removed:

   - python/flask.json

   Total snippets registered: 4
```

```
✓ package.json is already up to date. No changes needed.

   Total snippets registered: 4
```

---

## Snippets folder structure

Both structures are supported:

```
# Organised by language folder (recommended)
~/.config/nvim/snippets/
├── package.json
├── python/
│   ├── basics.json
│   ├── django.json
│   └── flask.json
├── lua/
│   └── basics.json
└── javascript/
    └── basics.json

# Or flat files with a language prefix
~/.config/nvim/snippets/
├── package.json
├── python-basics.json
├── python-flask.json
└── lua-basics.json
```

---

## Automate with Neovim

You can make Neovim run the script automatically every time you save a snippet file:

```lua
-- ~/.config/nvim/lua/autocmds.lua
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = vim.fn.expand("~") .. "/.config/nvim/snippets/**/*.json",
  callback = function()
    vim.fn.jobstart(
      vim.fn.expand("~") .. "/.config/nvim/snippets/sync_snippets.sh",
      { detach = true }
    )
  end,
})
```

---

## Supported languages

| Folder / prefix | Language ID |
|---|---|
| `python` | `python` |
| `lua` | `lua` |
| `javascript` | `javascript` |
| `typescript` | `typescript` |
| `typescriptreact` | `typescriptreact` |
| `javascriptreact` | `javascriptreact` |
| `rust` | `rust` |
| `go` | `go` |
| `ruby` | `ruby` |
| `java` | `java` |
| `kotlin` | `kotlin` |
| `cpp` | `cpp` |
| `c` | `c` |
| `cs` / `csharp` | `csharp` |
| `bash` / `sh` / `zsh` | `shellscript` |
| `fish` | `fish` |
| `html` | `html` |
| `css` / `scss` / `sass` | `css` / `scss` / `sass` |
| `sql` | `sql` |
| `yaml` | `yaml` |
| `toml` | `toml` |
| `markdown` | `markdown` |
| `vim` | `vim` |
| `docker` / `dockerfile` | `dockerfile` |
| `terraform` | `terraform` |
| `elixir` | `elixir` |
| `php` | `php` |
| `swift` | `swift` |
| `dart` | `dart` |
| `r` | `r` |
| `julia` | `julia` |

Don't see your language? The script falls back to using the parent folder name as the language ID, so it will still work — just make sure the folder name matches the language identifier expected by your LSP/snippet engine.

---

## License

MIT
