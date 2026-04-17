---
name: research-sandbox
description: Create a sandboxed autonomous research environment with Docker, GPU access, and a multi-session Claude loop. Use when the user wants to set up an autonomous research project.
user-invocable: true
---

# Research Sandbox Skill

You are scaffolding a Docker sandbox for autonomous research. Your job is to get the container running FAST. Do NOT do deep research — the autonomous loop will handle that later.

## Phase 1: Environment Probe (run BEFORE asking the user anything)

Run silently and remember the results:
```bash
id -u
id -g
docker --version
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "NO_GPU"
dpkg -l | grep nvidia-container-toolkit 2>/dev/null || echo "NO_NVIDIA_TOOLKIT"
git config --global user.name 2>/dev/null || echo ""
git config --global user.email 2>/dev/null || echo ""
command -v npm >/dev/null 2>&1 && echo "HAS_NPM" || echo "NO_NPM"
```

If Docker is missing, stop and report. If no GPU, warn the user (we remove `deploy:` from compose later). The git config and npm results are inputs to Phase 2 (Q2 branching) and Phase 5c (install decision) — do not ask the user for any of this.

## Phase 2: Intake (verbatim)

Send ONE message containing (a) a preview list of the questions, then (b) the questions themselves using the **exact wording** written below. Do not paraphrase, reorder, summarize, or soften. The only permitted variation is the conditional branch in Q3 (git identity), chosen from the Phase 1 probe. If the user answers partially, re-ask only the missing pieces, still verbatim.

Opening preview (show this first, verbatim):

> Before I start, here's what I'll ask you (5 items):
> 1. Research question + project slug
> 2. Where to scaffold (new subdirectory / here / custom path)
> 3. Git identity inside the container
> 4. Email notifications (optional)
> 5. Model and effort preference (optional)
>
> Answer in one message; anything missing I'll re-ask.

Then the questions (verbatim):

> **1. Research question.** What is your research question?
> I suggest the project slug `<propose a short kebab-case slug>` — OK, or what would you prefer?
>
> **2. Scaffold location.** Where should I put the project?
> - `subdir` (default) — create `./<slug>/` under your current directory and scaffold inside it.
> - `here` — scaffold directly into your current directory (`<absolute cwd path>`).
> - or give me an absolute or relative path — I'll create it if it doesn't exist.
>
> **3. Git identity (inside the container).**
> [If BOTH `user.name` and `user.email` were detected on the host, use exactly this line:]
> I detected `<NAME> <EMAIL>` from your host git config. Use this inside the container? (yes — or supply an alternate name + email.)
> [Otherwise, use exactly this line:]
> No git identity found on the host. What name and email should I use for commits inside the container?
>
> **4. Email notifications (optional).** Want end-of-session report emails via Resend? (yes/no)
> If yes: recipient email? Sender name + address (must be on a Resend-verified domain, e.g. `Your Name <noreply@yourdomain.com>`)?
>
> **5. Model / effort (optional).** Which Claude model for sessions? (Press Enter for default, or e.g. `claude-opus-4-6`.) Effort level? (Press Enter for unset, or one of: low / medium / high / max.)

Wait for all answers before proceeding to Phase 3.

## Phase 3: Scaffold

### 3.0. Enter target directory (based on Q2 answer)

Before writing anything, resolve the scaffold location and `cd` into it. All subsequent paths in Phase 3+ are relative to this target directory.

- **`subdir` (default)**: `mkdir <slug> && cd <slug>`. If `./<slug>/` already exists and is non-empty, STOP and ask the user: different slug? delete existing? proceed anyway? Wait for an answer before continuing.
- **`here`**: stay in the current working directory. If it's non-empty (anything other than `.git/` and hidden dotfiles), show the user the existing top-level entries and ask for explicit confirmation before proceeding. If it's already a git repo, warn that you'll be running `git init` / adding files on top.
- **Custom path** (absolute or relative): `mkdir -p <path> && cd <path>`. Apply the same non-empty check as `here`.

