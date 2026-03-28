---
name: research-sandbox
description: Create a sandboxed autonomous research environment with Docker, GPU access, and a multi-session Claude loop. Use when the user wants to set up an autonomous research project.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebSearch, WebFetch
---

# Research Sandbox Skill

You are setting up an autonomous research environment. This creates a Docker sandbox with GPU access where Claude sessions loop autonomously — each session does one piece of research, logs findings, and passes instructions to the next session.

## Phase 1: Gather Information

Ask the user the following (one message, keep it concise):

1. **"What is your research question?"** — This is the core question. Get a clear, specific statement.

Then, based on their answer:

2. **Suggest a project name** (short lowercase slug, e.g., `smiles-retrieval`, `protein-folding`) and ask if it's OK.
3. Ask **1-2 clarifying questions** if the research question is ambiguous (datasets to use, specific approaches to try, success criteria, etc.). Skip if the question is already clear.

Wait for the user's answers before proceeding.

## Phase 2: Environment Detection

Run these checks silently:

```bash
# Get host UID/GID for container user
HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Check Docker
docker --version

# Check GPU support
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "NO_GPU"

# Check nvidia-container-toolkit
dpkg -l | grep nvidia-container-toolkit || echo "NO_NVIDIA_TOOLKIT"
```

If Docker is missing, stop and tell the user. If GPU/nvidia-toolkit is missing, warn but continue (remove GPU sections from docker-compose.yml).

## Phase 3: Scaffold the Project

The current working directory is the project directory. Create the full structure:

### 3a. Copy static templates

Copy all files from `${CLAUDE_SKILL_DIR}/templates/` into the current directory, preserving structure. The templates contain these placeholders that MUST be replaced:

- `__PROJECT_NAME__` → the project name slug (e.g., `smiles-retrieval`)
- `__UID__` → host user's UID
- `__GID__` → host user's GID

Files to copy and substitute:
- `Dockerfile` (substitute `__UID__`, `__GID__`)
- `docker-compose.yml.template` → `docker-compose.yml` (substitute `__PROJECT_NAME__`)
- `loop.sh` (no substitution needed)
- `scripts/*` (substitute `__PROJECT_NAME__` in all scripts)
- `prompts/02-session-protocol.md` (no substitution needed)
- `prompts/03-evaluation.md` (no substitution needed)

**If NO GPU was detected**, remove the entire `deploy:` section from docker-compose.yml after copying.

### 3b. Generate research-specific files

These files are NOT templates — generate them based on the research question. Use web search and your knowledge to write high-quality content.

1. **`prompts/00-context.md`** — Research background:
   - Problem description and why it matters
   - Relevant datasets (URLs, sizes, formats)
   - Current state of the art (methods, benchmarks, numbers)
   - Key papers and resources

2. **`prompts/01-research-directions.md`** — Ordered list of approaches:
   - Priority 1 should always be "understand the data/baseline"
   - Then increasingly sophisticated approaches
   - Include GitHub repos, paper links, HuggingFace models where relevant

3. **`CLAUDE.md`** — Project-level instructions:
   - Use the template structure from `prompts/02-session-protocol.md` as reference
   - Customize the "What This Is" section for this specific research
   - Keep the directory layout table and rules generic

4. **`state/next_action.md`** — First session bootstrap:
   - Tell the first session to read all prompts, explore the data, and create an initial plan

### 3c. Initialize Python project

```bash
uv init --no-readme
# Edit pyproject.toml: set name to project name, requires-python to ">=3.12"
uv python pin 3.12
```

### 3d. Create runtime directories

```bash
mkdir -p state logs notes results checkpoints data src
```

## Phase 4: Build and Start Container

```bash
docker compose up -d --build
```

## Phase 5: Verify

Run these checks inside the container (via `docker exec`):

1. **GPU**: `nvidia-smi` (skip if no GPU)
2. **uv**: `uv --version`
3. **Python**: `uv run python --version`
4. **Network**: `uv run python -c "import urllib.request; urllib.request.urlopen('https://huggingface.co'); print('OK')"`
5. **Permissions**: `touch /workspace/state/_test && rm /workspace/state/_test`
6. **Claude**: `claude --version`

Report results to the user.

## Phase 6: User Authentication

Tell the user:
```
Container is ready. Please authenticate Claude inside it:

  docker exec -it __PROJECT_NAME__-sandbox claude /login

Let me know when done.
```

Wait for confirmation, then run a quick test:
```bash
docker exec __PROJECT_NAME__-sandbox claude --dangerously-skip-permissions -p "Say hello" --output-format json
```

If it works, tell the user:

```
All set! To start the autonomous research loop:

  docker exec __PROJECT_NAME__-sandbox tmux new -d -s research /workspace/loop.sh

To watch it:
  docker exec -it __PROJECT_NAME__-sandbox tmux attach -t research

To stop it:
  touch state/STOP

To check status:
  ./scripts/status.sh
```
