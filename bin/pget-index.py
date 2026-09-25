#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["bibtexparser<2", "pymupdf"]
# ///
"""Build a Claude-friendly view of a Paperpile library downloaded by pget.

Reads <dir>/library.bib and <dir>/pdfs/, writes <dir>/{index.tsv,library.jsonl,
papers/<citekey>.md,unmatched-pdfs.txt,CLAUDE.md}. Extracted text is cached
in <dir>/.text/ and only redone for new or changed PDFs.
"""
import json
import os
import re
import shutil
import sys
import unicodedata
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import bibtexparser
from bibtexparser.bparser import BibTexParser
from bibtexparser.customization import convert_to_unicode

# Title prefix length used to pair BibTeX entries with PDF file names
KEY_LEN = 20


def norm(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]", "", s.lower())


def clean(s):
    return " ".join(re.sub(r"[{}]", "", s or "").split())


def extract_text(args):
    pdf, txt = args
    import pymupdf

    try:
        with pymupdf.open(pdf) as doc:
            text = "\n".join(page.get_text() for page in doc)
    except Exception as e:
        text = f"[text extraction failed: {e}]"
    txt.parent.mkdir(parents=True, exist_ok=True)
    txt.write_text(text)


def update_text_cache(root, pdfs):
    todo = []
    for pdf in pdfs:
        txt = root / ".text" / pdf.relative_to(root / "pdfs").with_suffix(".txt")
        if not txt.exists() or txt.stat().st_mtime < pdf.stat().st_mtime:
            todo.append((pdf, txt))
    if todo:
        print(f"Extracting text from {len(todo)} new/changed PDFs")
        with ProcessPoolExecutor(min(8, os.cpu_count() or 1)) as pool:
            for i, _ in enumerate(pool.map(extract_text, todo, chunksize=4), 1):
                if i % 100 == 0:
                    print(f"  {i}/{len(todo)}")


def pdf_title(pdf):
    # Paperpile names files "Author Year - Title.pdf" (long titles truncated)
    stem = pdf.stem
    return stem.split(" - ", 1)[1] if " - " in stem else stem


def match_pdfs(entries, pdfs):
    by_name = {p.name.lower(): p for p in pdfs}
    by_key = {}
    for p in pdfs:
        key = norm(pdf_title(p))
        if len(key) >= KEY_LEN:
            by_key.setdefault(key[:KEY_LEN], []).append((key, p))
    matched = {}
    for e in entries:
        found = []
        # Prefer an explicit file field, if the export has one
        for name in re.findall(r"[^;:{}]+\.pdf", e.get("file", ""), re.I):
            p = by_name.get(Path(name.strip()).name.lower())
            if p:
                found.append(p)
        if not found:
            title = norm(clean(e.get("title", "")))
            for key, p in by_key.get(title[:KEY_LEN], []):
                if title.startswith(key) or key.startswith(title):
                    found.append(p)
        matched[e["ID"]] = sorted(set(found))
    return matched