Report the resolved absolute path back to the user in one line (e.g. `Scaffolding into: /home/you/projects/<slug>`) so they can confirm mentally before the scaffold runs.

### 3a. Copy templates with substitution

Read each file from `${CLAUDE_SKILL_DIR}/templates/` and write it to the current directory (the target from Phase 3.0), replacing:
- `__PROJECT_NAME__` → project slug
- `__UID__` → host UID
- `__GID__` → host GID

Mapping:
- `templates/Dockerfile` → `Dockerfile`
- `templates/docker-compose.yml.template` → `docker-compose.yml`
- `templates/loop.sh` → `loop.sh`
- `templates/protocol.md` → `protocol.md`
- `templates/.gitignore` → `.gitignore`
- `templates/scripts/*` → `scripts/*`
- `templates/src/send_report_email.py` → `src/send_report_email.py` (if email enabled)
- `templates/tools/viewer/*` → `tools/viewer/*`
- `templates/README.md` → `README.md`

Make `loop.sh` and all `scripts/*.sh` executable.

If NO GPU, remove the `deploy:` block from docker-compose.yml.

**If email enabled:**

In `src/send_report_email.py`, replace:
- `__REPORT_EMAIL_TO__` → recipient email address
- `__RESEND_FROM__` → sender name and email (e.g. `Automated Name <noreply@domain.com>`)

Add `.env.email` to `.gitignore` (already in template).

### 3b. Generate research-specific files

Write these based on your existing knowledge — do NOT do web searches. Keep them concise.

1. **`README.md`** — Overwrite the template README with a project-specific version that includes:
   - Project title and one-line description
   - Research question and why it matters (2-3 paragraphs, was old `prompts/00-context.md`)
   - Research directions / approaches to explore (was old `prompts/01-research-directions.md`):
     - Priority 1: "Understand the data and establish baselines"
     - 2-3 more directions worth exploring
     - Note: "Refine this list after the first few sessions"
   - Any datasets/resources the user mentioned
   - Known state of the art (rough, from your knowledge)
   - Then keep all the framework sections from the template (Quick Start, Controls, etc.)

2. **`CLAUDE.md`** — Hard runtime rules only (session-workflow rules live in `protocol.md`):
   ```
   # Hard Rules

   - You are running inside Docker at `/workspace`
   - Follow `protocol.md` every session — it defines the workflow, code organization, commit format, and session rules
   - Always use GPU. If `torch.cuda.is_available()` is False, STOP.
   - Estimate VRAM before training
   - NEVER include Co-Authored-By lines or mention AI coauthorship in commits
   - Do NOT modify `protocol.md` or `scripts/`
   - You may update `README.md` as understanding deepens
   ```

3. **`state/next_action.md`** — Bootstrap the first session:
   ```
   # Next Action
   This is the very first session. Do the following:
   1. Read README.md and protocol.md to understand the project and session protocol
   2. Explore and download relevant data
   3. Create a research plan in state/plan.md IF one doesn't already exist; otherwise treat the existing plan as your source of truth and do not overwrite it
   4. Update the journal and write the next action

   ## Context
   <One sentence restating the research question>
   ```

### 3c. Initialize Python project

Do NOT run uv on the host. Just write these two files directly:

**`pyproject.toml`**:
```toml
[project]
name = "<project-slug>"
version = "0.1.0"
description = "<one-line research description>"
requires-python = ">=3.12"
dependencies = []
```

**`.python-version`**:
```
3.12
```

The container has uv installed. The first autonomous session will run `uv sync` inside the container.

### 3d. Create runtime directories

```bash
mkdir -p state logs results checkpoints data src playground reports/figures tests
```

### 3e. Write config (if model/effort specified)

If the user specified a model or effort level, write `.research-config`:
```bash
CLAUDE_MODEL="<model>"
CLAUDE_EFFORT="<effort>"
```

### 3f. Initialize git

