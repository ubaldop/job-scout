#!/usr/bin/env python3
"""Find the public job board of each company and add it to the board list.

Usage:
  find_boards.py [--add] [--file FILE] <company name | slug | careers URL> ...
  ... | find_boards.py --add -          (one company per line on stdin)

For each company, the script tries likely board slugs ("Acme Labs" -> acmelabs, acme-labs, acme)
on Greenhouse, Ashby, Lever (US and EU), Workable, SmartRecruiters and Personio, and keeps
the boards that answer with at least one open job. An ATS URL (jobs.ashbyhq.com/acme/...) is
read directly.

Output: one line per board found, "<ats> <slug>  # <company>, <n> jobs", and the companies
with no board on stderr. With --add, new boards are appended to the board list
(default: $JOB_SCOUT_HOME/companies.txt, where JOB_SCOUT_HOME defaults to ~/.claude/job-scout).
"""
import argparse
import concurrent.futures as cf
import json
import os
import re
import sys
import unicodedata
import urllib.error
import urllib.request

UA = {"user-agent": "Mozilla/5.0 (job-scout board finder)", "accept": "application/json"}
HOME = os.environ.get("JOB_SCOUT_HOME", os.path.expanduser("~/.claude/job-scout"))
URL_PATTERNS = [
    ("greenhouse", r"greenhouse\.io/(?:embed/job_board\?for=)?([\w-]+)"),
    ("ashby", r"jobs\.ashbyhq\.com/([\w.-]+)"),
    ("lever", r"jobs\.(?:eu\.)?lever\.co/([\w.-]+)"),
    ("workable", r"apply\.workable\.com/([\w-]+)"),
    ("smartrecruiters", r"(?:jobs|careers)\.smartrecruiters\.com/([\w-]+)"),
    ("personio", r"([\w-]+)\.jobs\.personio\.(?:de|com)"),
]


def get(url, body=None):
    data = json.dumps(body).encode() if body is not None else None
    headers = dict(UA, **({"content-type": "application/json"} if data else {}))
    try:
        with urllib.request.urlopen(urllib.request.Request(url, data=data, headers=headers), timeout=15) as r:
            return r.read().decode("utf-8", "replace")
    except (urllib.error.URLError, TimeoutError, ConnectionError):
        return None


def count(ats, slug):
    """Number of open jobs on the board, or 0 if the board does not exist."""
    try:
        if ats == "greenhouse":
            return len(json.loads(get(f"https://boards-api.greenhouse.io/v1/boards/{slug}/jobs") or "{}").get("jobs", []))
        if ats == "ashby":
            return len(json.loads(get(f"https://api.ashbyhq.com/posting-api/job-board/{slug}") or "{}").get("jobs", []))
        if ats == "lever":
            for host in ("api.lever.co", "api.eu.lever.co"):
                d = json.loads(get(f"https://{host}/v0/postings/{slug}?mode=json") or "[]")
                if isinstance(d, list) and d:
                    return len(d)
            return 0
        if ats == "workable":
            body = {"query": "", "location": [], "department": [], "worktype": [], "remote": []}
            return len(json.loads(get(f"https://apply.workable.com/api/v3/accounts/{slug}/jobs", body) or "{}").get("results", []))
        if ats == "smartrecruiters":
            return json.loads(get(f"https://api.smartrecruiters.com/v1/companies/{slug}/postings?limit=1") or "{}").get("totalFound", 0)
        if ats == "personio":
            x = get(f"https://{slug}.jobs.personio.de/xml") or ""
            return x.count("<position>")
    except (ValueError, AttributeError):
        return 0
    return 0


def slugs(name):
    n = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode().lower()
    n = re.sub(r"\b(inc|gmbh|ltd|llc|sas|s\.?p\.?a|srl|ag|bv|ab|oy|as|se|plc|co)\b\.?", " ", n)
    words = re.findall(r"[a-z0-9]+", n)
    if not words:
        return []
    out = ["".join(words), "-".join(words)]
    if len(words) > 1 and words[-1] in ("labs", "hq", "io", "ai", "app", "tech", "technologies", "group", "software"):
        out.append("".join(words[:-1]))
    return list(dict.fromkeys(out))


def find(company):
    for ats, pattern in URL_PATTERNS:
        m = re.search(pattern, company)
        if m:
            n = count(ats, m.group(1))
            return company, [(ats, m.group(1), n)] if n else []
    candidates = [(ats, s) for s in slugs(company)
                  for ats in ("ashby", "greenhouse", "lever", "workable", "personio", "smartrecruiters")]
    with cf.ThreadPoolExecutor(max_workers=6) as pool:
        counts = list(pool.map(lambda c: count(*c), candidates))
    found = [(ats, s, n) for (ats, s), n in zip(candidates, counts) if n]
    # One board per ATS: the first slug variant that works is the most specific.
    best = {}
    for ats, s, n in found:
        best.setdefault(ats, (ats, s, n))
    return company, list(best.values())


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("companies", nargs="+", help="company names, slugs or ATS URLs; '-' reads stdin")
    ap.add_argument("--add", action="store_true", help="append the new boards to the board list")
    ap.add_argument("--file", default=os.path.join(HOME, "companies.txt"))
    a = ap.parse_args()

    names = []
    for c in a.companies:
        names += [l.strip() for l in sys.stdin if l.strip() and not l.startswith("#")] if c == "-" else [c]
    known = set()
    if os.path.exists(a.file):
        with open(a.file, encoding="utf-8") as f:
            known = {tuple(l.split("#")[0].split()[:2]) for l in f if l.split("#")[0].strip()}

    new, missing = [], []
    with cf.ThreadPoolExecutor(max_workers=8) as pool:
        for company, boards in pool.map(find, names):
            if not boards:
                missing.append(company)
            for ats, slug, n in boards:
                line = f"{ats} {slug}  # {company}, {n} jobs"
                print(line + ("  (already listed)" if (ats, slug) in known else ""))
                if (ats, slug) not in known:
                    known.add((ats, slug))
                    new.append(line)

    if a.add and new:
        os.makedirs(os.path.dirname(os.path.abspath(a.file)), exist_ok=True)
        fresh = not os.path.exists(a.file)
        with open(a.file, "a", encoding="utf-8") as f:
            if fresh:
                f.write("# Job boards scanned by job-scout: <ats> <slug>  # comment\n")
            f.write("\n".join(new) + "\n")
    print(f"{len(names)} companies, {len(new)} new boards" + (f" added to {a.file}" if a.add and new else "")
          + f", {len(missing)} without a public board", file=sys.stderr)
    if missing:
        print("  no board found: " + ", ".join(missing), file=sys.stderr)


if __name__ == "__main__":
    main()
