---
name: research-sandbox
description: Create a sandboxed autonomous research environment with Docker, GPU access, and a multi-session Claude loop. Use when the user wants to set up an autonomous research project.
user-invocable: true
---

# Research Sandbox Skill

You are scaffolding a Docker sandbox for autonomous research. Your job is to get the container running FAST. Do NOT do deep research — the autonomous loop will handle that later.

## Phase 1: Ask the User

In ONE message, ask two things:

1. **Research question** — "What is your research question?" Suggest a project name (short slug like `smiles-retrieval`) and confirm.

2. **Email notifications** (optional) — "Want email reports when sessions finish?" If yes, ask:
   - Email provider (default: Resend; also supports SendGrid, Mailgun, Postmark, or generic SMTP)
   - Recipient email address
   - Sender name and email (must be from a domain verified with their provider, e.g. `Your Name <noreply@yourdomain.com>`)
   - Where is the API key stored? (e.g. `~/.secrets`, env var, etc.)

   If the user declines, skip all email setup (Phase 3a email template, Phase 5b).

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
- `templates/scripts/*` → `scripts/*`
- `templates/src/send_report_email.py` → `src/send_report_email.py` (if email enabled)
- `templates/prompts/*` → `prompts/*`
- `templates/README.md` → `README.md`

Make `loop.sh` and all `scripts/*.sh` executable.

If NO GPU, remove the `deploy:` block from docker-compose.yml.

**If email enabled:**

In `src/send_report_email.py`, replace:
- `__REPORT_EMAIL_TO__` → recipient email address
- `__RESEND_FROM__` → sender name and email (e.g. `Automated Name <noreply@domain.com>`)

If the provider is **not** Resend, also rewrite the `send_email()` function to use the chosen provider's API:
- **SendGrid**: `https://api.sendgrid.com/v3/mail/send`, env var `SENDGRID_API_KEY`
- **Mailgun**: `https://api.mailgun.net/v3/<domain>/messages`, env var `MAILGUN_API_KEY`
- **Postmark**: `https://api.postmarkapp.com/email`, env var `POSTMARK_SERVER_TOKEN`
- **SMTP**: use Python's `smtplib` instead of urllib, env vars `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`

The template ships with Resend as the default implementation. Adapt the API URL, headers, payload format, and env var name to match the chosen provider.

Add `.env.email` to `.gitignore`.

### 3b. Generate lightweight research-specific files

Write these based on your existing knowledge — do NOT do web searches. Keep them SHORT (each under 40 lines). They will be refined by the autonomous sessions later.

1. **`prompts/00-context.md`** — Brief problem statement:
   - What the research question is and why it matters (2-3 paragraphs)
   - Any datasets/resources the user mentioned
   - Known state of the art (rough, from your knowledge)

2. **`prompts/01-research-directions.md`** — Starter list of approaches:
   - Priority 1: "Understand the data and establish baselines"
   - 2-3 more directions worth exploring
   - Note: "This list should be refined after the first few sessions"

3. **`CLAUDE.md`** — Project instructions (use this structure):
   ```
   # <Project Name> — Autonomous Research

   ## What This Is
   <One sentence about the research question>

   ## First Thing Every Session
   1. Read state/summary.md, state/journal.md, state/next_action.md, state/plan.md
   2. Follow prompts/02-session-protocol.md

   ## Prompt Files
   - prompts/00-context.md — Problem background
   - prompts/01-research-directions.md — Approaches to explore
   - prompts/02-session-protocol.md — Session protocol (MUST FOLLOW)
   - prompts/03-evaluation.md — Evaluation framework

   ## Directory Layout
   | Directory | Purpose |
   |-----------|---------|
   | src/ | Research code |
   | data/ | Datasets |
   | checkpoints/ | Model checkpoints |
   | results/ | Evaluation results (JSON) |
   | notes/ | Research notes |
   | reports/ | Session reports with figures (research diary) |
   | logs/ | Session logs (text + JSON) |
   | state/ | Cross-session memory |
   | prompts/ | Immutable instructions |
   | scripts/ | Control scripts — DO NOT MODIFY |

   ## Rules
   - ONE objective per session
   - Always read state before working, always update state after
   - Use uv add / uv sync / uv remove for Python deps. Never uv pip install.
   - Do NOT modify scripts/ or prompts/
   ```

4. **`state/next_action.md`** — Bootstrap the first session:
   ```
   # Next Action
   This is the very first session. Do the following:
   1. Read all prompt files in prompts/ to understand the project
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
mkdir -p state logs notes results checkpoints data src reports/figures
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
4. Write permission test: `touch /workspace/state/_test && rm /workspace/state/_test`

Report a brief summary table to the user.

## Phase 5b: Email Setup (if enabled)

If the user wants email notifications:

1. Create `.env.email` in the project directory with the provider's API key. The env var name depends on the provider:
   - Resend: `RESEND_API_KEY`
   - SendGrid: `SENDGRID_API_KEY`
   - Mailgun: `MAILGUN_API_KEY`
   - Postmark: `POSTMARK_SERVER_TOKEN`
   - SMTP: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`

   Do NOT read or echo key values. Use a command like:
   ```bash
   source <secrets_file> && echo "RESEND_API_KEY=${RESEND_API_KEY}" > .env.email
   ```
   (Adjust the variable name for the chosen provider.)

2. Test email from inside the container:
   ```bash
   docker exec -w /workspace <project>-sandbox bash -c 'set -a && source /workspace/.env.email && set +a && uv run python /workspace/src/send_report_email.py --test 2>&1'
   ```

3. Tell the user to check their inbox. If it fails, debug (common issue: Cloudflare blocks default urllib User-Agent — already handled in the script).

## Phase 6: User Auth

Tell the user:
```
Container is ready. Authenticate Claude:
  docker exec -it <project>-sandbox claude /login
Let me know when done.
```

After confirmation, test with:
```bash
docker exec <project>-sandbox claude --dangerously-skip-permissions -p "Say hello" --output-format json
```

Then tell the user:
```
All set! To start the autonomous research loop:
  ./scripts/start-loop.sh

To watch:    docker exec -it <project>-sandbox tmux attach -t research
To stop:     touch state/STOP
Status:      ./scripts/status.sh
Reports:     ls reports/
```
