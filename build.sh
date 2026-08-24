#!/usr/bin/env bash
# Render resume.md (which is plain HTML) to resume.pdf via headless Chrome.
# Replaces the vscode markdown-pdf extension; mirrors the settings in
# .vscode/settings.json (styles.css injected, zero margins, no header/footer).
#
# Two traps this script exists to avoid:
#
#  1. `.page` is position:fixed, which pins the resume to exactly one page but
#     also means any overflow is silently clipped out of the PDF. The PDF still
#     reports as one page, so it looks fine until you actually read it.
#
#  2. Chrome applies default print margins unless the CSS says otherwise, so the
#     print layout can differ from what a browser screenshot shows. `@page
#     { margin: 0 }` in styles.css keeps them identical -- but the fit check
#     below deliberately measures in the PRINT path anyway, so that if the two
#     ever diverge again the build fails instead of quietly clipping.
set -euo pipefail

cd "$(dirname "$0")"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

page() {  # page <css-file> <out-html>
  {
    echo '<!doctype html><html><head><meta charset="utf-8"><style>'
    cat "$1"
    echo '</style></head><body>'
    cat resume.md
    echo '</body></html>'
  } > "$2"
}

topdf() {  # topdf <html> <pdf>
  "$CHROME" --headless --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$2" "file://$1" 2>/dev/null
}

count_pages() {
  python3 -c "
import re,sys
d=open(sys.argv[1],'rb').read()
print(len(re.findall(rb'/Type\s*/Page[^s]', d)))" "$1"
}

# --- fit check ---------------------------------------------------------------
# Same document, .page unpinned so content can flow, printed through the same
# PDF path. If it needs more than one page, the real build would clip it.
sed 's/position: fixed;/position: static;/' styles.css > "$BUILD/probe.css"
page "$BUILD/probe.css" "$BUILD/probe.html"
topdf "$BUILD/probe.html" "$BUILD/probe.pdf"

pages=$(count_pages "$BUILD/probe.pdf")
if [ "$pages" -gt 1 ]; then
  echo "ERROR: content needs $pages pages; the layout only renders one." >&2
  echo "       The overflow would be silently clipped from resume.pdf. Trim it." >&2
  exit 1
fi

# --- render ------------------------------------------------------------------
page styles.css "$BUILD/resume.html"
topdf "$BUILD/resume.html" "$PWD/resume.pdf"

echo "fit ok (content fits one printed page); wrote $PWD/resume.pdf"
