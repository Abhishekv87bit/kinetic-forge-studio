# GitHub Professional Presence & Pipeline Integration — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform a monorepo into 6 professional GitHub repos with CI, branch protection, conventional commits, backdated history, and a recruiter-grade profile.

**Architecture:** Phase-ordered migration — foundation first, smallest repo first (proves workflow), largest repo last (benefits from lessons). Shared scaffold templates created once, stamped per repo. Each repo gets: CI, branch protection, PR/issue templates, conventional commits, dependabot, secret scanning.

**Tech Stack:** GitHub CLI (`gh`), Git LFS, GitHub Actions, `ruff`, `commitlint`, `gitleaks`, `release-please`, `pre-commit`, shields.io badges, Mermaid diagrams.

**Spec:** `docs/superpowers/specs/2026-03-15-github-reorganization-design.md`

---

## Chunk 1: Foundation + Shared Scaffold Templates

### Task 1: Archive Existing GitHub Repos

**Context:** 3 repos exist under `Abhishekv87bit`: Main-GIThub, foxfin, Work. Archive all before creating new repos.

- [ ] **Step 1: Verify current GitHub auth and repos**

```bash
gh auth status
# NOTE: Auth may show 'mohitauchit-ctrl' — this is the old username.
# If the account was renamed to Abhishekv87bit, the token still works.
# If gh commands fail with 404s, re-authenticate:
#   gh auth login
gh repo list Abhishekv87bit --limit 50
```
Expected: See 3 repos (Main-GIThub, foxfin, Work). If auth fails, run `gh auth login` first.

- [ ] **Step 2: Archive each existing repo**

```bash
gh repo archive Abhishekv87bit/Main-GIThub --yes
gh repo archive Abhishekv87bit/Work --yes
# foxfin = alpha-pulse, do NOT archive — will be enhanced in Phase 6
```
Expected: 2 repos archived. foxfin left active.

- [ ] **Step 3: Verify archives**

```bash
gh repo list Abhishekv87bit --limit 50
```
Expected: Main-GIThub and Work show as archived.

---

### Task 2: Fix Git Identity

- [ ] **Step 1: Set global git config**

```bash
git config --global user.name "Abhishek V"
git config --global user.email "abhishekv87@yahoo.com"
```

- [ ] **Step 2: Verify**

```bash
git config --global user.name
git config --global user.email
```
Expected: "Abhishek V" and "abhishekv87@yahoo.com"

---

### Task 3: Create Global Gitignore

- [ ] **Step 1: Create global gitignore file**

Create `~/.gitignore_global`:
```
# OS
.DS_Store
Thumbs.db
desktop.ini

# Editors
.idea/
.vscode/
*.swp
*.swo

# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/
.pytest_cache/
*.egg-info/
dist/
build/

# Node
node_modules/

# Secrets
.env
.env.local
*.pem
credentials.json

# Build artifacts
*.log
nul
```

- [ ] **Step 2: Register it**

```bash
git config --global core.excludesfile ~/.gitignore_global
```

- [ ] **Step 3: Verify**

```bash
git config --global core.excludesfile
```
Expected: Path to `~/.gitignore_global`

---

### Task 4: Create Shared Scaffold Templates

**Context:** These template files get copied into every new repo. Create them in a temporary staging directory.

- [ ] **Step 1: Create staging directory**

```bash
mkdir -p "/d/Claude local/github-scaffold"
```

- [ ] **Step 2: Create LICENSE (MIT)**

Create `github-scaffold/LICENSE`:
```
MIT License

Copyright (c) 2025-2026 Abhishek V

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Create CONTRIBUTING.md**

Create `github-scaffold/CONTRIBUTING.md`:
```markdown
# Contributing

## Commit Conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>
```

**Types:** `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `ci`, `style`, `perf`

**Examples:**
- `feat(engine): add parametric gear generator`
- `fix(api): handle missing auth token gracefully`
- `docs: update installation instructions`

## Pull Request Workflow

1. Create a branch: `feat/description`, `fix/description`, or `chore/description`
2. Make changes with conventional commits
3. Open a PR against `main`
4. CI must pass (lint + tests)
5. Squash merge when ready

## Development Setup

```bash
# Clone
git clone https://github.com/Abhishekv87bit/REPO_NAME.git
cd REPO_NAME

# Install dependencies
pip install -r requirements.txt -r requirements-dev.txt

# Run tests
pytest -v

# Lint
ruff check .
ruff format --check .
```

## Code Standards

- Python: formatted with `ruff format`, linted with `ruff check`
- TypeScript (if applicable): formatted with Prettier, linted with ESLint
- All PRs require passing CI before merge
```

- [ ] **Step 4: Create .commitlintrc.yml**

Create `github-scaffold/.commitlintrc.yml`:
```yaml
extends:
  - '@commitlint/config-conventional'
rules:
  type-enum:
    - 2
    - always
    - - feat
      - fix
      - chore
      - docs
      - test
      - refactor
      - ci
      - style
      - perf
  subject-case:
    - 2
    - never
    - - sentence-case
      - start-case
      - pascal-case
      - upper-case
```

- [ ] **Step 5: Create PR template**

Create `github-scaffold/.github/PULL_REQUEST_TEMPLATE.md`:
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

- [ ] **Step 6: Create issue templates**

Create `github-scaffold/.github/ISSUE_TEMPLATE/bug.yml`:
```yaml
name: Bug Report
description: Report a bug
labels: ["bug"]
body:
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: A clear description of the bug.
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
      description: What did you expect to happen?
    validations:
      required: true
  - type: textarea
    id: reproduce
    attributes:
      label: Steps to reproduce
      description: How can we reproduce the issue?
    validations:
      required: true
  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - Critical
        - High
        - Medium
        - Low
    validations:
      required: true
```

Create `github-scaffold/.github/ISSUE_TEMPLATE/feature.yml`:
```yaml
name: Feature Request
description: Suggest a new feature
labels: ["enhancement"]
body:
  - type: textarea
    id: problem
    attributes:
      label: What problem does this solve?
      description: Describe the problem or need.
    validations:
      required: true
  - type: textarea
    id: solution
    attributes:
      label: Proposed solution
      description: How should this work?
    validations:
      required: true
  - type: dropdown
    id: scope
    attributes:
      label: Scope
      description: How big is this change?
      options:
        - Lightweight (bug fix, config change)
        - Medium (clear feature, < 8 files)
        - Full (new subsystem, architectural change)
    validations:
      required: true
```

- [ ] **Step 7: Create dependabot config**

Create `github-scaffold/.github/dependabot.yml`:
```yaml
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

- [ ] **Step 8: Create .pre-commit-config.yaml**

Create `github-scaffold/.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.6
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/alessandrojcm/commitlint-pre-commit-hook
    rev: v9.18.0
    hooks:
      - id: commitlint
        stages: [commit-msg]
        additional_dependencies: ['@commitlint/config-conventional']
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks
```

NOTE: After copying this to each repo, run `pre-commit install && pre-commit install --hook-type commit-msg` to activate.

- [ ] **Step 9: Create base CI workflow (Python-only variant)**