def main(root):
    root = Path(root).resolve()
    parser = BibTexParser(common_strings=True)
    parser.customization = convert_to_unicode
    parser.ignore_nonstandard_types = False
    with open(root / "library.bib") as f:
        entries = bibtexparser.load(f, parser=parser).entries
    pdfs = sorted(p for p in (root / "pdfs").rglob("*") if p.suffix.lower() == ".pdf")
    print(f"{len(entries)} BibTeX entries, {len(pdfs)} PDFs")

    update_text_cache(root, pdfs)
    matched = match_pdfs(entries, pdfs)

    papers = root / "papers.tmp"
    shutil.rmtree(papers, ignore_errors=True)
    papers.mkdir()
    rows, used = [], set()
    with open(root / "library.jsonl.tmp", "w") as jsonl:
        for e in sorted(entries, key=lambda e: e["ID"]):
            key = e["ID"]
            title = clean(e.get("title"))
            authors = [clean(a) for a in re.split(r"\s+and\s+", e.get("author", "")) if a.strip()]
            labels = [clean(k) for k in re.split(r"[;,]", e.get("keywords", "")) if k.strip()]
            pdf_paths = [str(p) for p in matched[key]]
            used.update(matched[key])
            md_path = papers / f"{re.sub(r'[^A-Za-z0-9_.+-]', '_', key)}.md"
            record = {
                "citekey": key,
                "type": e.get("ENTRYTYPE"),
                "title": title,
                "authors": authors,
                "year": clean(e.get("year")),
                "journal": clean(e.get("journal") or e.get("booktitle")),
                "doi": clean(e.get("doi")),
                "pmid": clean(e.get("pmid")),
                "url": clean(e.get("url")),
                "labels": labels,
                "abstract": clean(e.get("abstract")),
                "pdfs": pdf_paths,
                "md": str(root / "papers" / md_path.name),
            }
            jsonl.write(json.dumps(record, ensure_ascii=False) + "\n")
            first = authors[0].split(",")[0] if authors else ""
            rows.append([key, record["year"], first, record["journal"], title, "; ".join(labels), " ".join(pdf_paths)])

            md = [f"# {title}", ""]
            for field in ("citekey", "year", "journal", "doi", "pmid", "url"):
                if record[field]:
                    md.append(f"- {field}: {record[field]}")
            md.append(f"- authors: {'; '.join(authors)}")
            if labels:
                md.append(f"- labels: {'; '.join(labels)}")
            for p in pdf_paths:
                md.append(f"- pdf: {p}")
            md += ["", "## Abstract", "", record["abstract"] or "(none)", ""]
            for p in matched[key]:
                txt = root / ".text" / p.relative_to(root / "pdfs").with_suffix(".txt")
                md += [f"## Full text ({p.name})", "", txt.read_text(errors="replace").strip(), ""]
            md_path.write_text("\n".join(md))

    with open(root / "index.tsv.tmp", "w") as f:
        f.write("citekey\tyear\tfirst_author\tjournal\ttitle\tlabels\tpdf\n")
        for row in rows:
            f.write("\t".join(c.replace("\t", " ") for c in row) + "\n")
    unmatched = [str(p) for p in pdfs if p not in used]
    (root / "unmatched-pdfs.txt").write_text("".join(p + "\n" for p in unmatched))

    # Swap in the new outputs only once everything was written
    shutil.rmtree(root / "papers", ignore_errors=True)
    papers.rename(root / "papers")
    os.replace(root / "library.jsonl.tmp", root / "library.jsonl")
    os.replace(root / "index.tsv.tmp", root / "index.tsv")
    (root / "CLAUDE.md").write_text(CLAUDE_MD.format(root=root, n=len(entries)))

    with_pdf = sum(1 for r in rows if r[-1])
    print(f"{len(entries)} papers, {with_pdf} with PDF text, {len(unmatched)} PDFs not matched to an entry")
    print(f"Library: {root}")


CLAUDE_MD = """\
# Paperpile library ({n} papers)

Read-only copy of the user's Paperpile library, rebuilt by `pget sync`.

- `index.tsv`: one line per paper: citekey, year, first_author, journal, title, labels (Paperpile labels), pdf
- `library.jsonl`: same plus authors, doi, pmid, url, abstract (no full text)
- `papers/<citekey>.md`: metadata, abstract and full text extracted from the PDF(s)
- `library.bib`: BibTeX as exported by Paperpile; cite papers by their citekey
- `pdfs/`: the original PDFs (Paperpile's Google Drive folder)
- `unmatched-pdfs.txt`: PDFs that could not be paired with an entry (e.g. supplements); their text is in `.text/`

Finding papers:

    grep -i 'phosphosite' {root}/index.tsv                     # titles/labels
    grep -il 'kinase.*substrate' {root}/papers/*.md            # abstracts + full text
    jq -r 'select(.labels | index("my label")) | .citekey' {root}/library.jsonl
    grep -A20 '{{Smith2020-ab,' {root}/library.bib                # BibTeX entry

Then read the matching `papers/<citekey>.md` (full texts can be long; use offset/limit
or grep -n for the relevant section). Full text comes from automatic PDF extraction,
so tables, figures and equations may be garbled; papers without a PDF have only metadata
and abstract. When quoting or citing, give the citekey and title.
"""

if __name__ == "__main__":
    main(sys.argv[1])
