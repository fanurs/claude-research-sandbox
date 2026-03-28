---
name: research-sandbox
description: Create a sandboxed autonomous research environment with Docker, GPU access, and a multi-session Claude loop. Use when the user wants to set up an autonomous research project.
user-invocable: true
---

# Research Sandbox Skill

You are scaffolding a Docker sandbox for autonomous research. Your job is to get the container running FAST. Do NOT do deep research — the autonomous loop will handle that later.

## Phase 1: Ask the User

In ONE message, ask:
1. **"What is your research question?"**
2. **Suggest a project name** (short slug like `smiles-retrieval`) and confirm.
3. Only ask clarifying questions if truly ambiguous. Keep it brief.

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
- `templates/prompts/*` → `prompts/*`

Make `loop.sh` and all `scripts/*.sh` executable.

If NO GPU, remove the `deploy:` block from docker-compose.yml.

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
mkdir -p state logs notes results checkpoints data src
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

Then tell the user how to start the loop:
```
To start: docker exec <project>-sandbox tmux new -d -s research /workspace/loop.sh
To watch: docker exec -it <project>-sandbox tmux attach -t research
To stop:  touch state/STOP
Status:   ./scripts/status.sh
```
