# resume

## Build

```sh
./build.sh
```

Writes `resume.pdf`. Requires Google Chrome (at the standard `/Applications`
path) and `python3` — no VS Code extension, and nothing to install.

## Files

| file | what it is |
| --- | --- |
| `resume.md` | The resume. Despite the extension this is **plain HTML**, not markdown — the name is left over from the old export tool. |
| `styles.css` | All styling. Injected into a `<head>` at build time. |
| `build.sh` | Wraps the two into one document and prints it to PDF via headless Chrome. |
| `resume.pdf` | Generated. Rebuild it rather than editing it. |

## Two things that will bite you

**The layout silently clips.** `.page` is `position: fixed`, which is what pins
the resume to exactly one page — but it also means anything that doesn't fit is
dropped from the PDF instead of flowing onto page 2. The PDF still reports as
one page and still opens fine; content is just missing off the bottom.

`build.sh` guards against this: before rendering, it re-renders the same
document with `.page` unpinned so content can flow, prints *that* to PDF, and
fails the build if it needs more than one page. So trust the build, and if it
errors, trim something — don't work around it.

**Print margins are not screen margins.** Chrome applies default page margins to
`--print-to-pdf` unless the CSS opts out, which shrinks the printable box,
rewraps the text narrower and taller, and then the clipping above eats the
overflow. `@page { margin: 0 }` in `styles.css` is what prevents that. Removing
it breaks the PDF in a way the browser never shows you.

## Checking the result

The build only proves the content fits. To actually look at the PDF:

```sh
qlmanage -t -s 1400 -o /tmp/check resume.pdf   # → /tmp/check/resume.pdf.png
```

Reading the rasterized PDF is the only real check — viewing the HTML in a
browser renders a different layout from the one that gets printed.

## Legacy

`.vscode/settings.json` still holds the old `markdown-pdf` extension config
(styles, zero margins). It's unused now; `build.sh` reproduces those settings
directly. Kept only as a record of what the original export did.
