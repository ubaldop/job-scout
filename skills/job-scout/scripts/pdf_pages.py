#!/usr/bin/env python3
"""Print the number of pages of a PDF. Fallback for systems without pdfinfo (poppler-utils).

Usage: pdf_pages.py <file.pdf>

It counts the page objects, also inside compressed object streams (PDF 1.5+).
"""
import re
import sys
import zlib


def pages(path):
    data = open(path, "rb").read()
    chunks = [data]
    for m in re.finditer(rb"stream\r?\n(.*?)\r?\nendstream", data, re.S):
        try:
            chunks.append(zlib.decompress(m.group(1)))
        except zlib.error:
            pass
    return sum(len(re.findall(rb"/Type\s*/Page(?![a-zA-Z])", c)) for c in chunks)


if __name__ == "__main__":
    print(pages(sys.argv[1]))
