#!/usr/bin/env python3
"""Flag Simple English violations in application texts (cover letters, form answers).

Usage: style_check.py <file.md> [...]

Checks the mechanical rules of the simple-english skill: sentence length (25 words),
em-dashes, semicolons, contractions, banned modals, present perfect, ", -ing" clauses,
and common slop words. Lines that start with "#", "Apply:", "⚠", "Note:", or an email address are skipped.
It cannot judge tone or truthfulness: read the text after it passes.
"""
import re
import sys

BANNED = [
    (r"—|–(?=\s)|\s--\s", "em-dash: write two sentences or name the relation"),
    (r";", "semicolon: write two sentences"),
    (r"\b\w+'(s|re|ve|ll|d|t|m)\b|\b\w+’(s|re|ve|ll|d|t|m)\b", "contraction (or possessive: rewrite if it is a contraction)"),
    (r"\b(should|may|might|could|would)\b", "banned modal: use can, will, must, or restructure"),
    (r"\b(has|have|had)\s+(been|\w+ed|built|led|run|done|made|seen|shown|written|grown|taught)\b", "present/past perfect: use simple tense"),
    (r",\s+\w+ing\b", "', -ing' clause: start a new sentence"),
    (r"\b(leverage|utilize|robust|seamless(ly)?|passionate|excited|cutting-edge|state-of-the-art|innovative|"
     r"crucial|pivotal|streamline|elevate|empower|foster|harness|synergy|delve|thrilled|eager|"
     r"in order to|ensure|simply|just)\b", "slop word: delete it or use the plain word"),
]
# Headings, notes for the user, tables, field metadata and contact lines are not application text.
SKIP = re.compile(r"^\s*(#|Apply:|⚠|Note:|\(|Upload |\||-\s*\*\*|\[TU|\[YOU|\S+@\S+)")


def sentences(text):
    text = re.sub(r"`[^`]*`", "X", text)
    for part in re.split(r"(?<=[.!?])\s+(?=[A-Z\"(])", text):
        yield part.strip()


def check(path):
    problems = 0
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        if not line.strip() or SKIP.match(line):
            continue
        for pattern, msg in BANNED:
            for m in re.finditer(pattern, line, re.I):
                print(f"{path}:{n}: {msg}: «{m.group(0)}»")
                problems += 1
        for s in sentences(line):
            words = len(re.findall(r"[\w’'-]+", s))
            if words > 25:
                print(f"{path}:{n}: sentence of {words} words (max 25): «{s[:70]}…»")
                problems += 1
    return problems


if __name__ == "__main__":
    total = sum(check(p) for p in sys.argv[1:])
    print(f"{total} problem(s)")
    sys.exit(1 if total else 0)
