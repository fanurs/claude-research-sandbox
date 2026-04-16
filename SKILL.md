---
name: research-sandbox
description: Create a sandboxed autonomous research environment with Docker, GPU access, and a multi-session Claude loop. Use when the user wants to set up an autonomous research project.
user-invocable: true
---

# Research Sandbox Skill

You are scaffolding a Docker sandbox for autonomous research. Your job is to get the container running FAST. Do NOT do deep research — the autonomous loop will handle that later.

## Phase 1: Ask the User

In ONE message, ask these things:

1. **Research question** — "What is your research question?" Suggest a project name (short slug like `smiles-retrieval`) and confirm.

2. **Email notifications** (optional) — "Want email reports when sessions finish? (uses Resend)" If yes, ask:
   - Recipient email address
   - Sender name and email (must be from a domain verified with Resend, e.g. `Your Name <noreply@yourdomain.com>`)
   - Where is the Resend API key stored? (e.g. `~/.secrets`, env var, etc.)

   If the user declines, skip all email setup (Phase 3a email template, Phase 5b).

3. **Git identity** — "What name and email for git commits inside the container?" Suggest the user's system git config if detectable via `git config user.name` / `git config user.email`.

4. **Model preference** (optional) — "Which Claude model for sessions? (default: your default, or e.g. claude-opus-4-6)" and "Effort level? (default: unset, or low/medium/high/max)"

5. **npm availability** — "Do you have npm on the host? (needed for the optional log viewer web UI)"

Only ask additional clarifying questions if truly ambiguous. Keep it brief.

Wait for answers before proceeding.

## Phase 2: Environment Detection

Run silently:
```bash
HOST_UID=$(id -u) && echo "UID=$HOST_UID"
HOST_GID=$(id -g) && echo "GID=$HOST_GID"
docker --version
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "NO_GPU"
dpkg -l | grep nvidia-container-toolkit 2>/dev/null || echo "NO_NVIDIA_TOOLKIT"
```

If Docker is missing, stop. If no GPU, warn and continue (remove `deploy:` section from compose later).

## Phase 3: Scaffold

### 3a. Copy templates with substitution

Read each file from `${CLAUDE_SKILL_DIR}/templates/` and write it to the current directory, replacing:
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

2. **`CLAUDE.md`** — Hard rules only, ~20 lines:
   ```
   # Hard Rules

   - You are running inside Docker at /workspace
   - Follow protocol.md every session (orient → scope → work → report → commit → handoff)
   - ONE objective per session
   - Use `uv add` / `uv sync` / `uv remove` for Python deps — NEVER `uv pip install`
   - Always use GPU. If `torch.cuda.is_available()` is False, STOP.
   - Estimate VRAM before training
   - All exploration code goes in `playground/session-NN-slug/` — only proven code moves to `src/`
   - After completing work, commit with `git add -A && git commit -m "Session NN: <desc>"`
   - NEVER include Co-Authored-By lines or mention AI coauthorship in commits
   - Do NOT modify protocol.md or scripts/
   - You may update README.md as understanding deepens (research directions, findings, etc.)
   ```

3. **`state/next_action.md`** — Bootstrap the first session:
   ```
   # Next Action
   This is the very first session. Do the following:
   1. Read README.md and protocol.md to understand the project and session protocol
   2. Explore and download relevant data
   3. Write up initial findings in notes/
   4. Create a research plan in state/plan.md
   5. Update the journal and write the next action

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
mkdir -p state logs notes results checkpoints data src playground reports/figures tests
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

CRITICAL: Never read, print, or echo `.env.email` contents. Trust the user set it up correctly.

1. Create `.env.email` in the project directory with the Resend API key:
   ```bash
   source <secrets_file> && echo "RESEND_API_KEY=${RESEND_API_KEY}" > .env.email
   ```
   Do NOT read or echo key values.

2. Test email from inside the container:
   ```bash
   docker exec -w /workspace __PROJECT_NAME__-sandbox bash -c 'set -a && source /workspace/.env.email && set +a && uv run python /workspace/src/send_report_email.py --test 2>&1'
   ```

3. Ask the user: "Did you receive the test email?" If it fails, debug — but do NOT read `.env.email` during debugging. Check error messages from the script output only.

### 5c. Log Viewer Setup (if npm available)

If the user has npm on the host:
```bash
cd tools/viewer && npm install
```

Tell the user:
```
Log viewer installed. To watch sessions in your browser:
  cd tools/viewer && npm start
Then open http://localhost:3000

The viewer runs on the HOST (not inside the container).
It reads log files from the bind-mounted logs/ directory.
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
To stop:            touch state/STOP
To stop after N:    echo "STOP-50" > state/STOP
Status:             ./scripts/status.sh
Reports:            ls reports/
```
