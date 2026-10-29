#!/usr/bin/env bash
# Check the tools that Job Scout needs for a given CV, and print the command that installs the missing ones.
# Usage: check_deps.sh [cv-file]
#
# Exit 0: everything needed is present. Exit 1: something is missing (see the "install:" line).
# The script installs nothing: the skill asks the user first, because most commands need sudo.
set -uo pipefail

cv="${1:-}"
missing=()     # package keys for the install command
optional=()    # tools needed only for some forms (cover letter upload)
report() { printf '%-8s %-34s %s\n' "$1" "$2" "$3"; }
has() { command -v "$1" >/dev/null 2>&1; }

echo "Job Scout dependencies${cv:+ for $cv}:"

if has python3; then report OK python3 "scanner, forms, style check"
else report MISSING python3 "scanner, forms, style check (required)"; missing+=(python); fi

# LaTeX: needed only for .tex CVs. Any one engine is enough.
if [[ -z "$cv" || "$cv" == *.tex ]]; then
  if has latexmk || has pdflatex || has xelatex; then report OK "LaTeX (TeX Live)" "build the CV"
  elif has tectonic; then report OK "LaTeX (tectonic)" "build the CV"
  elif has docker && docker info >/dev/null 2>&1; then
    report OK "LaTeX (Docker)" "build the CV (image ${JOB_SCOUT_LATEX_IMAGE:-texlive/texlive:latest}, pulled at first use)"
  else
    report MISSING "LaTeX engine" "build a .tex CV"; missing+=(latex)
  fi
fi

# pandoc + LibreOffice: Markdown/Word CVs, and the cover letter PDF (only for forms with an upload field).
need_office=optional
[[ "$cv" == *.md || "$cv" == *.docx ]] && need_office=required
if has pandoc; then report OK pandoc "Markdown CV, cover letter PDF"
else report MISSING pandoc "Markdown CV, cover letter PDF ($need_office)"
  if [[ $need_office == required ]]; then missing+=(pandoc); else optional+=(pandoc); fi; fi
if has soffice || has libreoffice; then report OK LibreOffice "Markdown/Word CV, cover letter PDF"
else report MISSING LibreOffice "Markdown/Word CV, cover letter PDF ($need_office)"
  if [[ $need_office == required ]]; then missing+=(office); else optional+=(office); fi; fi

if has pdfinfo; then report OK pdfinfo "page count"
else report OPTIONAL pdfinfo "page count (scripts/pdf_pages.py is used instead)"; fi
if has pdftoppm; then report OK pdftoppm "preview of the CV header"
else report OPTIONAL pdftoppm "preview of the CV header (skipped without it)"; fi

install_cmd() {
  local -a keys=("$@")
want() { [[ " ${keys[*]} " == *" $1 "* ]]; }
pkgs=()
case "$(uname -s)" in
  Darwin)
    want python && pkgs+=(python); want latex && pkgs+=(tectonic); want pandoc && pkgs+=(pandoc)
    cmd="brew install ${pkgs[*]} poppler"
    want office && cmd+=" && brew install --cask libreoffice"
    has brew || cmd="install Homebrew first (https://brew.sh), then: $cmd"
    ;;
  Linux)
    if has apt-get; then
      want python && pkgs+=(python3); want latex && pkgs+=(texlive-latex-extra texlive-fonts-recommended latexmk)
      want pandoc && pkgs+=(pandoc); want office && pkgs+=(libreoffice-writer)
      cmd="sudo apt-get install -y ${pkgs[*]} poppler-utils"
    elif has dnf; then
      want python && pkgs+=(python3); want latex && pkgs+=(texlive-scheme-medium latexmk)
      want pandoc && pkgs+=(pandoc); want office && pkgs+=(libreoffice-writer)
      cmd="sudo dnf install -y ${pkgs[*]} poppler-utils"
    elif has pacman; then
      want python && pkgs+=(python); want latex && pkgs+=(texlive-basic texlive-latexextra texlive-fontsrecommended)
      want pandoc && pkgs+=(pandoc-cli); want office && pkgs+=(libreoffice-fresh)
      cmd="sudo pacman -S --needed ${pkgs[*]} poppler"
    elif has zypper; then
      want python && pkgs+=(python3); want latex && pkgs+=(texlive-scheme-medium texlive-latexmk)
      want pandoc && pkgs+=(pandoc); want office && pkgs+=(libreoffice-writer)
      cmd="sudo zypper install -y ${pkgs[*]} poppler-tools"
    else
      cmd="install with your package manager: ${keys[*]} (LaTeX: TeX Live or tectonic)"
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    want python && pkgs+=(Python.Python.3.12); want latex && pkgs+=(MiKTeX.MiKTeX)
    want pandoc && pkgs+=(JohnMacFarlane.Pandoc); want office && pkgs+=(TheDocumentFoundation.LibreOffice)
    cmd=""; for p in "${pkgs[@]}"; do cmd+="${cmd:+ && }winget install -e --id $p"; done
    ;;
  *) cmd="install: ${keys[*]}" ;;
esac
  echo "$cmd"
}

[[ ${#optional[@]} -gt 0 ]] && echo "optional install (cover letter PDF): $(install_cmd "${optional[@]}")"
[[ ${#missing[@]} -eq 0 ]] && { echo "all needed tools are present"; exit 0; }
echo "install: $(install_cmd "${missing[@]}")"
exit 1
