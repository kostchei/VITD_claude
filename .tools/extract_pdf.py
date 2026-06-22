#!/usr/bin/env python
"""Extract the text layer of the-vast-in-the-dark.pdf into an ordered Markdown
file. Page-ordered, with light whitespace cleanup; no manual transcription.

Usage: python .tools/extract_pdf.py <input.pdf> <output.md>
"""
import re
import sys

import pypdf


def clean(text: str) -> str:
    # Collapse runs of blank lines and trim trailing spaces, keep line order.
    lines = [ln.rstrip() for ln in text.splitlines()]
    out = []
    blank = 0
    for ln in lines:
        if ln.strip() == "":
            blank += 1
            if blank <= 1:
                out.append("")
        else:
            blank = 0
            out.append(ln)
    return "\n".join(out).strip()


def main() -> None:
    src, dst = sys.argv[1], sys.argv[2]
    reader = pypdf.PdfReader(src)
    n = len(reader.pages)

    parts = [
        "# The Vast in the Dark — extracted text",
        "",
        f"> Auto-extracted from `{src}` ({n} pages) via `.tools/extract_pdf.py`. "
        "Page-ordered, text layer only (art/diagrams omitted). Not hand-edited.",
        "",
        "## Contents",
        "",
    ]
    # Clickable per-page index (GitHub auto-anchors `## Page N` -> `#page-n`).
    links = [f"[Page {i + 1}](#page-{i + 1})" for i in range(n)]
    for row in range(0, n, 8):
        parts.append("- " + " · ".join(links[row:row + 8]))
    parts.append("")

    for i, page in enumerate(reader.pages):
        body = clean(page.extract_text() or "")
        parts.append("---")
        parts.append("")
        parts.append(f"## Page {i + 1}")
        parts.append("")
        parts.append(body if body else "_(no extractable text on this page)_")
        parts.append("")

    with open(dst, "w", encoding="utf-8") as f:
        f.write("\n".join(parts) + "\n")

    nonempty = sum(1 for p in reader.pages if (p.extract_text() or "").strip())
    print(f"wrote {dst}: {n} pages ({nonempty} with text)")


if __name__ == "__main__":
    main()
