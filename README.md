# CotEditor Scripts — Markdown

Markdown preview script for [CotEditor](https://coteditor.com) Script Menu.

Converts the current document to HTML with **Python 3 stdlib only** (no Homebrew packages, no `cmark` / `pandoc` / `multimarkdown`) and opens it in your default browser.

Shortcut from the filename: **⌘⇧M**

## Requirements

- macOS
- [CotEditor](https://github.com/coteditor/CotEditor)
- `python3` (macOS `/usr/bin/python3` 3.9+ is enough)

## Install

1. In CotEditor: **Scripts** (script icon) → **Open Scripts Folder**  
   (usually `~/Library/Application Scripts/com.coteditor.CotEditor/`)
2. Copy `Markdown Preview.@M.sh` into that folder.
3. Make it executable if needed:

```bash
chmod +x ~/Library/Application\ Scripts/com.coteditor.CotEditor/Markdown\ Preview.@M.sh
```

4. Run **Scripts → Markdown Preview** or press **⌘⇧M**.

## What it supports

- Headings `#` / `##` / `###`
- Bold / italic / inline `` code ``
- Links `[text](url)`
- Unordered and ordered lists
- Blockquotes
- Fenced code blocks ` ``` `

This is a lightweight subset of Markdown, not full CommonMark/GFM (no tables, footnotes, nested lists, etc.).

## License

MIT — see [LICENSE](LICENSE).