Create `github-scaffold/.github/workflows/ci.yml`:
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
      - run: pip install -r requirements.txt
      - run: pip install pytest
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

- [ ] **Step 10: Create release-please workflow**

Create `github-scaffold/.github/workflows/release.yml`:
```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          release-type: python
```

- [ ] **Step 11: Verify scaffold directory structure**

```bash
find "/d/Claude local/github-scaffold" -type f | sort
```
Expected:
```
.commitlintrc.yml
.github/ISSUE_TEMPLATE/bug.yml
.github/ISSUE_TEMPLATE/feature.yml
.github/PULL_REQUEST_TEMPLATE.md
.github/dependabot.yml
.github/workflows/ci.yml
.github/workflows/release.yml
.pre-commit-config.yaml
CONTRIBUTING.md
LICENSE
```

---

## Chunk 2: pineapple-pipeline + openscad-mcp Repos

### Task 5: Create pineapple-pipeline Repo

**Backdate:** 2026-03-14 (first production-pipeline commit in monorepo)
**Size:** 575K — smallest repo, proves the workflow.

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create Abhishekv87bit/pineapple-pipeline --public --description "Universal AI-powered development pipeline — 9-stage process with template library, enforcement gates, and signed verification"
```

- [ ] **Step 2: Init local repo in clean directory**

```bash
mkdir -p "/d/GitHub/pineapple-pipeline"
cd "/d/GitHub/pineapple-pipeline"
git init
```

- [ ] **Step 3: Copy project files from monorepo (selective)**

```bash
# Copy core directories
cp -r "/d/Claude local/production-pipeline/templates" "/d/GitHub/pineapple-pipeline/"
cp -r "/d/Claude local/production-pipeline/tools" "/d/GitHub/pineapple-pipeline/"
cp -r "/d/Claude local/production-pipeline/tests" "/d/GitHub/pineapple-pipeline/"
# Copy docs/ and examples/ if they exist and are non-empty
[ -d "/d/Claude local/production-pipeline/docs" ] && cp -r "/d/Claude local/production-pipeline/docs" "/d/GitHub/pineapple-pipeline/"
[ -d "/d/Claude local/production-pipeline/examples" ] && cp -r "/d/Claude local/production-pipeline/examples" "/d/GitHub/pineapple-pipeline/"

# Copy config files
cp "/d/Claude local/production-pipeline/pyproject.toml" "/d/GitHub/pineapple-pipeline/"
cp "/d/Claude local/production-pipeline/requirements.txt" "/d/GitHub/pineapple-pipeline/"
cp "/d/Claude local/production-pipeline/README.md" "/d/GitHub/pineapple-pipeline/"
cp "/d/Claude local/production-pipeline/RUNBOOK.md" "/d/GitHub/pineapple-pipeline/"
cp "/d/Claude local/production-pipeline/THREAT_MODEL.md" "/d/GitHub/pineapple-pipeline/"

# Do NOT copy: .pytest_cache, __pycache__, any .env files
```

- [ ] **Step 4: Add .gitignore**

Create `/d/GitHub/pineapple-pipeline/.gitignore`:
```
__pycache__/
*.pyc
.pytest_cache/
.venv/
*.egg-info/
dist/
build/
.env
```

- [ ] **Step 5: Copy scaffold templates**

```bash
cp "/d/Claude local/github-scaffold/LICENSE" "/d/GitHub/pineapple-pipeline/"
cp "/d/Claude local/github-scaffold/CONTRIBUTING.md" "/d/GitHub/pineapple-pipeline/"
cp "/d/Claude local/github-scaffold/.commitlintrc.yml" "/d/GitHub/pineapple-pipeline/"
cp "/d/Claude local/github-scaffold/.pre-commit-config.yaml" "/d/GitHub/pineapple-pipeline/"
cp -r "/d/Claude local/github-scaffold/.github" "/d/GitHub/pineapple-pipeline/"

