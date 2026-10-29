<p align="center">
  <img src="assets/logo.jpg" alt="Job Scout" width="480">
</p>

<p align="center"><b>Job hunting for Claude Code.</b><br>
Find live job offers that match your profile, then get a tailored CV, a cover letter and ready-to-paste form answers for each one.</p>

---

Job Scout is a [Claude Code](https://claude.com/claude-code) plugin. You tell it once what you look for: role, stack, where you can work from, contract types, minimum salary. Then you ask "find me a job". It:

1. **Scans hundreds of company job boards** through their public APIs (Greenhouse, Ashby, Lever, SmartRecruiters, Workable, Personio) and searches the web for more.
2. **Opens every candidate posting** and checks what aggregators often get wrong: is it still open, is "remote" really open to your country, is it employment or contracting, what is the salary.
3. **Tailors your CV** to each offer: headline, summary, bullet order, skills. It never invents anything: every claim must come from your CV or from facts you gave it.
4. **Writes a cover letter** and **an answer for every field of the application form**, which it reads from the ATS. Answers that only you can give (salary expectation, phone, notice period…) are marked `⚠ TO CONFIRM`.
5. **Collects everything** in `job-scout/applications/<date>/`, with an index of the offers and of the close misses with the reason they were dropped.

It never submits an application for you. You review, then you send.

## Install

In Claude Code:

```
/plugin marketplace add ubaldop/job-scout
/plugin install job-scout@job-scout
```

Then open Claude Code in the folder where you want to keep your job search (a private folder or repository) and say:

```
find me a job
```

At the first run, Job Scout asks for your CV and a few criteria, saves them in `~/.claude/job-scout/profile.md`, and builds by itself the list of company job boards to scan for your profile. Then it searches. Edit the profile whenever your criteria change. See [the template](skills/job-scout/references/profile-template.md) for every option.

## Requirements

You need **Python 3** and Claude Code with web access. The rest depends on your CV, and Job Scout checks it for you: at the first run, `check_deps.sh` finds what is missing and gives the install command for your system (apt, dnf, pacman, zypper, Homebrew or winget). Job Scout asks before it installs anything. If a command needs `sudo`, it asks you to run it.

| What | Needed for |
|---|---|
| **One** of: TeX Live, [tectonic](https://tectonic-typesetting.github.io), or Docker | a CV in LaTeX. With Docker, the image `texlive/texlive` is pulled at the first build (large). Change it with `JOB_SCOUT_LATEX_IMAGE`. |
| pandoc + LibreOffice | a CV in Markdown or Word, and the cover letter PDF for forms that want a file |
| poppler-utils (optional) | page count and preview of the CV. Without it, a bundled script counts the pages. |

Without these tools, Job Scout still searches and writes every text: you export the PDF yourself.

## Your CV

Your CV is the source of truth. Any of these work:

- **LaTeX** (`.tex`), any template. The skill copies it with its supporting files and edits the source.
- **Markdown** (`.md`) or **Word** (`.docx`). The PDF is built with pandoc and LibreOffice.
- **PDF only**: the skill converts it once to a Markdown CV, and asks you to review it.

## What you get

Job Scout remembers your profile and your job boards in its home folder, the same for every project:

```
~/.claude/job-scout/                 # change it with JOB_SCOUT_HOME
├── profile.md                       # your criteria
├── companies.txt                    # job boards to scan: built for you, grows at each run
└── cache/
```

The applications go to the folder where you run Claude Code:

```
job-scout/applications/2026-10-28/
├── index.md                         # ranked offers, fields to confirm, notable discards
└── 01-acme-senior-backend-engineer/
    ├── job.md                       # posting summary, why it matches, gaps, CV changes
    ├── jane_doe_resume.tex          # tailored CV
    ├── jane_doe_resume.pdf
    ├── cover_letter.md
    └── application_form.md          # one ready-to-paste answer per form field
```

## Job boards

You do not have to write a list of companies. After the profile, Job Scout makes a list of companies that hire your roles where you can work, from what it knows and from web searches. Then `find_boards.py` finds the public job board of each one on Greenhouse, Ashby, Lever, Workable, SmartRecruiters or Personio. At each run, the companies that the web search finds are added too, so the scan gets better with use.

The list is a plain file, one board per line, and you can edit it:

```
greenhouse acme  # Acme, 12 jobs
ashby example-co  # Example Co, 4 jobs
```

You can also use the scripts by themselves:

```bash
python3 skills/job-scout/scripts/find_boards.py --add "Acme" "Example Co"
python3 skills/job-scout/scripts/scan_ats.py --stack '\b(java|kotlin|kafka)\b' --where 'europe|emea|anywhere' --remote-only
```

## Privacy and fair use

- Your profile and applications stay on your computer, in `~/.claude/job-scout/` and in `job-scout/` of your project. Keep `job-scout/` out of public repositories: the skill offers to add it to `.gitignore`.
- The scanner reads only public, unauthenticated job board APIs, the same data the career pages show, and caches it to keep the number of requests low.
- LinkedIn is not supported: automated reading of LinkedIn is against its terms of service. If you find an offer there, give Claude the link to the company page.
- You are responsible for what you send. Read every CV and answer before you apply: the skill marks what it cannot know, but it can still make mistakes.

## Credits

- Plain English writing rules from [SimpleEnglish](https://github.com/AminBlg/SimpleEnglish) by AminBlg (MIT), bundled in `skills/simple-english/` with its license.

## License

MIT
