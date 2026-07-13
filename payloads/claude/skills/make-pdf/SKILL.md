---
name: make-pdf
description: |
  Turn any markdown file into a publication-quality PDF — 1in margins, intelligent page breaks, page numbers, optional cover pages and clickable TOC, curly quotes and em dashes, diagonal DRAFT watermark. Not a draft artifact — a finished one. Use when the user says "make a PDF", "export to PDF", "turn this markdown into a PDF", "generate a document", or any voice variant ("pdf this markdown", "turn this into a pdf").
model: claude-opus-4-6
effort: medium
---

# make-pdf

## Activate shared preamble (once per session)

If you haven't already this session: set `SKILL_NAME=make-pdf` and read `~/.claude/skills/_shared/preamble.md`, then execute its bash block and follow its directives. Skip if already done.

## SETUP — verify the binary before any make-pdf command

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
P=""
[ -n "$MAKE_PDF_BIN" ] && [ -x "$MAKE_PDF_BIN" ] && P="$MAKE_PDF_BIN"
[ -z "$P" ] && [ -n "$_ROOT" ] && [ -x "$HOME/.skillshare/runtime/gstack/make-pdf/dist/pdf" ] && P="$HOME/.skillshare/runtime/gstack/make-pdf/dist/pdf"
[ -z "$P" ] && P="$HOME/.skillshare/runtime/gstack/make-pdf/dist/pdf"
if [ -x "$P" ]; then
  echo "MAKE_PDF_READY: $P"
  export P
else
  echo "MAKE_PDF_NOT_AVAILABLE (run '~/.skillshare/runtime/gstack/build-shareable.sh')"
fi
```

If `MAKE_PDF_NOT_AVAILABLE`: tell the user the binary isn't built. Have them run `~/.skillshare/runtime/gstack/build-shareable.sh`, then retry.

If `MAKE_PDF_READY`: `$P` is the binary path. Use `$P` (not an explicit path) for the rest of the skill.

## Core commands

- `$P generate <input.md> [output.pdf]` — render markdown to PDF (80% use case)
- `$P generate --cover --toc essay.md out.pdf` — full publication layout
- `$P generate --watermark DRAFT memo.md draft.pdf` — diagonal DRAFT watermark
- `$P preview <input.md>` — render HTML and open in browser (fast iteration)
- `$P setup` — verify browse + Chromium + pdftotext, run smoke test
- `$P --help` — full flag reference

Output contract:
- `stdout`: ONLY the output path on success, one line
- `stderr`: progress unless `--quiet`
- Exit 0 success / 1 bad args / 2 render error / 3 Paged.js timeout / 4 browse unavailable

## Core patterns

### 80% case — memo/letter

```bash
$P generate letter.md                 # writes /tmp/letter.pdf
$P generate letter.md letter.pdf      # explicit output path
```

### Publication mode — cover + TOC + chapter breaks

```bash
$P generate --cover --toc --author "Blake Hurlburt" --title "On Horizons" \
  essay.md essay.pdf
```

Each top-level H1 starts a new page. Disable with `--no-chapter-breaks`.

### Draft watermark

```bash
$P generate --watermark DRAFT memo.md draft.pdf
```

### Fast iteration

```bash
$P preview essay.md
```

Renders HTML with print CSS and opens in browser. Refresh as you edit.

### Brand-free (no CONFIDENTIAL footer)

```bash
$P generate --no-confidential memo.md memo.pdf
```

## Common flags

```
Page layout:
  --margins <dim>            1in (default) | 72pt | 2.54cm | 25mm
  --page-size letter|a4|legal

Structure:
  --cover                    Cover page (title, author, date)
  --toc                      Clickable TOC with page numbers
  --no-chapter-breaks        Don't start a new page at every H1

Branding:
  --watermark <text>         Diagonal watermark ("DRAFT", "CONFIDENTIAL")
  --header-template <html>   Custom running header
  --footer-template <html>   Custom footer (mutex with --page-numbers)
  --no-confidential          Suppress the CONFIDENTIAL right-footer

Output:
  --page-numbers             "N of M" footer (default on)
  --tagged                   Accessible PDF (default on)
  --outline                  PDF bookmarks from headings (default on)
  --quiet                    Suppress progress on stderr
  --verbose                  Per-stage timings

Network:
  --allow-network            Fetch external images (off by default)

Metadata:
  --title "..."              Document title (defaults to first H1)
  --author "..."             Author for cover + PDF metadata
  --date "..."               Date for cover (defaults to today)
```

## Debugging

- Output blank → check browse daemon: `$B status`
- Fragmented text on copy-paste → highlight.js. Retry with `--no-syntax`, or remove fenced code blocks
- Paged.js timeout → probably no headings. Drop `--toc`
- External image missing → add `--allow-network` (gives the markdown permission to fetch its image URLs)
- PDF too tall/wide → `--page-size a4` or `--margins 0.75in`
- Linux only: install `fonts-liberation` for correct Helvetica/Arial fallback

## Output capture

```bash
PDF=$($P generate letter.md)   # then use $PDF
```