# Create initial CHANGELOG.md (release-please expects this)
echo -e "# Changelog\n\nAll notable changes to this project will be documented in this file.\n" > "/d/GitHub/pineapple-pipeline/CHANGELOG.md"
```

- [ ] **Step 6: Write project-specific README**

Replace `/d/GitHub/pineapple-pipeline/README.md` with professional README containing:
- Mermaid diagram of INTAKE → EVOLVE pipeline as hero
- Badge strip (CI, License, Python 3.12)
- "What This Does" — 2-3 paragraphs explaining the 9-stage pipeline
- Architecture section with Mermaid diagram (tools + templates + gates)
- Built With table (Python, Pydantic, pytest, GitHub Actions)
- Getting Started (prerequisites, installation, quick start)
- Project Structure (brief file tree)
- Development section

Use these badges:
```markdown
[![CI](https://github.com/Abhishekv87bit/pineapple-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/Abhishekv87bit/pineapple-pipeline/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/)
[![Built with Pydantic](https://img.shields.io/badge/Built%20with-Pydantic-orange)](https://docs.pydantic.dev/)
```

- [ ] **Step 7: Size audit**

```bash
du -sh "/d/GitHub/pineapple-pipeline"
```
Expected: < 1MB. If larger, investigate.

- [ ] **Step 8: Stage all files**

```bash
cd "/d/GitHub/pineapple-pipeline"
git add -A
```

- [ ] **Step 9: Backdated initial commit**

```bash
cd "/d/GitHub/pineapple-pipeline"
GIT_AUTHOR_DATE="2026-03-14T11:38:42" GIT_COMMITTER_DATE="2026-03-14T11:38:42" \
  git commit -m "feat: initial project scaffold — 9-stage pipeline with template library and enforcement gates"
```

- [ ] **Step 10: Push to GitHub**

```bash
cd "/d/GitHub/pineapple-pipeline"
git remote add origin https://github.com/Abhishekv87bit/pineapple-pipeline.git
git branch -M main
git push -u origin main
```

- [ ] **Step 11: Configure branch protection via rulesets + merge settings**

GitHub Free does not support legacy branch protection with 0 required reviewers.
Use **repository rulesets** (available on Free) instead:

```bash
# Create ruleset requiring PRs and status checks
gh api repos/Abhishekv87bit/pineapple-pipeline/rulesets \
  --method POST \
  --input - <<'EOF'
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    { "type": "pull_request", "parameters": { "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false, "require_last_push_approval": false } },
    { "type": "required_status_checks", "parameters": { "strict_required_status_checks_policy": true, "required_status_checks": [{"context": "lint"}, {"context": "test"}, {"context": "commitlint"}] } },
    { "type": "non_fast_forward" }
  ]
}
EOF

# Configure merge settings (squash only, PR body preserved for release-please)
gh api repos/Abhishekv87bit/pineapple-pipeline --method PATCH \
  --field allow_squash_merge=true \
  --field allow_merge_commit=false \
  --field allow_rebase_merge=false \
  --field squash_merge_commit_title="PR_TITLE" \
  --field squash_merge_commit_message="PR_BODY" \
  --field delete_branch_on_merge=true
```

This enforces: PRs required (0 approvals), CI must pass, no force push, squash merge only.

- [ ] **Step 12: Enable secret scanning + set topics**

```bash
# Secret scanning is auto-enabled for public repos
# Set topics
gh repo edit Abhishekv87bit/pineapple-pipeline --add-topic developer-tools --add-topic pipeline --add-topic ci-cd --add-topic template-engine --add-topic code-quality --add-topic python --add-topic pydantic
```

- [ ] **Step 13: Verify CI badge**

```bash
gh run list --repo Abhishekv87bit/pineapple-pipeline --limit 1
```
Expected: CI run triggered by push to main. Check status (may take 1-2 minutes).

- [ ] **Step 14: Create first release**

```bash
cd "/d/GitHub/pineapple-pipeline"
git tag v0.1.0
git push origin v0.1.0
gh release create v0.1.0 --title "v0.1.0 — Initial Release" --notes "Initial release of Pineapple Pipeline.

## What's Included
- 9-stage pipeline framework (INTAKE → EVOLVE)
- 11 production templates (Docker, CI, middleware, cache)
- Pipeline state machine with signed verification
- Audit, doctor, and cleanup tools
- Runbook and threat model documentation"
```

- [ ] **Step 15: Commit — verify workflow works end-to-end**

Open `https://github.com/Abhishekv87bit/pineapple-pipeline` in browser. Confirm:
- README renders with Mermaid diagram
- CI badge shows (green or pending)
- Topics visible
- Release visible
- Commit date shows 2026-03-14

---

### Task 6: Create openscad-mcp Repo

**Backdate:** 2025-08-28 (earliest commit in existing standalone .git)
**Size:** 88M — already a mature standalone repo with README, LICENSE, CI.
**Strategy:** This repo already has `.git` history. We'll create a fresh repo and copy files (not history), then backdate.

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create Abhishekv87bit/openscad-mcp --public --description "MCP server for OpenSCAD — render, validate, and iterate on 3D models through the Model Context Protocol"
```

- [ ] **Step 2: Init local repo in clean directory**

```bash
mkdir -p "/d/GitHub/openscad-mcp"
cd "/d/GitHub/openscad-mcp"
git init
```

- [ ] **Step 3: Copy project files (exclude .git, .venv, __pycache__)**

NOTE: `rsync` is not available in Git Bash on Windows. Use comprehensive `cp` instead.

```bash
cd "/d/Claude local/openscad-mcp"

# Directories
for dir in src tests examples workflows; do
  [ -d "$dir" ] && cp -r "$dir" "/d/GitHub/openscad-mcp/"
done

# Top-level files (all non-hidden + selected hidden)
cp pyproject.toml uv.lock README.md LICENSE CONTRIBUTING.md CHANGELOG.md "/d/GitHub/openscad-mcp/" 2>/dev/null
cp .env.example .dockerignore Dockerfile MANIFEST.in pytest.ini "/d/GitHub/openscad-mcp/" 2>/dev/null
cp API.md DEPLOYMENT.md DEPLOYMENT_SUMMARY.md "/d/GitHub/openscad-mcp/" 2>/dev/null
cp RELEASE_NOTES*.md "/d/GitHub/openscad-mcp/" 2>/dev/null
cp test_cube.scad "/d/GitHub/openscad-mcp/" 2>/dev/null
cp .gitignore "/d/GitHub/openscad-mcp/" 2>/dev/null

# Verify nothing was missed — compare source vs dest (ignoring .git, .venv, __pycache__)
echo "=== Source files ==="
ls "/d/Claude local/openscad-mcp/"
echo "=== Dest files ==="
ls "/d/GitHub/openscad-mcp/"
# Manually copy any files that appear in source but not dest
```

- [ ] **Step 4: Verify .gitignore exists and covers build artifacts**

Check if openscad-mcp already has a `.gitignore`. If not, create one:
```
__pycache__/
*.pyc
.venv/
.env
dist/
build/
*.egg-info/
```

- [ ] **Step 5: Copy scaffold templates (only what's missing)**

openscad-mcp already has README, LICENSE, CONTRIBUTING. Only add what's missing.

**IMPORTANT:** openscad-mcp has a `workflows/` directory at the project root (not `.github/workflows/`).
Move these existing CI/release workflows to `.github/workflows/` — they are likely customized for MCP.

```bash
# Move existing workflows/ to .github/workflows/ (GitHub only reads from .github/)
mkdir -p "/d/GitHub/openscad-mcp/.github/workflows"
if [ -d "/d/GitHub/openscad-mcp/workflows" ]; then
  cp "/d/GitHub/openscad-mcp/workflows/"*.yml "/d/GitHub/openscad-mcp/.github/workflows/" 2>/dev/null
  rm -r "/d/GitHub/openscad-mcp/workflows"
fi

# Add scaffold files that don't already exist
cp -n "/d/Claude local/github-scaffold/.commitlintrc.yml" "/d/GitHub/openscad-mcp/"
cp -n "/d/Claude local/github-scaffold/.pre-commit-config.yaml" "/d/GitHub/openscad-mcp/"
mkdir -p "/d/GitHub/openscad-mcp/.github/ISSUE_TEMPLATE"
cp -n "/d/Claude local/github-scaffold/.github/PULL_REQUEST_TEMPLATE.md" "/d/GitHub/openscad-mcp/.github/" 2>/dev/null
cp -n "/d/Claude local/github-scaffold/.github/ISSUE_TEMPLATE/bug.yml" "/d/GitHub/openscad-mcp/.github/ISSUE_TEMPLATE/" 2>/dev/null
cp -n "/d/Claude local/github-scaffold/.github/ISSUE_TEMPLATE/feature.yml" "/d/GitHub/openscad-mcp/.github/ISSUE_TEMPLATE/" 2>/dev/null
cp -n "/d/Claude local/github-scaffold/.github/dependabot.yml" "/d/GitHub/openscad-mcp/.github/" 2>/dev/null
# Only add release.yml if not already moved from workflows/
cp -n "/d/Claude local/github-scaffold/.github/workflows/release.yml" "/d/GitHub/openscad-mcp/.github/workflows/" 2>/dev/null
```

- [ ] **Step 6: Update README with badges**

Add to top of existing README (if not already present):
```markdown
[![CI](https://github.com/Abhishekv87bit/openscad-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/Abhishekv87bit/openscad-mcp/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/)
[![MCP Compatible](https://img.shields.io/badge/MCP-Compatible-green)](https://modelcontextprotocol.io)
```

- [ ] **Step 7: Size audit**

```bash
du -sh "/d/GitHub/openscad-mcp"
```
Expected: ~88M (excluding .venv).

- [ ] **Step 8: Stage, backdate commit, push**

```bash
cd "/d/GitHub/openscad-mcp"
git add -A
GIT_AUTHOR_DATE="2025-08-28T02:59:17" GIT_COMMITTER_DATE="2025-08-28T02:59:17" \
  git commit -m "feat: initial project scaffold — MCP server for OpenSCAD rendering and validation"
git remote add origin https://github.com/Abhishekv87bit/openscad-mcp.git
git branch -M main
git push -u origin main
```

- [ ] **Step 9: Configure branch protection (rulesets) + merge settings + topics**

```bash
# Create ruleset
gh api repos/Abhishekv87bit/openscad-mcp/rulesets \
  --method POST \
  --input - <<'EOF'
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    { "type": "pull_request", "parameters": { "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false, "require_last_push_approval": false } },
    { "type": "required_status_checks", "parameters": { "strict_required_status_checks_policy": true, "required_status_checks": [{"context": "lint"}, {"context": "test"}, {"context": "commitlint"}] } },
    { "type": "non_fast_forward" }
  ]
}
EOF

# Merge settings
gh api repos/Abhishekv87bit/openscad-mcp --method PATCH \
  --field allow_squash_merge=true \
  --field allow_merge_commit=false \
  --field allow_rebase_merge=false \
  --field squash_merge_commit_title="PR_TITLE" \
  --field squash_merge_commit_message="PR_BODY" \
  --field delete_branch_on_merge=true

# Topics
gh repo edit Abhishekv87bit/openscad-mcp --add-topic mcp-server --add-topic openscad --add-topic model-context-protocol --add-topic 3d-rendering --add-topic ai-tools --add-topic claude
```

- [ ] **Step 10: Verify + create release**

```bash
gh run list --repo Abhishekv87bit/openscad-mcp --limit 1
cd "/d/GitHub/openscad-mcp"
git tag v0.1.0
git push origin v0.1.0
gh release create v0.1.0 --title "v0.1.0 — Initial Release" --notes "MCP server for OpenSCAD — render, validate, and iterate on 3D models through the Model Context Protocol."
```

---

## Chunk 3: Profile README + kinetic-sculpture-designs

### Task 7: Create Profile README Repo

- [ ] **Step 1: Create the profile README repo**

```bash
gh repo create Abhishekv87bit/Abhishekv87bit --public --description "GitHub Profile"
```

- [ ] **Step 2: Init and create README.md**

```bash
mkdir -p "/d/GitHub/Abhishekv87bit"
cd "/d/GitHub/Abhishekv87bit"
git init
```

- [ ] **Step 3: Write the profile README**

Create `/d/GitHub/Abhishekv87bit/README.md` with:

```markdown
<!-- Header Banner — generated SVG gradient -->
<div align="center">

# Abhishek V

### Enterprise Veteran | AI Architect | Creative Technologist

> *13 years of enterprise domain expertise, now building the AI future — and proving it by creating things that move in the real world.*

</div>

---

## About Me

I spent 13 years as a **Business Analyst** in the **insurance industry** with leading IT firms — taking ideas from inception to implementation. Now I'm channeling that enterprise discipline into **AI/ML architecture**, building real systems that bridge digital intelligence and physical design.

I don't just build chatbots. I build **production pipelines**, **kinetic sculpture design studios**, and **parametric mechanical systems** — with the process rigor of someone who's shipped enterprise software for over a decade.

**Currently pursuing:** Guidewire Certifications | AWS Cloud Certifications

---

## Projects

| Project | Description | Stack |
|---------|-------------|-------|
| [Kinetic Forge Studio](https://github.com/Abhishekv87bit/kinetic-forge-studio) | AI-powered kinetic sculpture designer — design, simulate, export | ![Python](https://img.shields.io/badge/-Python-3776AB?style=flat&logo=python&logoColor=white) ![React](https://img.shields.io/badge/-React-61DAFB?style=flat&logo=react&logoColor=black) ![Three.js](https://img.shields.io/badge/-Three.js-000?style=flat&logo=three.js) ![FastAPI](https://img.shields.io/badge/-FastAPI-009688?style=flat&logo=fastapi&logoColor=white) |
| [Pineapple Pipeline](https://github.com/Abhishekv87bit/pineapple-pipeline) | Universal 9-stage dev pipeline with enforcement gates | ![Python](https://img.shields.io/badge/-Python-3776AB?style=flat&logo=python&logoColor=white) ![Pydantic](https://img.shields.io/badge/-Pydantic-E92063?style=flat) ![GitHub Actions](https://img.shields.io/badge/-Actions-2088FF?style=flat&logo=github-actions&logoColor=white) |
| [Kinetic Sculpture Designs](https://github.com/Abhishekv87bit/kinetic-sculpture-designs) | Parametric designs — Triple Helix, Waffle Planetary, wave sculptures | ![OpenSCAD](https://img.shields.io/badge/-OpenSCAD-F5A623?style=flat) ![CadQuery](https://img.shields.io/badge/-CadQuery-orange?style=flat) ![BOSL2](https://img.shields.io/badge/-BOSL2-blue?style=flat) |
| [OpenSCAD MCP](https://github.com/Abhishekv87bit/openscad-mcp) | MCP server for AI-driven 3D model rendering | ![MCP](https://img.shields.io/badge/-MCP-green?style=flat) ![Python](https://img.shields.io/badge/-Python-3776AB?style=flat&logo=python&logoColor=white) |

---

## Tech Stack

**Languages**
![Python](https://img.shields.io/badge/-Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![TypeScript](https://img.shields.io/badge/-TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![JavaScript](https://img.shields.io/badge/-JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)

**AI / ML**
![Claude API](https://img.shields.io/badge/-Claude%20API-blueviolet?style=for-the-badge)
![Gemini API](https://img.shields.io/badge/-Gemini%20API-4285F4?style=for-the-badge&logo=google&logoColor=white)
![LangFuse](https://img.shields.io/badge/-LangFuse-FF6B6B?style=for-the-badge)
![ChromaDB](https://img.shields.io/badge/-ChromaDB-orange?style=for-the-badge)

**3D / CAD**
![CadQuery](https://img.shields.io/badge/-CadQuery-orange?style=for-the-badge)
![OpenSCAD](https://img.shields.io/badge/-OpenSCAD-F5A623?style=for-the-badge)
![FreeCAD](https://img.shields.io/badge/-FreeCAD-red?style=for-the-badge)
![Three.js](https://img.shields.io/badge/-Three.js-000?style=for-the-badge&logo=three.js)

**Backend**
![FastAPI](https://img.shields.io/badge/-FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Pydantic](https://img.shields.io/badge/-Pydantic-E92063?style=for-the-badge)
![Docker](https://img.shields.io/badge/-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

**Frontend**
![React](https://img.shields.io/badge/-React-61DAFB?style=for-the-badge&logo=react&logoColor=black)
![Vite](https://img.shields.io/badge/-Vite-646CFF?style=for-the-badge&logo=vite&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/-Tailwind-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)

**Protocols**
![MCP](https://img.shields.io/badge/-Model%20Context%20Protocol-green?style=for-the-badge)

**DevOps**
![GitHub Actions](https://img.shields.io/badge/-GitHub%20Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Git](https://img.shields.io/badge/-Git-F05032?style=for-the-badge&logo=git&logoColor=white)

---

## GitHub Stats

<div align="center">

![GitHub Stats](https://github-readme-stats.vercel.app/api?username=Abhishekv87bit&show_icons=true&theme=tokyonight&hide_border=true)

![GitHub Streak](https://github-readme-streak-stats.herokuapp.com/?user=Abhishekv87bit&theme=tokyonight&hide_border=true)

![Top Languages](https://github-readme-stats.vercel.app/api/top-langs/?username=Abhishekv87bit&layout=compact&theme=tokyonight&hide_border=true)

</div>

---

## Connect

[![LinkedIn](https://img.shields.io/badge/-LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/YOUR_LINKEDIN)
[![Email](https://img.shields.io/badge/-Email-EA4335?style=for-the-badge&logo=gmail&logoColor=white)](mailto:abhishekv87@yahoo.com)
[![Portfolio](https://img.shields.io/badge/-Portfolio-000?style=for-the-badge&logo=github&logoColor=white)](https://abhishekv87bit.github.io)
```

**Note:** Replace `YOUR_LINKEDIN` with actual LinkedIn profile URL.

- [ ] **Step 4: Commit and push**

```bash
cd "/d/GitHub/Abhishekv87bit"
git add -A
git commit -m "feat: create professional profile README"
git remote add origin https://github.com/Abhishekv87bit/Abhishekv87bit.git
git branch -M main
git push -u origin main
```

- [ ] **Step 5: Verify profile renders**

Open `https://github.com/Abhishekv87bit` — the README should display on the profile page.

---

### Task 8: Create kinetic-sculpture-designs Repo

**Backdate:** 2026-01-17 (first 3d_design_agent commit)
**Size:** 2.3G → ~800M-1G after cleanup. Uses Git LFS for STEP files.

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create Abhishekv87bit/kinetic-sculpture-designs --public --description "Parametric kinetic sculpture designs — Triple Helix, Waffle Planetary, wave sculptures — with VLAD universal validator"
```

- [ ] **Step 2: Init local repo + set up Git LFS**

```bash
mkdir -p "/d/GitHub/kinetic-sculpture-designs"
cd "/d/GitHub/kinetic-sculpture-designs"
git init
git lfs install
git lfs track "*.step"
git lfs track "*.stl"
git lfs track "*.STEP"
git lfs track "*.STL"
```
This creates `.gitattributes` — commit it with the initial commit.

- [ ] **Step 3: Copy project files (selective — source code + reference geometry only)**

```bash
# Core design projects
cp -r "/d/Claude local/3d_design_agent/triple_helix_mvp" "/d/GitHub/kinetic-sculpture-designs/"
cp -r "/d/Claude local/3d_design_agent/waffle_grid_planetary" "/d/GitHub/kinetic-sculpture-designs/"
cp -r "/d/Claude local/3d_design_agent/components" "/d/GitHub/kinetic-sculpture-designs/"
cp -r "/d/Claude local/3d_design_agent/mechanisms" "/d/GitHub/kinetic-sculpture-designs/"

# Reference geometry (LFS-tracked)
cp -r "/d/Claude local/3d_design_agent/gears" "/d/GitHub/kinetic-sculpture-designs/"

# Design docs and rules
cp "/d/Claude local/3d_design_agent/DESIGN_RULES.md" "/d/GitHub/kinetic-sculpture-designs/"
cp -r "/d/Claude local/3d_design_agent/specs" "/d/GitHub/kinetic-sculpture-designs/" 2>/dev/null
cp -r "/d/Claude local/3d_design_agent/docs" "/d/GitHub/kinetic-sculpture-designs/" 2>/dev/null

# Tools (VLAD validator, validate_geometry)
cp -r "/d/Claude local/3d_design_agent/tools" "/d/GitHub/kinetic-sculpture-designs/" 2>/dev/null
cp "/d/Claude local/3d_design_agent/validate_geometry.py" "/d/GitHub/kinetic-sculpture-designs/" 2>/dev/null

# Top-level SCAD files (source code)
cp "/d/Claude local/3d_design_agent/"*.scad "/d/GitHub/kinetic-sculpture-designs/" 2>/dev/null

# Do NOT copy: *.png, *.jpg, *.csg, __pycache__, .pytest_cache, archives/ (too large), Pulley/ (508M, defer)
```

**Important:** Adapt this list based on what actually exists. The goal is source code + reference geometry, not screenshots or test artifacts.

- [ ] **Step 4: Add .gitignore**

Create `/d/GitHub/kinetic-sculpture-designs/.gitignore`:
```
__pycache__/
*.pyc
.pytest_cache/
.venv/
*.csg
*.png
*.jpg
qa_screenshots/
test_scad_cache/
```

- [ ] **Step 5: Copy scaffold + write README**

```bash
cp "/d/Claude local/github-scaffold/LICENSE" "/d/GitHub/kinetic-sculpture-designs/"
cp "/d/Claude local/github-scaffold/CONTRIBUTING.md" "/d/GitHub/kinetic-sculpture-designs/"
cp "/d/Claude local/github-scaffold/.commitlintrc.yml" "/d/GitHub/kinetic-sculpture-designs/"
cp "/d/Claude local/github-scaffold/.pre-commit-config.yaml" "/d/GitHub/kinetic-sculpture-designs/"
cp -r "/d/Claude local/github-scaffold/.github" "/d/GitHub/kinetic-sculpture-designs/"

# Create initial CHANGELOG.md
echo -e "# Changelog\n\nAll notable changes to this project will be documented in this file.\n" > "/d/GitHub/kinetic-sculpture-designs/CHANGELOG.md"
```

Write project-specific README with:
- Mermaid diagram of design pipeline (Design → Validate → Export) as hero
- Badge strip (CI, License, Python 3.12, OpenSCAD, CadQuery)
- "What This Does" — parametric kinetic sculpture designs with universal validation
- Built With table
- Gallery section with `<!-- Add rendered images here -->` placeholders
- Getting Started

- [ ] **Step 6: Size audit**

```bash
du -sh "/d/GitHub/kinetic-sculpture-designs"
```
Expected: 800M-1.2G. If over 1.5G, investigate what's large and exclude more aggressively.

- [ ] **Step 7: Stage, backdate commit, push**

```bash
cd "/d/GitHub/kinetic-sculpture-designs"
git add -A
GIT_AUTHOR_DATE="2026-01-17T02:27:25" GIT_COMMITTER_DATE="2026-01-17T02:27:25" \
  git commit -m "feat: initial project scaffold — parametric kinetic sculpture designs with VLAD validator"
git remote add origin https://github.com/Abhishekv87bit/kinetic-sculpture-designs.git
git branch -M main
git push -u origin main
```

- [ ] **Step 8: Configure protection + topics + release**

```bash
# Create ruleset
gh api repos/Abhishekv87bit/kinetic-sculpture-designs/rulesets \
  --method POST \
  --input - <<'EOF'
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    { "type": "pull_request", "parameters": { "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false, "require_last_push_approval": false } },
    { "type": "required_status_checks", "parameters": { "strict_required_status_checks_policy": true, "required_status_checks": [{"context": "lint"}, {"context": "test"}, {"context": "commitlint"}] } },
    { "type": "non_fast_forward" }
  ]
}
EOF

# Merge settings
gh api repos/Abhishekv87bit/kinetic-sculpture-designs --method PATCH \
  --field allow_squash_merge=true \
  --field allow_merge_commit=false \
  --field allow_rebase_merge=false \
  --field squash_merge_commit_title="PR_TITLE" \
  --field squash_merge_commit_message="PR_BODY" \
  --field delete_branch_on_merge=true

# Topics
gh repo edit Abhishekv87bit/kinetic-sculpture-designs --add-topic kinetic-sculpture --add-topic openscad --add-topic cadquery --add-topic parametric-design --add-topic 3d-printing --add-topic step-files --add-topic mechanical-design

cd "/d/GitHub/kinetic-sculpture-designs"
git tag v0.1.0
git push origin v0.1.0
gh release create v0.1.0 --title "v0.1.0 — Initial Release" --notes "Parametric kinetic sculpture designs with VLAD universal validator. Includes Triple Helix, Waffle Planetary, and reference gear libraries."
```

---

## Chunk 4: kinetic-forge-studio + alpha-pulse + Profile Polish

### Task 9: Create kinetic-forge-studio Repo

**Backdate:** 2026-02-23 (first KFS commit)
**Size:** 6G → ~300M source after cleanup. CRITICAL: delete 3.07GB `backend/nul` junk file.
**CI:** Python + Node (React frontend).

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create Abhishekv87bit/kinetic-forge-studio --public --description "AI-powered kinetic sculpture designer — design, simulate, and export with Claude + Gemini + CadQuery + Three.js"
```

- [ ] **Step 2: Init local repo + set up Git LFS**

```bash
mkdir -p "/d/GitHub/kinetic-forge-studio"
cd "/d/GitHub/kinetic-forge-studio"
git init
git lfs install
git lfs track "*.step"
git lfs track "*.stl"
git lfs track "*.STEP"
git lfs track "*.STL"
```

- [ ] **Step 3: Copy project files (CAREFUL — exclude junk)**

```bash
# Backend (exclude .venv, __pycache__, chroma, nul, .env, report.log)
mkdir -p "/d/GitHub/kinetic-forge-studio/backend"
cp -r "/d/Claude local/kinetic-forge-studio/backend/app" "/d/GitHub/kinetic-forge-studio/backend/"
cp -r "/d/Claude local/kinetic-forge-studio/backend/tests" "/d/GitHub/kinetic-forge-studio/backend/"
cp -r "/d/Claude local/kinetic-forge-studio/backend/tools" "/d/GitHub/kinetic-forge-studio/backend/" 2>/dev/null
cp -r "/d/Claude local/kinetic-forge-studio/backend/data" "/d/GitHub/kinetic-forge-studio/backend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/backend/pyproject.toml" "/d/GitHub/kinetic-forge-studio/backend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/backend/Dockerfile" "/d/GitHub/kinetic-forge-studio/backend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/backend/requirements"*.txt "/d/GitHub/kinetic-forge-studio/backend/" 2>/dev/null

# DO NOT COPY: backend/nul (3.07GB!), backend/.venv, backend/chroma, backend/.env, backend/report.log

# Frontend (exclude node_modules, dist, .next, test-results, playwright-report)
mkdir -p "/d/GitHub/kinetic-forge-studio/frontend"
cp -r "/d/Claude local/kinetic-forge-studio/frontend/src" "/d/GitHub/kinetic-forge-studio/frontend/"
cp -r "/d/Claude local/kinetic-forge-studio/frontend/public" "/d/GitHub/kinetic-forge-studio/frontend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/frontend/package.json" "/d/GitHub/kinetic-forge-studio/frontend/"
cp "/d/Claude local/kinetic-forge-studio/frontend/package-lock.json" "/d/GitHub/kinetic-forge-studio/frontend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/frontend/tsconfig"*.json "/d/GitHub/kinetic-forge-studio/frontend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/frontend/vite.config"* "/d/GitHub/kinetic-forge-studio/frontend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/frontend/tailwind.config"* "/d/GitHub/kinetic-forge-studio/frontend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/frontend/postcss.config"* "/d/GitHub/kinetic-forge-studio/frontend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/frontend/index.html" "/d/GitHub/kinetic-forge-studio/frontend/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/frontend/Dockerfile" "/d/GitHub/kinetic-forge-studio/frontend/" 2>/dev/null

# DO NOT COPY: frontend/node_modules, frontend/dist, frontend/test-results, frontend/playwright-report

# Root files
cp "/d/Claude local/kinetic-forge-studio/docker-compose.yml" "/d/GitHub/kinetic-forge-studio/" 2>/dev/null
cp "/d/Claude local/kinetic-forge-studio/.env.example" "/d/GitHub/kinetic-forge-studio/" 2>/dev/null
cp -r "/d/Claude local/kinetic-forge-studio/.github" "/d/GitHub/kinetic-forge-studio/" 2>/dev/null
```

- [ ] **Step 4: Add .gitignore (comprehensive for Python + Node)**

Create `/d/GitHub/kinetic-forge-studio/.gitignore`:
```
# Python
__pycache__/
*.pyc
.venv/
.pytest_cache/
*.egg-info/
backend/chroma/
backend/nul
backend/.env
backend/report.log

# Node
node_modules/
dist/
.next/
.vite/

# Test artifacts
test-results/
playwright-report/

# Secrets
.env
.env.local
*.pem

# OS / Editor
.DS_Store
Thumbs.db
.idea/
.vscode/
```

- [ ] **Step 5: Copy scaffold templates (merge with existing .github if present)**

```bash
cp "/d/Claude local/github-scaffold/LICENSE" "/d/GitHub/kinetic-forge-studio/"
cp "/d/Claude local/github-scaffold/CONTRIBUTING.md" "/d/GitHub/kinetic-forge-studio/"
cp "/d/Claude local/github-scaffold/.commitlintrc.yml" "/d/GitHub/kinetic-forge-studio/"
cp "/d/Claude local/github-scaffold/.pre-commit-config.yaml" "/d/GitHub/kinetic-forge-studio/"
# Merge .github — copy only what doesn't already exist
mkdir -p "/d/GitHub/kinetic-forge-studio/.github/ISSUE_TEMPLATE"
cp -n "/d/Claude local/github-scaffold/.github/PULL_REQUEST_TEMPLATE.md" "/d/GitHub/kinetic-forge-studio/.github/" 2>/dev/null
cp -n "/d/Claude local/github-scaffold/.github/ISSUE_TEMPLATE/bug.yml" "/d/GitHub/kinetic-forge-studio/.github/ISSUE_TEMPLATE/" 2>/dev/null
cp -n "/d/Claude local/github-scaffold/.github/ISSUE_TEMPLATE/feature.yml" "/d/GitHub/kinetic-forge-studio/.github/ISSUE_TEMPLATE/" 2>/dev/null
cp -n "/d/Claude local/github-scaffold/.github/workflows/release.yml" "/d/GitHub/kinetic-forge-studio/.github/workflows/" 2>/dev/null

# KFS-specific dependabot: needs npm for frontend too
cat > "/d/GitHub/kinetic-forge-studio/.github/dependabot.yml" <<'EOF'
version: 2
updates:
  - package-ecosystem: pip
    directory: "/backend"
    schedule:
      interval: weekly
    labels: [dependencies]
  - package-ecosystem: npm
    directory: "/frontend"
    schedule:
      interval: weekly
    labels: [dependencies]
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: weekly
EOF

# Create initial CHANGELOG.md
echo -e "# Changelog\n\nAll notable changes to this project will be documented in this file.\n" > "/d/GitHub/kinetic-forge-studio/CHANGELOG.md"
```

- [ ] **Step 6: Write KFS-specific CI workflow (OVERWRITES any CI copied in Step 3)**

Create/overwrite `/d/GitHub/kinetic-forge-studio/.github/workflows/ci.yml`:
```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install ruff
      - run: ruff check backend/
      - run: ruff format --check backend/

  test-backend:
    runs-on: ubuntu-latest
    needs: lint-backend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: cd backend && pip install -r requirements.txt && pip install pytest
      - run: cd backend && pytest -v --tb=short

  build-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: cd frontend && npm ci
      - run: cd frontend && npm run build

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

- [ ] **Step 7: Write project-specific README**

Create `/d/GitHub/kinetic-forge-studio/README.md` with:
- Mermaid architecture diagram as hero (Frontend → API → Engines → AI → Export)
- Badge strip (CI, License, Python, TypeScript, React, FastAPI, CadQuery, Claude API)
- "What This Does" — AI-powered kinetic sculpture design studio
- Architecture section with Mermaid
- Built With table (full tech stack)
- Getting Started (Docker compose + manual setup)
- Project Structure

- [ ] **Step 8: Size audit — CRITICAL**

```bash
du -sh "/d/GitHub/kinetic-forge-studio"
# Verify nul file was NOT copied
ls -la "/d/GitHub/kinetic-forge-studio/backend/nul" 2>/dev/null
# Should say: No such file or directory
```
Expected: < 500MB. If the `nul` file was accidentally copied, **delete it immediately**.

- [ ] **Step 9: Stage, backdate commit, push**

```bash
cd "/d/GitHub/kinetic-forge-studio"
git add -A
GIT_AUTHOR_DATE="2026-02-23T01:56:04" GIT_COMMITTER_DATE="2026-02-23T01:56:04" \
  git commit -m "feat: initial project scaffold — AI-powered kinetic sculpture designer with Claude + Gemini + CadQuery + Three.js"
git remote add origin https://github.com/Abhishekv87bit/kinetic-forge-studio.git
git branch -M main
git push -u origin main
```

- [ ] **Step 10: Configure protection + topics + release**

```bash
# Create ruleset
gh api repos/Abhishekv87bit/kinetic-forge-studio/rulesets \
  --method POST \
  --input - <<'EOF'
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    { "type": "pull_request", "parameters": { "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false, "require_last_push_approval": false } },
    { "type": "required_status_checks", "parameters": { "strict_required_status_checks_policy": true, "required_status_checks": [{"context": "lint-backend"}, {"context": "test-backend"}, {"context": "build-frontend"}, {"context": "commitlint"}] } },
    { "type": "non_fast_forward" }
  ]
}
EOF

# Merge settings
gh api repos/Abhishekv87bit/kinetic-forge-studio --method PATCH \
  --field allow_squash_merge=true \
  --field allow_merge_commit=false \
  --field allow_rebase_merge=false \
  --field squash_merge_commit_title="PR_TITLE" \
  --field squash_merge_commit_message="PR_BODY" \
  --field delete_branch_on_merge=true

# Topics
gh repo edit Abhishekv87bit/kinetic-forge-studio --add-topic kinetic-sculpture --add-topic cadquery --add-topic three-js --add-topic fastapi --add-topic react --add-topic claude-api --add-topic gemini-api --add-topic 3d-modeling --add-topic ai-powered --add-topic mcp

cd "/d/GitHub/kinetic-forge-studio"
git tag v0.1.0
git push origin v0.1.0
gh release create v0.1.0 --title "v0.1.0 — Initial Release" --notes "AI-powered kinetic sculpture designer. Design, simulate, and export with Claude + Gemini + CadQuery + Three.js."
```

---

### Task 10: Enhance alpha-pulse (foxfin)

**Context:** `foxfin` repo already exists on GitHub as `Abhishekv87bit/foxfin`. It needs to be renamed to match the local project name, and have professional standards applied.

- [ ] **Step 1: Rename repo on GitHub (if desired)**

```bash
# Option A: Rename foxfin -> alpha-pulse
gh repo rename alpha-pulse --repo Abhishekv87bit/foxfin --yes
# Option B: Keep as foxfin if that's the preferred public name
```
Confirm with user which name to use publicly.

- [ ] **Step 2: Make repo public (currently private, spec says public)**

```bash
# IMPORTANT: foxfin is currently PRIVATE. Spec says alpha-pulse should be public.
gh repo edit Abhishekv87bit/foxfin --visibility public
```

- [ ] **Step 3: Fix local remote (currently points to old monorepo)**

```bash
cd "/d/Claude local/alpha-pulse"
# Check current remote — likely points to mohitauchit-ctrl/Main-GIThub (WRONG)
git remote -v
# Fix it to point to the correct repo
git remote set-url origin https://github.com/Abhishekv87bit/foxfin.git
# If repo was renamed in Step 1, use the new name:
# git remote set-url origin https://github.com/Abhishekv87bit/alpha-pulse.git
git remote -v
# Verify: should now show Abhishekv87bit/foxfin (or alpha-pulse)
```

- [ ] **Step 4: Review current state**

```bash
gh repo view Abhishekv87bit/foxfin
cd "/d/Claude local/alpha-pulse"
ls -la
cat README.md 2>/dev/null
ls .github/ 2>/dev/null
```

- [ ] **Step 5: Add missing scaffold files**

Copy scaffold templates that don't already exist:
```bash
cd "/d/Claude local/alpha-pulse"
cp -n "/d/Claude local/github-scaffold/LICENSE" .
cp -n "/d/Claude local/github-scaffold/CONTRIBUTING.md" .
cp -n "/d/Claude local/github-scaffold/.commitlintrc.yml" .
cp -n "/d/Claude local/github-scaffold/.pre-commit-config.yaml" .
mkdir -p .github/ISSUE_TEMPLATE .github/workflows
cp -n "/d/Claude local/github-scaffold/.github/PULL_REQUEST_TEMPLATE.md" .github/
cp -n "/d/Claude local/github-scaffold/.github/ISSUE_TEMPLATE/bug.yml" .github/ISSUE_TEMPLATE/
cp -n "/d/Claude local/github-scaffold/.github/ISSUE_TEMPLATE/feature.yml" .github/ISSUE_TEMPLATE/
cp -n "/d/Claude local/github-scaffold/.github/dependabot.yml" .github/
cp -n "/d/Claude local/github-scaffold/.github/workflows/ci.yml" .github/workflows/
cp -n "/d/Claude local/github-scaffold/.github/workflows/release.yml" .github/workflows/
```

- [ ] **Step 6: Update README with badges + professional standard**

Add badges, "Built With" table, and ensure README matches the documentation standard from the spec.

- [ ] **Step 7: Set topics**

```bash
# Topics TBD based on project review — set after reviewing alpha-pulse content
gh repo edit Abhishekv87bit/foxfin --add-topic python  # Add actual relevant topics
```

- [ ] **Step 8: Create CHANGELOG.md**

```bash
cd "/d/Claude local/alpha-pulse"
echo -e "# Changelog\n\nAll notable changes to this project will be documented in this file.\n" > CHANGELOG.md
```

- [ ] **Step 9: Commit and push**

```bash
cd "/d/Claude local/alpha-pulse"
git add -A
git commit -m "chore: add professional scaffold — CI, PR template, issue templates, badges"
git push
```

- [ ] **Step 10: Configure ruleset + merge settings**

```bash
# NOTE: Replace 'foxfin' with 'alpha-pulse' if repo was renamed in Step 1
gh api repos/Abhishekv87bit/foxfin/rulesets \
  --method POST \
  --input - <<'EOF'
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    { "type": "pull_request", "parameters": { "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false, "require_last_push_approval": false } },
    { "type": "required_status_checks", "parameters": { "strict_required_status_checks_policy": true, "required_status_checks": [{"context": "lint"}, {"context": "test"}, {"context": "commitlint"}] } },
    { "type": "non_fast_forward" }
  ]
}
EOF

gh api repos/Abhishekv87bit/foxfin --method PATCH \
  --field allow_squash_merge=true \
  --field allow_merge_commit=false \
  --field allow_rebase_merge=false \
  --field squash_merge_commit_title="PR_TITLE" \
  --field squash_merge_commit_message="PR_BODY" \
  --field delete_branch_on_merge=true
```

- [ ] **Step 11: Create first release**

```bash
cd "/d/Claude local/alpha-pulse"
git tag v0.1.0
git push origin v0.1.0
gh release create v0.1.0 --repo Abhishekv87bit/foxfin --title "v0.1.0 — Professional Scaffold" --notes "Added CI, PR templates, issue templates, dependabot, pre-commit hooks, and professional README."
```

---

### Task 11: Profile Polish + Final Verification

- [ ] **Step 1: Pin repos on GitHub profile**

Go to `https://github.com/Abhishekv87bit` → Click "Customize your pins" → Select:
1. kinetic-forge-studio
2. pineapple-pipeline
3. kinetic-sculpture-designs
4. openscad-mcp
5. foxfin (alpha-pulse)

(5 pins for Phase 1. Slot 6 reserved for portfolio website in Phase 2.)

Or via API if supported:
```bash
# Pinning requires the GraphQL API
# Manual step — do this in the browser
```

- [ ] **Step 2: Set GitHub profile settings**

Go to `https://github.com/settings/profile` and set:
- Name: Abhishek V
- Bio: "13yr enterprise BA turning AI architect. Building kinetic sculpture design tools with Claude, Gemini, CadQuery, Three.js"
- Website: https://abhishekv87bit.github.io
- Location: (your city)
- Social: LinkedIn URL

Or via CLI:
```bash
gh api user --method PATCH \
  --field name="Abhishek V" \
  --field bio="13yr enterprise BA turning AI architect. Building kinetic sculpture design tools with Claude, Gemini, CadQuery, Three.js" \
  --field blog="https://abhishekv87bit.github.io"
```

- [ ] **Step 3: Verify merge settings applied (already done per-repo during branch protection steps)**

```bash
for repo in pineapple-pipeline openscad-mcp kinetic-sculpture-designs kinetic-forge-studio; do
  echo "--- $repo ---"
  gh api repos/Abhishekv87bit/$repo --jq '{squash: .allow_squash_merge, merge: .allow_merge_commit, rebase: .allow_rebase_merge, delete_branch: .delete_branch_on_merge}'
done
```
Expected: Each repo shows `squash: true, merge: false, rebase: false, delete_branch: true`.

- [ ] **Step 4: Full verification checklist**

Run these checks and confirm each passes:

```bash
echo "=== Git Identity ==="
git config --global user.name
git config --global user.email

echo "=== Repos exist ==="
gh repo list Abhishekv87bit --limit 10

echo "=== CI status per repo ==="
for repo in pineapple-pipeline openscad-mcp kinetic-sculpture-designs kinetic-forge-studio; do
  echo "--- $repo ---"
  gh run list --repo Abhishekv87bit/$repo --limit 1
done

echo "=== Topics per repo ==="
for repo in pineapple-pipeline openscad-mcp kinetic-sculpture-designs kinetic-forge-studio; do
  echo "--- $repo ---"
  gh repo view Abhishekv87bit/$repo --json repositoryTopics -q '.repositoryTopics[].name'
done

echo "=== Rulesets per repo ==="
for repo in pineapple-pipeline openscad-mcp kinetic-sculpture-designs kinetic-forge-studio; do
  echo "--- $repo ---"
  gh api repos/Abhishekv87bit/$repo/rulesets --jq '.[].name' 2>/dev/null
done

echo "=== Releases ==="
for repo in pineapple-pipeline openscad-mcp kinetic-sculpture-designs kinetic-forge-studio; do
  echo "--- $repo ---"
  gh release list --repo Abhishekv87bit/$repo --limit 1
done
```

Expected: All repos exist, CI green (or pending), topics set, protection configured, releases created.

- [ ] **Step 5: Verify backdated commits show correct dates**

Open each repo in browser and check the initial commit date:
- pineapple-pipeline: should show 2026-03-14
- openscad-mcp: should show 2025-08-28
- kinetic-sculpture-designs: should show 2026-01-17
- kinetic-forge-studio: should show 2026-02-23

- [ ] **Step 6: Verify profile page looks professional**

Open `https://github.com/Abhishekv87bit`:
- [ ] Profile README renders (banner, projects table, tech stack, stats)
- [ ] 5 repos pinned in correct order
- [ ] Bio displays correctly
- [ ] Contribution graph shows activity on backdated dates

- [ ] **Step 7: Local workspace — update references**

Update local git remotes to point to new repos:
```bash
# For each project that was copied (not moved), you may want to set up
# the new repo as the working directory going forward
echo "New repos are in /d/GitHub/"
echo "  /d/GitHub/pineapple-pipeline"
echo "  /d/GitHub/openscad-mcp"
echo "  /d/GitHub/kinetic-sculpture-designs"
echo "  /d/GitHub/kinetic-forge-studio"
echo "  /d/GitHub/Abhishekv87bit"
echo ""
echo "Original monorepo at /d/Claude local/ remains untouched as backup."
```

---

## Summary

| Phase | Task | Repo | Backdate |
|-------|------|------|----------|
| 0 | Tasks 1-4 | Foundation + Scaffold | N/A |
| 1 | Task 5 | pineapple-pipeline | 2026-03-14 |
| 2 | Task 6 | openscad-mcp | 2025-08-28 |
| 3 | Task 7 | Abhishekv87bit (profile) | N/A |
| 4 | Task 8 | kinetic-sculpture-designs | 2026-01-17 |
| 5 | Task 9 | kinetic-forge-studio | 2026-02-23 |
| 6 | Task 10 | alpha-pulse (foxfin) | Already exists |
| 7 | Task 11 | Profile polish + verify | N/A |

**Total:** 11 tasks, ~16 steps each, estimated 2-3 hours of focused execution.
