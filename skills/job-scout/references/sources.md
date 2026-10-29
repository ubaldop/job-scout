# Where to search, and how to read what you find

## 1. Company job boards (the main source)

Most tech companies publish their jobs through an applicant tracking system (ATS) that has a public, unauthenticated JSON API. These APIs give the full, current posting, often with the salary band. `scripts/scan_ats.py` reads them in parallel and caches the results.

| ATS | Board URL | API used by the scanner |
|---|---|---|
| Greenhouse | `boards.greenhouse.io/<slug>`, `job-boards.greenhouse.io/<slug>` | `boards-api.greenhouse.io/v1/boards/<slug>/jobs?content=true` |
| Ashby | `jobs.ashbyhq.com/<slug>` | `api.ashbyhq.com/posting-api/job-board/<slug>?includeCompensation=true` |
| Lever | `jobs.lever.co/<slug>`, `jobs.eu.lever.co/<slug>` | `api.lever.co/v0/postings/<slug>?mode=json` (and `api.eu.lever.co`) |
| SmartRecruiters | `jobs.smartrecruiters.com/<slug>` | `api.smartrecruiters.com/v1/companies/<slug>/postings` (no description: open the posting) |
| Workable | `apply.workable.com/<slug>` | `POST apply.workable.com/api/v3/accounts/<slug>/jobs` (no description) |
| Personio | `<slug>.jobs.personio.de` | `<slug>.jobs.personio.de/xml` |

To find the slug of a company: open its careers page and follow an "Apply" link, or search `site:jobs.ashbyhq.com <company>`.

The scanner reads the boards from `companies.txt` in the Job Scout home (`~/.claude/job-scout/` by default). `scripts/find_boards.py` builds it from company names: it tries the likely slugs on every ATS and keeps the boards with open jobs. Build the list after the profile, and add every good company that a later search finds. A list of 100–300 boards of the right companies gives a good scan in under a minute.

A posting that the user's country is not in can still be in another posting of the same company: some companies publish one posting per country (Trading 212 does). Check the board, not only the matched row.

## 2. Web search

Use WebSearch to find companies that are not in the lists, then add their boards:

- ATS search operators: `site:jobs.ashbyhq.com`, `site:job-boards.greenhouse.io`, `site:jobs.lever.co`, `site:apply.workable.com` + the stack + "remote" + the region.
- Remote job boards: Himalayas, Remotive, RemoteOK, We Work Remotely, Working Nomads, EU Remote Jobs, Wellfound, Arbeitnow (Germany), Welcome to the Jungle (France), SwissDevJobs (`swissdevjobs.ch/api/jobsLight` is a public JSON feed).
- Hacker News "Who is hiring?" threads, searchable at hnhiring.com.
- Stack-specific boards and communities (for example scalajobs.com for Scala, or the hiring threads of a language subreddit).
- Glassdoor and Indeed through web search only: their pages block automated reading, and their snippets are often old.

Aggregator snippets are often wrong about location and salary. Use them only to discover a posting, then open the posting on the company ATS.

LinkedIn is not a source of this skill: automated reading of LinkedIn is against its terms of service. If the user finds a posting on LinkedIn, ask for the link to the company page or ATS.

## 3. Salary evidence when the posting has none

In order of reliability:
1. A salary band on another posting of the same company, same level, same region.
2. A public salary calculator or salary bands page of the company (GitLab, Buffer, PostHog and others publish one).
3. Levels.fyi for the company, the same level and the same country. Note whether the number is base or total compensation.
4. Glassdoor and Indeed: weak evidence, often for other levels or countries.

Many companies pay by the country of the employee. A band published for the US or for London does not apply to a candidate in another country. Some job forms ask for the salary expectation: then the user can state the minimum and let the company filter.

## 4. How to read "remote"

These usually do NOT mean "remote from anywhere in Europe":
- "Remote (Germany)", "remote within the UK", "Remote — Spain or Portugal": only those countries.
- "Hybrid", "X days in the office", "remote-friendly" with one office city.
- A location list of cities without the word remote.
- "Remote in EMEA" plus "must have the right to work in <country>".

These usually DO:
- "Remote — Europe / EU / EMEA", "anywhere in <time zone> ± N hours", "we hire through an Employer of Record (Deel, Remote.com, Oyster…)", "fully distributed, we hire in N countries" (check the list).

When the posting is not clear, keep the offer only if the application form or the careers FAQ confirms it, and write the doubt in `job.md`.

Employment type: "contractor", "B2B", "freelance" and "self-employed" are not employment. Keep these offers only if the profile accepts them.
