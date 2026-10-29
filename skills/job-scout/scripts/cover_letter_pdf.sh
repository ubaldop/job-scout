#!/usr/bin/env bash
# Convert <offer-dir>/cover_letter.md to cover_letter.pdf (pandoc -> docx -> LibreOffice).
# Usage: cover_letter_pdf.sh <offer-dir>
# Needs pandoc and LibreOffice (soffice).
set -euo pipefail

dir="$(cd "${1:?usage: cover_letter_pdf.sh <offer-dir>}" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pandoc "$dir/cover_letter.md" -o "$tmp/cover_letter.docx"
soffice --headless --convert-to pdf --outdir "$tmp" "$tmp/cover_letter.docx" >/dev/null 2>&1
mv "$tmp/cover_letter.pdf" "$dir/cover_letter.pdf"
pages="$(pdfinfo "$dir/cover_letter.pdf" 2>/dev/null | awk '/^Pages:/ {print $2}' || true)"
[[ -n "$pages" ]] || pages="$(python3 "$(dirname "$0")/pdf_pages.py" "$dir/cover_letter.pdf" 2>/dev/null || true)"
echo "built $dir/cover_letter.pdf (${pages:-?} page(s))"