```bash
git init -b main
git add -A
git commit -m "Initial scaffold from research-sandbox"
```

## Phase 4: Build and Start

```bash
docker compose up -d --build
```

## Phase 5: Verify

Run inside container via `docker exec`:
1. `nvidia-smi` (skip if no GPU)
2. `uv --version`
3. `claude --version`
4. `vim --version | head -1`
5. Write permission test: `touch /workspace/state/_test && rm /workspace/state/_test`

Report a brief summary table to the user.

### 5a. Git config inside container

```bash
docker exec __PROJECT_NAME__-sandbox git config --global user.name "<name>"
docker exec __PROJECT_NAME__-sandbox git config --global user.email "<email>"
```

### 5b. Email Setup (if enabled)

The skill **never touches the user's API key.** Generate a stub file in the project directory (NOT from `templates/` — that would put a secret-shaped file in the skill repo) and hand off to the user to fill in.

1. Create `.env.email` with a placeholder and short setup guide, then lock permissions:
   ```bash
   cat > .env.email <<'EOF'
   RESEND_API_KEY=REPLACE_THIS_WITHOUT_ANY_QUOTE

   # How to get a Resend API key (rough guide — see https://resend.com/docs for anything tricky):
   # 1. Sign up at https://resend.com and create an API key from the dashboard.
   # 2. Add + verify your sending domain (Resend → Domains → Add Domain; follow DNS steps).
   # 3. Paste the key above, replacing REPLACE_THIS_WITHOUT_ANY_QUOTE.
   #    No quotes, no trailing spaces, no repeated `RESEND_API_KEY=` prefix.
   # 4. Make sure the sender address you configured during setup uses that verified domain.
   #
   # This file is gitignored and chmod 400 — keep it that way.
   EOF
   chmod 400 .env.email
   ```

   Do NOT read or echo this file after creation.

2. Tell the user (verbatim):
   > I created `.env.email` with a placeholder. Open it, replace `REPLACE_THIS_WITHOUT_ANY_QUOTE` with your actual Resend API key, then let me know — I'll run a test send.

3. Wait for confirmation. Then test from inside the container:
   ```bash
   docker exec -w /workspace __PROJECT_NAME__-sandbox bash -c 'set -a && source /workspace/.env.email && set +a && uv run python /workspace/src/send_report_email.py --test 2>&1'
   ```

4. Ask: "Did you receive the test email?" If it fails, debug **without reading `.env.email`** — rely on stderr from the script only.

### 5c. Log Viewer Setup (auto-detect, do not ask)

Use the `HAS_NPM` / `NO_NPM` result from the Phase 1 probe. Do not ask the user.

- If `HAS_NPM`: run `cd tools/viewer && npm install`, then tell the user:
  ```
  Log viewer installed. To watch sessions in your browser:
    cd tools/viewer && npm start
  Then open http://localhost:3000

  The viewer runs on the HOST (not inside the container).
  It reads log files from the bind-mounted logs/ directory.
  ```

- If `NO_NPM`: skip the install silently. Tell the user:
  ```
  npm wasn't found on the host, so the log viewer is skipped.
  If you want it later: install Node.js/npm, then run
    cd tools/viewer && npm install && npm start
  ```

## Phase 6: User Auth

Tell the user:
```
Container is ready. Authenticate Claude:
  docker exec -it __PROJECT_NAME__-sandbox claude /login
Let me know when done.
```

After confirmation, test with:
```bash
docker exec __PROJECT_NAME__-sandbox claude --dangerously-skip-permissions -p "Say hello" --output-format json
```

Then tell the user:
```
All set! To start the autonomous research loop:
  ./scripts/start-loop.sh

To watch (web UI):  cd tools/viewer && npm start → http://localhost:3000
To watch (raw):     docker exec -it __PROJECT_NAME__-sandbox tmux attach -t research
To stop:            ./scripts/stop.sh
To stop after N:    ./scripts/stop.sh 50
Status:             ./scripts/status.sh
Reports:            ls reports/
```
