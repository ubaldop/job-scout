#!/usr/bin/env bash
# Build the PDF of a tailored CV and print its page count.
# Usage: build_cv.sh <cv-file>        (.tex, .md or .docx)
#
# .tex  -> the first LaTeX engine found: latexmk/pdflatex on PATH, tectonic, or Docker
#          (image $JOB_SCOUT_LATEX_IMAGE, default texlive/texlive:latest; the first pull is large).
#          Set JOB_SCOUT_LATEX_ENGINE=xelatex or lualatex if the CV needs it.
# .md   -> pandoc to .docx, then LibreOffice to PDF.
# .docx -> LibreOffice to PDF.
set -euo pipefail

src="$(cd "$(dirname "${1:?usage: build_cv.sh <cv-file>}")" && pwd)/$(basename "$1")"
[[ -f "$src" ]] || { echo "missing $src" >&2; exit 1; }
dir="$(dirname "$src")"
name="$(basename "${src%.*}")"
pdf="$dir/$name.pdf"
engine="${JOB_SCOUT_LATEX_ENGINE:-pdflatex}"
image="${JOB_SCOUT_LATEX_IMAGE:-texlive/texlive:latest}"

office() {
  local bin
  bin="$(command -v soffice || command -v libreoffice || true)"
  [[ -n "$bin" ]] || { echo "LibreOffice (soffice) is required for $1" >&2; exit 1; }
  "$bin" --headless --convert-to pdf --outdir "$dir" "$1" >/dev/null 2>&1
}

case "$src" in
  *.tex)
    cd "$dir"
    if command -v latexmk >/dev/null && command -v "$engine" >/dev/null; then
      case "$engine" in pdflatex) flag=-pdf ;; *) flag="-$engine" ;; esac
      latexmk "$flag" -interaction=nonstopmode -halt-on-error "$name.tex" >/dev/null 2>&1 \
        || { echo "LaTeX failed, see $dir/$name.log" >&2; exit 1; }
    elif command -v "$engine" >/dev/null; then
      for _ in 1 2; do
        "$engine" -interaction=nonstopmode -halt-on-error "$name.tex" >/dev/null 2>&1 \
          || { echo "LaTeX failed, see $dir/$name.log" >&2; exit 1; }
      done
    elif command -v tectonic >/dev/null; then
      tectonic -X compile "$name.tex" >"$dir/$name.log" 2>&1 \
        || { echo "tectonic failed, see $dir/$name.log" >&2; exit 1; }
    elif command -v docker >/dev/null; then
      for _ in 1 2; do
        docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$dir":/data -w /data "$image" \
          "$engine" -interaction=nonstopmode -halt-on-error "$name.tex" >/dev/null 2>&1 \
          || { echo "LaTeX in Docker ($image) failed, see $dir/$name.log" >&2; exit 1; }
      done
    else
      echo "no LaTeX engine: install TeX Live, tectonic or Docker" >&2; exit 1
    fi
    rm -f "$dir/$name".{aux,out,fls,fdb_latexmk,synctex.gz}
    ;;
  *.md)
    command -v pandoc >/dev/null || { echo "pandoc is required for Markdown CVs" >&2; exit 1; }
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    pandoc "$src" -o "$tmp/$name.docx"
    office "$tmp/$name.docx"
    ;;
  *.docx)
    office "$src"
    ;;
  *)
    echo "unsupported CV format: $src (use .tex, .md or .docx)" >&2; exit 1
    ;;
esac

[[ -f "$pdf" ]] || { echo "no PDF produced for $src" >&2; exit 1; }
pages="$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages:/ {print $2}' || true)"
[[ -n "$pages" ]] || pages="$(python3 "$(dirname "$0")/pdf_pages.py" "$pdf" 2>/dev/null || true)"
echo "built $pdf (${pages:-?} page(s))"
