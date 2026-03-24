# GitHub Professional Presence & Pipeline Integration

> **Date:** 2026-03-15
> **Author:** Abhishek V + Claude
> **Status:** Revised — incorporating full narrative, backdated commits, archive strategy, no-media constraint

---

## 1. Overview

### 1.1 Problem Statement

Current state:
- Everything lives in a single monorepo (`D:\Claude local\`) tracked by `mohitauchit-ctrl/Main-GIThub` (stale identity). The GitHub account was previously under username `mohitauchit-ctrl` and will be renamed to / replaced by `Abhishekv87bit`.
- Git config uses wrong name/email (`mohitauchit-ctrl` / `mohitauchit@gmail.com`)
- No public-facing repos except `alpha-pulse` (already public) and archived `Main-GIThub`
- No GitHub profile README, no portfolio presence
- No CI/CD enforcing quality gates
- Pipeline enforcement is local-only (hookify rules), not backed by GitHub infrastructure

### 1.2 Three Goals

Build a GitHub presence that serves three purposes simultaneously:

1. **Professional showcase** — Recruiters see a polished, active, well-organized profile within 30 seconds
2. **Pipeline backbone** — GitHub Actions, branch protection, and PR workflows physically enforce Pineapple Pipeline stages
3. **Ecosystem hub** — GitHub + LinkedIn + portfolio website tell one cohesive story

### 1.3 Constraints

- Single developer (now), public showcase (future)
- No secrets/API keys may be exposed (confirmed: none in git history)
- `alpha-pulse` is already public — remains so
- `Main-GIThub` is archived (private) — stays as-is
- Fresh repos with **backdated initial commits** matching real project creation dates (preserves contribution graph timeline)
- Existing GitHub content **archived** (made private), never deleted — backup preserved
- **No local photos/videos/screenshots** uploaded to GitHub — use generated assets (shields.io badges, Mermaid diagrams, placeholder references for screenshots)
- Must support Pineapple Pipeline enforcement via GitHub features
- **GitHub Free limits:** 2,000 Actions minutes/month, 1 GB LFS storage + 1 GB bandwidth. Monitor usage; consider GitHub Pro ($4/month) if limits are hit, or use `paths:` filters in CI to skip doc-only changes.
- **Rollback:** Old repos archived (not deleted) + monorepo remains on local machine. To rollback: make old repos public again and delete the new ones. Zero data loss risk.

---

## 2. Brand Identity & Narrative

### 2.1 The 30-Second Story

> "Enterprise veteran with 13 years of domain expertise, now building the AI future — and proving it by creating things that move in the real world."

The narrative is NOT "pick one." The narrative IS the rare combination:

**Four identity pillars:**
1. **AI/ML Engineer** — builds real things with Claude, Gemini, CadQuery, MCP
2. **Full-stack engineer** — domain expertise across insurance, 3D/CAD, web (React + FastAPI + Three.js)
3. **Systems thinker / technical leader** — built the Pineapple Pipeline, makes architectural decisions, understands production-grade engineering
4. **Creative technologist** — kinetic sculpture is a passion, making physical things is a passion

**The career arc:** 13 years as a Business Analyst in the insurance industry with leading IT firms — bringing ideas from inception to implementation. Currently pursuing Guidewire and AWS Cloud certifications. Transitioning to full-stack AI/ML architecture by building real, ambitious projects that prove capability.

**The differentiator:** Most AI developers build chatbots. You build an entire production pipeline, a kinetic sculpture design studio, and parametric mechanical designs — and you bring enterprise-grade process discipline to all of it.

### 2.2 Identity

| Field | Value |
|-------|-------|
| Display name | Abhishek V |
| Username | `Abhishekv87bit` |
| Email (commits) | `abhishekv87@yahoo.com` |
| Bio (160 chars) | "13yr enterprise BA turning AI architect. Building kinetic sculpture design tools with Claude, Gemini, CadQuery, Three.js, MCP" |
| Website | `https://abhishekv87bit.github.io` (portfolio, Phase 2) |
| LinkedIn | (existing profile) |

### 2.3 Consistency Rule

Same avatar, adapted bio, and visual identity across GitHub, LinkedIn, and portfolio website. One brand, three surfaces.

---

## 3. Repository Architecture

### 3.1 Repo Map (6 repos, Phase 1)

| # | Repo Name | Visibility | What | Source |
|---|-----------|------------|------|--------|
| 1 | `kinetic-forge-studio` | Public | Full-stack AI-powered kinetic sculpture designer | `kinetic-forge-studio/` |
| 2 | `pineapple-pipeline` | Public | Universal dev pipeline + template library | `production-pipeline/` |
| 3 | `kinetic-sculpture-designs` | Public | Parametric designs, VLAD validator, knowledge banks | `3d_design_agent/` (curated) |
| 4 | `openscad-mcp` | Public | MCP server for OpenSCAD rendering | `openscad-mcp/` |
| 5 | `alpha-pulse` | Public | (already exists — enhance documentation) | Already on GitHub |
| 6 | `Abhishekv87bit` | Public | GitHub profile README | New |

**Phase 2 addition:**

| 7 | `Abhishekv87bit.github.io` | Public | Portfolio website / blog (GitHub Pages) | New |

### 3.2 What Stays Behind

Not everything in the monorepo becomes a repo:
- `Jeff/`, `dance-to-music/` — Archive or drop
- `tools/aidl/`, `tools/aws-workstation/` — Utility scripts, not portfolio material
- `prototypes/` — Fold relevant pieces into `kinetic-sculpture-designs`
- `sessions/`, `migrations/`, `archives/` — Development artifacts, not public
- Loose files (`.npy`, standalone scripts) — Clean up

### 3.3 Cross-Repo Dependencies

| Consumer | Depends On | Strategy |
|----------|-----------|----------|
| `kinetic-forge-studio` | VLAD validator | Vendor pattern (copy into KFS). Pip-installable later when VLAD stabilizes. |
| `kinetic-forge-studio` | `openscad-mcp` | Runtime connection (MCP protocol), no code dependency |
| `pineapple-pipeline` | Nothing | Pipeline is agnostic — zero code dependency on any project |

---

## 4. Per-Repository Documentation Standard

Every repo follows the same documentation structure. Consistency signals professionalism.

### 4.1 README Template

```markdown
<!-- Hero banner: generated asset (Mermaid diagram, SVG, shields.io banner) — NOT a local photo/screenshot -->
<!-- Use: Mermaid architecture diagram, CSS gradient SVG, or placeholder until generated asset is ready -->
![Banner](docs/images/banner.svg)

# Project Name

> One-line hook that makes someone want to read more.

<!-- Badge strip -->
[![CI](badge-url)](actions-url)
[![License: MIT](badge-url)](license-url)
[![Python 3.12](badge-url)](python-url)
[![Built with CadQuery](badge-url)](cadquery-url)
<!-- etc. -->

## What This Does

2-3 paragraphs. Problem statement, solution, why it matters.
Written for someone who has never seen this project.
Lead with the outcome, not the technology.

## Demo / Screenshots

Generated visuals only (Mermaid diagrams, SVG renders, terminal output).
NO local photos/videos/screenshots. Use placeholders: `<!-- Add generated screenshot here -->`

## Architecture

Mermaid diagram showing high-level component relationships.

## Built With

| Technology | Role |
|-----------|------|
| ![Python](shield-badge) | Core language |
| ![CadQuery](shield-badge) | Parametric 3D modeling engine |
| ![Claude API](shield-badge) | Design reasoning and physics auditing |
| ... | ... |

## Getting Started

### Prerequisites
### Installation
### Quick Start (< 5 commands to working state)

## Project Structure

Brief file tree with 1-line descriptions per directory.

## Development

How to run tests, lint, format, contribute. Link to CONTRIBUTING.md.

## License

MIT

## Acknowledgments
```

### 4.2 Standard Files (every repo)

| File | Purpose |
|------|---------|
| `README.md` | Project overview + getting started |
| `LICENSE` | MIT |
| `CONTRIBUTING.md` | Commit conventions, PR workflow, code standards |
| `CHANGELOG.md` | Auto-generated from conventional commits |
| `.github/workflows/ci.yml` | CI pipeline |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR checklist tied to pipeline stages |
| `.github/ISSUE_TEMPLATE/bug.yml` | Structured bug report |
| `.github/ISSUE_TEMPLATE/feature.yml` | Structured feature request |
| `.github/dependabot.yml` | Automated dependency updates |
| `.pre-commit-config.yaml` | Local quality hooks |
| `.commitlintrc.yml` | Conventional commit format rules (required by CI commitlint action) |
| `.gitignore` | Project-specific exclusions |
| `docs/images/` | Screenshots, diagrams, banner |

### 4.3 Badges

Standard strip at the top of every README:

```markdown
[![CI](https://github.com/Abhishekv87bit/REPO/actions/workflows/ci.yml/badge.svg)](...)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](...)
[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](...)
```

Plus per-repo tech badges:

```markdown
[![Built with CadQuery](https://img.shields.io/badge/Built%20with-CadQuery-orange)](...)
[![Powered by Claude](https://img.shields.io/badge/Powered%20by-Claude-blueviolet)](...)
[![MCP Compatible](https://img.shields.io/badge/MCP-Compatible-green)](...)
```

### 4.4 Topics (Tags) per Repo

Topics appear on the repo page and in GitHub search.

| Repo | Topics |
|------|--------|
| `kinetic-forge-studio` | `kinetic-sculpture`, `cadquery`, `three-js`, `fastapi`, `react`, `claude-api`, `gemini-api`, `3d-modeling`, `ai-powered`, `mcp` |
| `pineapple-pipeline` | `developer-tools`, `pipeline`, `ci-cd`, `template-engine`, `code-quality`, `python`, `pydantic` |
| `kinetic-sculpture-designs` | `kinetic-sculpture`, `openscad`, `cadquery`, `parametric-design`, `3d-printing`, `step-files`, `mechanical-design` |
| `openscad-mcp` | `mcp-server`, `openscad`, `model-context-protocol`, `3d-rendering`, `ai-tools`, `claude` |
| `alpha-pulse` | Topics will be defined in Phase 6 after reviewing current state (5-minute review task) |

---

## 5. GitHub Profile

### 5.1 Profile README (`Abhishekv87bit/Abhishekv87bit`)

This is the first thing recruiters see. One scroll to tell the full story.

**Structure:**

1. **Custom header banner** — Generated SVG or clean gradient with name + tagline reflecting the enterprise-to-AI arc. NOT a local photo/screenshot — use generated assets (CSS gradient, SVG, or shields.io-style banner). Something that reflects both the enterprise background and the kinetic sculpture domain.

2. **Introduction** — 3-4 lines: the career arc (13yr BA -> AI architect), what you build, the four identity pillars, what makes the combination rare.

3. **Projects table** — 4-5 rows, each with project name (linked), one-line description, and tech stack icons.

4. **Tech stack grid** — All technologies organized by category (Languages, AI/ML, 3D/CAD, Backend, Frontend, DevOps, Protocols). Using `shields.io` badges with icons for visual density.

5. **GitHub stats cards** — Three cards side by side:
   - Contribution stats (`github-readme-stats`)
   - Streak counter (`github-readme-streak-stats`)
   - Top languages (`github-readme-stats/top-langs`)

6. **Dynamic elements** (optional personality touches):
   - Typing animation SVG (`readme-typing-svg`) showing rotating taglines
   - Contribution snake animation (`snk`) — the snake that eats your contribution graph
   - "Currently working on" section (manually updated)

7. **Connect section** — LinkedIn badge, email badge, portfolio badge.

### 5.2 Pinned Repositories (6 slots)

Order matters. Recruiters scan top-left to bottom-right.

1. **kinetic-forge-studio** — Flagship. Full-stack + AI + 3D.
2. **pineapple-pipeline** — Systems thinking. Engineering maturity.
3. **kinetic-sculpture-designs** — Domain expertise. Creative vision.
4. **openscad-mcp** — Protocol-level thinking. Open-source.
5. **alpha-pulse** — (Depends on project — diversity of work)
6. *(Reserved for `Abhishekv87bit.github.io` — portfolio site, Phase 2. Pin 5 repos in Phase 1.)*

### 5.3 Activity Signals

Recruiters look at the contribution graph and activity timeline. Ways to maintain visible, consistent activity:

- **Conventional commits** with good messages create readable activity
- **Issues** (even self-filed) show organized development
- **PRs** (even self-merged) show disciplined process
- **Releases** with changelogs show shipping cadence
- **Dependabot PRs** (merging them) show maintenance discipline
- **Discussions** or wiki updates show documentation effort

The contribution graph fills naturally from consistent daily work. No artificial inflation — real commits on real projects.

### 5.4 GitHub Settings

| Setting | Value |
|---------|-------|
| Avatar | Professional photo or distinctive illustration |
| Name | Abhishek V |
| Bio | "13yr enterprise BA turning AI architect. Building kinetic sculpture design tools with Claude, Gemini, CadQuery, Three.js" |
| Location | (your city) |
| Website | `https://abhishekv87bit.github.io` |
| Social: LinkedIn | (your profile URL) |
| README | `Abhishekv87bit/Abhishekv87bit` repo |

---

## 6. Pipeline Integration (GitHub as Pineapple Backbone)

This makes GitHub functional, not just decorative. Every pipeline stage maps to GitHub infrastructure that physically enforces it.

### 6.1 Stage-to-GitHub Mapping

| Pipeline Stage | GitHub Feature | Enforcement Level |
|----------------|----------------|-------------------|
| INTAKE | Issue templates (structured forms) | Issues auto-labeled by type |
| BRAINSTORM | Issue comments / linked Discussion | Soft (no gate) |
| PLAN | PR description must reference spec | PR template checklist |
| SETUP | Branch creation from issue | Naming convention: `feat/`, `fix/`, `chore/` |
| BUILD | Conventional commits | `commitlint` in CI rejects bad format |
| VERIFY | GitHub Actions CI runs tests | **Required status check** — merge blocked if red |
| REVIEW | Branch protection requires PR | At least 1 approval (self-review for solo dev) |
| SHIP | Squash merge to `main` | Only merge method enabled. Auto-tag release. |
| EVOLVE | Post-merge Action | Creates reminder to write session handoff |

> **Note:** Stage names and gates here reflect GitHub-level enforcement only. The Pineapple Pipeline enforces additional local gates (hookify rules, spec file existence) that are complementary to, not replaced by, GitHub features.

### 6.2 GitHub Actions CI Template

Shared base, customized per repo:

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install ruff
      - run: ruff check .
      - run: ruff format --check .

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: pytest -v --tb=short

  commitlint:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: wagoid/commitlint-github-action@v6
        with:
          configFile: .commitlintrc.yml
```

Per-repo additions:
- **KFS:** Frontend build (`npm run build`), Docker build test
- **Pipeline:** Template placeholder validation, pipeline self-tests
- **Designs:** VLAD validation, OpenSCAD compile checks
- **OpenSCAD MCP:** MCP protocol compliance tests

### 6.3 Branch Protection Rules

Applied to `main` on every repo:

| Rule | Setting |
|------|---------|
| Require PR before merging | Yes |
| Required approvals | 0 (GitHub Free does not allow PR author to self-approve; increase to 1 when collaborators join) |
| Require status checks to pass | Yes (CI job must be green) |
| Require conversation resolution | Yes |
| Allow squash merging only | Yes (disable merge commits and rebase) |
| Auto-delete head branches | Yes |
| Allow force push | No |

### 6.4 Conventional Commits

Format: `<type>(<scope>): <description>`

Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `ci`, `style`, `perf`

Enforced by:
- **Local:** `commitlint` via pre-commit hook (catches before push)
- **Remote:** `commitlint` GitHub Action (backup, catches if local hook skipped)

Benefits:
- Auto-generated `CHANGELOG.md` from commit messages
- Semantic versioning (`feat` = minor, `fix` = patch, `BREAKING CHANGE` = major)
- Clean, readable git history

### 6.5 PR Template

```markdown
## Summary
<!-- What does this PR do and why? Link to issue. -->

## Spec Reference
<!-- Link to design spec in docs/specs/ (required for features) -->

## Verification Evidence
<!-- Paste test results, pineapple_verify output, or CI link -->
- [ ] All tests pass locally
- [ ] Linting passes (`ruff check . && ruff format --check .`)
- [ ] No secrets in committed files

## Change Type
- [ ] feat: New feature
- [ ] fix: Bug fix
- [ ] chore: Maintenance
- [ ] docs: Documentation
- [ ] test: Tests
- [ ] refactor: Code restructuring
```

### 6.6 Issue Templates

**Bug Report** (`bug.yml`):
- What happened? (textarea)
- Expected behavior (textarea)
- Steps to reproduce (textarea)
- Severity dropdown: Critical / High / Medium / Low
- Auto-label: `bug`

**Feature Request** (`feature.yml`):
- What problem does this solve? (textarea)
- Proposed solution (textarea)
- Scope dropdown: Lightweight / Medium / Full (maps to pipeline path routing)
- Auto-label: `enhancement`

### 6.7 Release Management

Tool: **`release-please`** GitHub Action (Google, widely adopted)

On merge to `main`:
1. Scans commits since last release
2. Bumps version based on conventional commit types
3. Creates Release PR with auto-generated changelog
4. On merge of Release PR: creates GitHub Release + git tag (`v1.2.3`)

This gives every repo a visible release history with changelogs — strong signal of shipping discipline.

> **Note:** Since only squash merge is enabled, configure GitHub's merge settings to "Default to PR body" so `release-please` changelogs are preserved in `main`'s git history (not just the PR title).

### 6.8 Secret Scanning & Dependency Management

**Secrets:**
- GitHub native secret scanning + push protection (free for public repos)
- Local `gitleaks` pre-commit hook (catches before commit)
- `.gitignore` excludes `.env`, `*.pem`, `credentials.json`

**Dependencies:**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: pip
    directory: "/"
    schedule:
      interval: weekly
    labels: [dependencies]
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: weekly
```

---

## 7. Per-Repo Specifics

### 7.1 kinetic-forge-studio

| Field | Value |
|-------|-------|
| GitHub description | "AI-powered kinetic sculpture designer — design, simulate, and export with Claude + Gemini + CadQuery + Three.js" |
| README hero | Mermaid architecture diagram (no local screenshots — generate assets or use placeholders) |
| Architecture | Mermaid: Frontend (React/R3F) -> API (FastAPI) -> Engines (CadQuery, Photo Analyzer) -> AI (Claude, Gemini) -> Export (STEP/STL) |
| Built With | Python, TypeScript, FastAPI, React, Three.js, CadQuery, Claude API, Gemini API, ChromaDB, Docker |
| CI extras | `npm run build`, Docker image build, Playwright E2E (if stable) |
| Size concern | 6.0GB -> needs cleanup: `node_modules/`, `chroma/`, generated files, `__pycache__/` |
| Git LFS | STEP files in parts library |

### 7.2 pineapple-pipeline

| Field | Value |
|-------|-------|
| GitHub description | "Universal AI-powered development pipeline — 9-stage process with template library, enforcement gates, and signed verification" |
| README hero | Mermaid diagram of the INTAKE -> EVOLVE pipeline |
| Architecture | Tools (state machine, config, verify, doctor, audit) + Templates (11 production templates) + Gates (hookify rules) |
| Built With | Python, Pydantic, pytest, GitHub Actions |
| CI extras | Template placeholder validation, pipeline self-tests |
| Size | 575KB — clean, ready to go |

### 7.3 kinetic-sculpture-designs

| Field | Value |
|-------|-------|
| GitHub description | "Parametric kinetic sculpture designs — Triple Helix, Waffle Planetary, wave sculptures — with VLAD universal validator" |
| README hero | Mermaid diagram of design pipeline (no local screenshots — generate or placeholder) |
| Architecture | Design files (OpenSCAD + CadQuery) -> VLAD validator -> Export (STEP/STL) |
| Built With | Python, OpenSCAD, CadQuery, BOSL2 |
| CI extras | VLAD validation on all CadQuery designs, OpenSCAD compile check |
| Size concern | 2.3GB -> heavy curation: keep source files + reference geometry, drop screenshots + test artifacts + iteration debris |
| Git LFS | STEP files, reference geometry |

### 7.4 openscad-mcp

| Field | Value |
|-------|-------|
| GitHub description | "MCP server for OpenSCAD — render, validate, and iterate on 3D models through the Model Context Protocol" |
| README hero | Diagram: AI Assistant <-> MCP Protocol <-> OpenSCAD Engine |
| Built With | Python, MCP SDK, OpenSCAD |
| Note | MCP is cutting-edge. README should explain what MCP is for readers who don't know. Strong differentiator. |

### 7.5 alpha-pulse

| Field | Value |
|-------|-------|
| Status | Already public. Review current state, add professional README + badges + CI to match standard. |

---

## 8. Ecosystem Integration

### 8.1 GitHub -> LinkedIn

- LinkedIn "Featured" section: Link to top 2-3 GitHub repos with screenshots
- LinkedIn "Projects": Mirror GitHub descriptions
- LinkedIn bio: Adapted version of GitHub bio
- LinkedIn posts: Share releases and milestones with visuals

### 8.2 GitHub -> Portfolio Website (Phase 2)

**Repo:** `Abhishekv87bit.github.io`
**URL:** `https://abhishekv87bit.github.io`
**Platform:** GitHub Pages (free, built-in)
**Generator:** Hugo or plain HTML/CSS/JS (TBD in Phase 2 design)

Portfolio content:
- Hero section: Name, tagline, sculpture render
- Projects: Card grid linking to GitHub repos
- About: Extended bio, story, what drives you
- Blog: Technical write-ups (future)
- Contact: Email, LinkedIn, GitHub

Phase 2 because: The profile README serves as the immediate portfolio. The website is a polish layer after repos are set up and active.

### 8.3 Link Graph

| From | Links To |
|------|----------|
| GitHub profile | Portfolio website, LinkedIn |
| LinkedIn | GitHub profile |
| Portfolio website | GitHub repos, LinkedIn |
| Each repo README | Portfolio website (footer) |

---

## 9. Migration Strategy

### 9.1 Order of Operations

```
Phase 0: Archive + Foundation (archive existing repos, fix git config, global gitignore, tooling)
Phase 1: pineapple-pipeline (smallest, proves workflow)
Phase 2: openscad-mcp (small, has own .git already)
Phase 3: Abhishekv87bit profile README (quick win, immediate visibility)
Phase 4: kinetic-sculpture-designs (needs curation, takes time)
Phase 5: kinetic-forge-studio (largest, most complex CI, benefits from lessons learned)
Phase 6: alpha-pulse enhancement (already exists, just add standards)
Phase 7: Profile polish (pinned repos, bio, settings)
Phase 8: Portfolio website (separate design cycle)
```

### 9.1.1 Archive Existing GitHub Content

Before creating new repos, archive all existing repos on `mohitauchit-ctrl` / `Abhishekv87bit`:

```bash
# Make existing repos private (archive, don't delete)
gh repo edit mohitauchit-ctrl/Main-GIThub --visibility private --archived
# Repeat for any other existing repos

# Transfer ownership if needed (mohitauchit-ctrl -> Abhishekv87bit)
# Or simply leave archived under old account
```

Nothing is deleted. The old repos stay as private archives — recoverable if needed.

### 9.2 Phase 0: Foundation

```bash
# Fix git identity
git config --global user.name "Abhishek V"
git config --global user.email "abhishekv87@yahoo.com"

# Global gitignore
git config --global core.excludesfile ~/.gitignore_global
# Contents: .env, *.pem, .DS_Store, Thumbs.db, *.pyc, __pycache__/,
#           .idea/, .vscode/, *.swp, node_modules/

# Install local tooling
pip install pre-commit ruff
```

### 9.3 Per-Repo Migration Workflow

For each repo:

```
 1. Create GitHub repo (gh repo create --public)
 2. Init local repo in clean directory
 3. Size audit: remove node_modules/, __pycache__/, .next/, chroma/, build artifacts BEFORE any git add
    Verify remaining size < 500 MB (excluding LFS files). Use `du -sh` to confirm.
 4. Copy project files from monorepo (selective, not bulk)
 5. Add .gitignore (project-specific + global)
 6. If repo has STEP/STL files: run `git lfs install` && `git lfs track '*.step' '*.stl'`
    LFS tracking MUST be set up BEFORE any large binary is committed.
 7. Add scaffold: .github/, README, LICENSE, CONTRIBUTING, .commitlintrc.yml
 8. Write project-specific README (generated assets only — no local photos/screenshots)
 9. Pre-commit hooks: ruff, commitlint, gitleaks
10. Initial commit with BACKDATED timestamps:
    GIT_AUTHOR_DATE="YYYY-MM-DDT00:00:00" GIT_COMMITTER_DATE="YYYY-MM-DDT00:00:00" \
      git commit -m "feat: initial project scaffold"
    (Date = real project creation date from monorepo git log)
11. Push to GitHub
12. Configure branch protection (gh api)
    NOTE: Steps 10-11 (commit + push) happen BEFORE step 12 (branch protection).
    The CI workflow is pushed as part of the initial commit but protection is not active yet.
    This is intentional — the first PR after setup is the real enforcement test.
13. Enable secret scanning + push protection
14. Set repo topics (gh repo edit --add-topic)
15. Verify CI passes (green badge)
16. Create first release (v0.1.0)
```

**Backdating reference dates** (approximate, to be confirmed from git log):
| Repo | Backdate To | Source |
|------|-------------|--------|
| `kinetic-forge-studio` | TBD | First KFS commit in monorepo |
| `pineapple-pipeline` | TBD | First production-pipeline commit |
| `kinetic-sculpture-designs` | TBD | First 3d_design_agent commit |
| `openscad-mcp` | TBD | First openscad-mcp commit |
| `alpha-pulse` | Already exists | Already has real history |

### 9.4 Post-Migration Cleanup

1. Verify all repos have green CI badges
2. Verify backdated commits show correct dates on GitHub contribution graph
3. Pin 6 repos on profile
4. Set GitHub profile settings (bio, website, etc.)
5. Update LinkedIn with GitHub links
6. Local workspace: point to new separate repo directories
7. Confirm old repos archived (private) on GitHub — nothing deleted

---

## 10. Verification

After full migration, confirm:

- [ ] `git config user.name` = "Abhishek V" globally
- [ ] `git config user.email` = "abhishekv87@yahoo.com" globally
- [ ] All 6 repos created and pushed
- [ ] Each repo has: README, LICENSE, CONTRIBUTING, CI, PR template, issue templates, dependabot
- [ ] CI green on every repo (badge visible in README)
- [ ] Branch protection enabled on `main` for every repo
- [ ] Secret scanning + push protection enabled
- [ ] Topics set on every repo
- [ ] Profile README live
- [ ] 6 repos pinned
- [ ] GitHub bio, website, LinkedIn URL set
- [ ] Conventional commit enforcement works (test with bad message -> CI rejects)
- [ ] First Dependabot PR appears within a week

---

## 11. What This Spec Does NOT Cover

- Portfolio website design and content (Phase 2 — separate spec)
- Blog setup and content strategy (Phase 2)
- Multi-contributor workflows (CODEOWNERS, team reviews) — single developer for now
- Deployment CI/CD (GitHub Actions -> production server) — pipeline governs dev process, not deployment
- GitHub Sponsors or monetization
- Custom domain setup (`abhishekv.dev` or similar) — Phase 2
- Content of individual project READMEs (written during migration, not pre-designed here)
