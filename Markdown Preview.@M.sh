#!/bin/bash
#%%%{CotEditorXInput=AllText}%%%
#%%%{CotEditorXOutput=None}%%%
#
# CotEditor Script Menu: Markdown → HTML preview in the default browser
# Shortcut from filename: ⌘⇧M
# Requires: python3 (stdlib only; compatible with macOS /usr/bin/python3 3.9+)

set -euo pipefail

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Prefer system python for sandboxed Script Menu; fall back to Homebrew.
if [[ -x /usr/bin/python3 ]]; then
	PYTHON=/usr/bin/python3
elif command -v python3 >/dev/null 2>&1; then
	PYTHON=$(command -v python3)
else
	echo "python3 not found" >&2
	exit 1
fi

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/coteditor-md-preview.XXXXXX")
mdfile="$tmpdir/source.md"
htmlfile="$tmpdir/preview.html"
cat > "$mdfile"

"$PYTHON" - "$mdfile" "$htmlfile" <<'PY'
import html
import re
import sys
from pathlib import Path

md = Path(sys.argv[1]).read_text(encoding="utf-8")
blocks = []


def fence(m):
    lang = (m.group(1) or "").strip()
    code = html.escape(m.group(2))
    cls = ' class="language-%s"' % html.escape(lang) if lang else ""
    blocks.append("<pre><code%s>%s</code></pre>" % (cls, code))
    return "@@BLOCK%d@@" % (len(blocks) - 1)


md = re.sub(r"```([^\n`]*)\n(.*?)```", fence, md, flags=re.S)


def inline(s):
    s = html.escape(s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
    return s


out, buf = [], []
in_ul = in_ol = in_p = False


def flush_p():
    global in_p, buf
    if in_p:
        out.append("<p>" + "<br>\n".join(buf) + "</p>")
        in_p, buf = False, []


def close_lists():
    global in_ul, in_ol
    if in_ul:
        out.append("</ul>")
        in_ul = False
    if in_ol:
        out.append("</ol>")
        in_ol = False


for raw in md.splitlines():
    line = raw.rstrip()
    m = re.fullmatch(r"@@BLOCK(\d+)@@", line.strip())
    if m:
        flush_p()
        close_lists()
        out.append(blocks[int(m.group(1))])
        continue
    if not line.strip():
        flush_p()
        close_lists()
        continue
    if line.startswith("### "):
        flush_p()
        close_lists()
        out.append("<h3>%s</h3>" % inline(line[4:]))
        continue
    if line.startswith("## "):
        flush_p()
        close_lists()
        out.append("<h2>%s</h2>" % inline(line[3:]))
        continue
    if line.startswith("# "):
        flush_p()
        close_lists()
        out.append("<h1>%s</h1>" % inline(line[2:]))
        continue
    if re.match(r"^[-*+] ", line):
        flush_p()
        if not in_ul:
            close_lists()
            out.append("<ul>")
            in_ul = True
        item = inline(re.sub(r"^[-*+] ", "", line))
        out.append("<li>%s</li>" % item)
        continue
    if re.match(r"^\d+\. ", line):
        flush_p()
        if not in_ol:
            close_lists()
            out.append("<ol>")
            in_ol = True
        item = inline(re.sub(r"^\d+\. ", "", line))
        out.append("<li>%s</li>" % item)
        continue
    if line.startswith("> "):
        flush_p()
        close_lists()
        out.append("<blockquote><p>%s</p></blockquote>" % inline(line[2:]))
        continue
    close_lists()
    in_p = True
    buf.append(inline(line))

flush_p()
close_lists()
body = "\n".join(out)

Path(sys.argv[2]).write_text(
    """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Markdown Preview</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #f7f7f8; --fg: #1d1d1f; --muted: #6e6e73;
    --border: #d2d2d7; --code-bg: #efeff0; --accent: #0066cc;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #1c1c1e; --fg: #f5f5f7; --muted: #a1a1a6;
      --border: #3a3a3c; --code-bg: #2c2c2e; --accent: #6cb6ff;
    }
  }
  body {
    margin: 0; background: var(--bg); color: var(--fg);
    font: 17px/1.65 -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
  }
  main { max-width: 46rem; margin: 2rem auto; padding: 0 1.25rem 3rem; }
  h1, h2, h3 { line-height: 1.25; margin: 1.6em 0 .5em; }
  h1, h2 { border-bottom: 1px solid var(--border); padding-bottom: .25em; }
  a { color: var(--accent); }
  code {
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: .92em; background: var(--code-bg);
    padding: .12em .35em; border-radius: 4px;
  }
  pre { background: var(--code-bg); padding: 1em; overflow-x: auto; border-radius: 8px; }
  pre code { background: none; padding: 0; }
  blockquote {
    margin-left: 0; padding: .2em 1em;
    border-left: 4px solid var(--border); color: var(--muted);
  }
  img, video { max-width: 100%%; height: auto; }
</style>
</head>
<body>
<main>
%s
</main>
</body>
</html>
"""
    % body,
    encoding="utf-8",
)
PY

open "$htmlfile"
